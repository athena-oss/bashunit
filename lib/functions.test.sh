BASHUNIT_MOCK_PREFIX="BASHUNIT_MOCK_"

# This function outputs the coverage for the given source and tests directory. It is
# also possible to output the list of functions that don't have tests for it.
# USAGE: bashunit.test.show_coverage <source_dir> <tests_dir> [<show_untested_functions>]
# RETURN: --
function bashunit.test.show_coverage()
{
	bashunit.utils.dir_exists_or_fail "$1"
	bashunit.utils.dir_exists_or_fail "$2"
	show=${3:-0}
	if [ "$show" -eq 1 ]; then
		bashunit.utils.print_info "List of Untested Functions:" 1>&2
	fi
	local count=0
	local nr_funcs=0
	local coverage
	for line in $(grep -R "^function " "$1" | grep -v bashunit.test. | grep -v "\._" | awk '{ print $1":"$2 }' | sed -e 's#()##g')
	do
		file=$(echo "$line" | awk -F':' '{ print $1 }')
		func=$(echo "$line" | awk -F':' '{ print $3 }')
		grep -n -R "testcase_$func" "$2"/test.*.sh 1>/dev/null
		if [ $? -ne 0 ]; then
			((count++))
			if [ "$show" -eq 1 ]; then
				bashunit.utils.print_warn "No test(s) found for function '$func' in file '$file'" 1>&2
			fi
		fi
		let nr_funcs++
	done
	if [ "$show" -eq 1 ] && [ "$count" -gt 0 ]; then
		bashunit.utils.print_warn "There are still '$count/$nr_funcs' untested functions." 1>&2
	fi
	let coverage=$((count*100/nr_funcs))
	let coverage=100-coverage
	if [ "$coverage" -eq 100 ]; then
		bashunit.utils.print_ok "Coverage: ${coverage}% (approximately). No untested functions."
	else
		bashunit.utils.print_info "Coverage: ${coverage}% (approximately)"
	fi
}

# This function creates a temporary directory in the home dir,
# by making use of mktemp command.
# USAGE: bashunit.test.create_tempdir
# RETURN: string
function bashunit.test.create_tempdir()
{
	tmpdir=$(mktemp -d -t "bashunit.XXX")
	echo "$tmpdir"
}

# This function creates a temporary file in the home dir,
# by making use of mktemp command.
# USAGE: bashunit.test.create_tempfile
# RETURN: string
function bashunit.test.create_tempfile()
{
	local tmpfile
	tmpfile=$(mktemp -t "bashunit.XXX")
	echo "$tmpfile"
}

# This function executes the suite of tests located in the given directory.
# The exit code will be zero in case all tests succeed and 1 if any fail.
# USAGE: bashunit.test.run_suite <directory|file>
# RETURN: --
function bashunit.test.run_suite()
{
	local target
	bashunit.test._save_state

	target=$(bashunit.utils.absolutepath "$1" 2>/dev/null)
	if [ $? -ne 0 ]; then
		bashunit.utils.exit_with_msg "target '$1' does not exist!"
	fi

	# single file
	if [ -f "$target" ]; then
		bashunit.test._start_suite
		bashunit.test._run_test_case "$target"
		bashunit.test._end_suite
		return $?
	fi

	# directory with testcases
	bashunit.utils.dir_exists_or_fail "$target"
	bashunit.test._start_suite

	for test_suite in $(find "$target" -name "test.*sh")
	do
		bashunit.test._run_test_case "$test_suite"
	done

	bashunit.test._end_suite
	return $?
}

# Assert <string> contains <sub-string>
# USAGE: bashunit.test.assert_string_contains <string> <sub-string>
function bashunit.test.assert_string_contains()
{
	LINE=$BASH_LINENO
	bashunit.test._expects_pass bashunit.test._assert_string_contains "$1" "$2"
}

# Assert <string> does not contain <sub-string>
# USAGE: bashunit.test.assert_string_contains.expects_fail <string> <sub-string>
function bashunit.test.assert_string_contains.expects_fail()
{
	LINE=$BASH_LINENO
	bashunit.test._expects_fail bashunit.test._assert_string_contains "$1" "$2"
}

# This function asserts if two values are equal.
# USAGE: bashunit.test.assert_value <value> <expected>
# RETURN: 0 (true) 1 (false)
function bashunit.test.assert_value()
{
	LINE=$BASH_LINENO
	bashunit.test._expects_pass bashunit.test._assert_value "$@"
}

# This function asserts if two arrays are equal.
# It takes the name of the array variables to look them up.
# USAGE: bashunit.test.assert_value <name_of_array> <name_of_expected_array>
# RETURN: 0 (true) 1 (false)
function bashunit.test.assert_array()
{
	LINE=$BASH_LINENO
	bashunit.test._expects_pass bashunit.test._assert_array "$1" "$2"
}

# This function asserts if two values are not supposed to be equal.
# USAGE: bashunit.test.assert_value.expects_fail <value> <not_expected>
# RETURN: 0 (true) 1 (false)
function bashunit.test.assert_value.expects_fail()
{
	LINE=$BASH_LINENO
	bashunit.test._expects_fail bashunit.test._assert_value "$@"
}

# This function asserts the return of a function call.
# USAGE: bashunit.test.assert_return <function> <arguments>
# RETURN: 0 (true) 1 (false)
function bashunit.test.assert_return()
{
	LINE=$BASH_LINENO
	if ! bashunit.test._assert_function_exists "$1"; then
		return 1
	fi
	bashunit.test._expects_pass bashunit.test._assert_return "$@"
}

# This function asserts if a function call fails.
# USAGE: bashunit.test.assert_return.expects_fail <function> <arguments>
# RETURN: 0 (true) 1 (false)
function bashunit.test.assert_return.expects_fail()
{
	LINE=$BASH_LINENO
	if ! bashunit.test._assert_function_exists "$1"; then
		return 1
	fi
	bashunit.test._expects_fail bashunit.test._assert_return "$@"
}

# This function asserts the output of a function call.
# USAGE: bashunit.test.assert_output <function> <expected> <arguments>
# RETURN: 0 (true) 1 (false)
function bashunit.test.assert_output()
{
	LINE=$BASH_LINENO
	if ! bashunit.test._assert_function_exists "$1"; then
		return 1
	fi
	bashunit.test._expects_pass bashunit.test._assert_output "$@"
}

# This function asserts if the output of a function call is not the same as the expected.
# USAGE: bashunit.test.assert_output.expects_fail <function> <expected> <arguments>
# RETURN: 0 (true) 1 (false)
function bashunit.test.assert_output.expects_fail()
{
	LINE=$BASH_LINENO
	if ! bashunit.test._assert_function_exists "$1"; then
		return 1
	fi
	bashunit.test._expects_fail bashunit.test._assert_output "$@"
}

# This function asserts if the function exits with 0.
# USAGE: bashunit.test.assert_exit_code <function> <arguments>
# RETURN: 0 (true) 1 (false)
function bashunit.test.assert_exit_code()
{
	LINE=$BASH_LINENO
	if ! bashunit.test._assert_function_exists "$1"; then
		return 1
	fi
	bashunit.test._expects_pass bashunit.test._assert_exit_code "$@"
}

# This function asserts if the function does not exit with 0.
# USAGE: bashunit.test.assert_exit_code <function> <arguments>
# RETURN: 0 (true) 1 (false)
function bashunit.test.assert_exit_code.expects_fail()
{
	LINE=$BASH_LINENO
	if ! bashunit.test._assert_function_exists "$1"; then
		return 1
	fi
	bashunit.test._expects_fail bashunit.test._assert_exit_code "$@"
}

# This function mocks and existing function by overriding it.
# Also it saves the function to be mocked as BASHUNIT_MOCK_<func_name>,
# so that it can be restored afterwards by callin bashunit.test.unmock.
# USAGE: bashunit.test.mock <function_name> <mock_function_name>
# RETURN: --
function bashunit.test.mock()
{
	if [ -z "$1" ]; then
		bashunit.utils.exit_with_msg "name of function to be mocked must be provided."
		return 1
	fi

	if [ -z "$2" ]; then
		bashunit.utils.exit_with_msg "mock function must be provided."
		return 1
	fi

	bashunit.utils.function_exists_or_fail "$2"

	bashunit.test._save_mock "$1"
	bashunit.test._override_function "$1" "$2"

	return 0
}

# This function overrides the given function with a new one.
# USAGE: bashunit.test._override_function <func_to_be_overrided> <func_to_override>
# RETURN: 0 (true) 1 (false)
function bashunit.test._override_function()
{
	if bashunit.utils.function_exists "$2" ; then
		local new_func_src
		new_func_src=$(declare -f "$2")
		if [ -z "$new_func_src" ]; then
			bashunit.utils.exit_with_msg "could not retrieve declaration of '$2' while trying to override!"
		fi
		local newname_func="$1${new_func_src#$2}"
		eval "$newname_func"
		return $?
	fi
	return 1
}

# This function unmocks the previous mocked function by restoring its source code.
# USAGE: bashunit.test.unmock <function_name>
# RETURN: --
function bashunit.test.unmock()
{
	local name="${BASHUNIT_MOCK_PREFIX}$1"
	if bashunit.test._override_function "$1" "$name" ; then
		unset -f "$name"
	fi
}

# This function creates a mock of the specified function with the
# given return.
# USAGE: bashunit.test.mock.returns <function_name> <return>
# RETURN: --
function bashunit.test.mock.returns()
{
	bashunit.test._mock_build "return" "$1" "$2"
}

# This function creates a mock of the specified function with the
# given output.
# USAGE: bashunit.test.mock.outputs <function_name> <return>
# RETURN: --
function bashunit.test.mock.outputs()
{
	bashunit.test._mock_build "echo" "$1" "$2"
}

# This function creates a mock of the specified function with the
# given exit code.
# USAGE: bashunit.test.mock.exits <function_name> <return>
# RETURN: --
function bashunit.test.mock.exits()
{
	bashunit.test._mock_build "exit" "$1" "$2"
}

# internal functions
function bashunit.test._save_mock()
{
	local save_name="${BASHUNIT_MOCK_PREFIX}$1"
	if ! bashunit.utils.function_exists "$save_name" ; then
		bashunit.test._override_function "$save_name" "$1"
	fi
	return $?
}

function bashunit.test._mock_build()
{
	bashunit.test._save_mock "$2"
	local func="$2()
	{
		$1 $3;
	}"
	eval "$func"
}

function bashunit.test._assert_exit_code()
{
	"$@" 1>/dev/null 2>/dev/null
	local rc=$?
	if [[ $rc -ne 0 ]]; then
		return 1
	fi
	return 0
}

function bashunit.test._ignore_traps()
{
	return 0
}

function bashunit.test._expects_pass()
{
	bashunit.test._inc_nr_tests
	local output
	output=$("$@")
	if [ $? -ne 0 ]; then
		printf "\033[31mF\033[m"
		bashunit.test._inc_nr_failed_tests
		bashunit.test._append_output "\033[31m$TESTCASE/${FUNCNAME[2]}:$LINE criteria should not happen\033[m: $output"
		return 1
	fi
	echo -n "."
	return 0
}

function bashunit.test._expects_fail()
{
	bashunit.test._inc_nr_tests
	local output
	local -i rc

	# hack for when dealing with exit codes which causes some issues in linux
	if [[ "$1" =~ _exit_code ]]; then
		("$@")
		rc=$?
		output="exit code [$rc]"
	else
		output=$("$@")
		rc=$?
	fi
	if [ $rc -ne 0 ]; then
		echo -n "."
		return 0
	fi
	printf "\033[31mF\033[m"
	bashunit.test._inc_nr_failed_tests
	bashunit.test._append_output "\033[31m$TESTCASE/${FUNCNAME[2]}:$LINE criteria should not happen\033[m: $output"
	return 1
}

function bashunit.test._append_output()
{
	local str="$TESTSUITE_OUTPUT\n$1"
	TESTSUITE_OUTPUT="$str"
}

function bashunit.test._assert_return()
{
	local func=$1
	shift 1
	if $func "$@" ; then
		echo "return [$?] matches expected [$?]"
		return 0
	else
		echo "return [$?] does not match expected [0]"
		return 1
	fi
}

function bashunit.test._assert_output()
{
	local func
	local expected
	local output
	func=$1
	expected="$2"
	shift 2
	output="$($func "$@")"
	bashunit.test._assert_value "$output" "$expected"
}

function bashunit.test._assert_function_exists()
{
	if ! declare -F "$1" >/dev/null; then
		printf "\033[31mF\033[m"
		bashunit.test._append_output "\033[31m$TESTCASE/${FUNCNAME[2]}:$LINE criteria should not happen\033[m: function to test doesn't exist: $1"
		return 1
	fi

	return 0
}

function bashunit.test._assert_array()
{
	# sad but true, ${!...} works not with arrays
	# so indirection won't help here and we need
	# to use 'eval' (search for '${!prefix*}' in
	# the 'man bash' for explanation)
	eval "local -a array_to_test=( \"\${${1}[@]}\" )"
	eval "local -a array_expected=( \"\${${2}[@]}\" )"

	if [ ${#array_to_test[*]} -ne ${#array_expected[*]} ]; then
		echo "array (${array_to_test[*]}) does not match expected array" \
			"(${array_expected[*]}), size mismatch (${#array_to_test[*]} != ${#array_expected[*]})"
		return 1
	fi

	for ((i=0; i<${#array_to_test[*]}; i++)); do
		if [ "${array_to_test[$i]}" != "${array_expected[$i]}" ]; then
			echo "array (${array_to_test[*]}) does not match expected array (${array_expected[*]}), values mismatch"
			return 1
		fi
	done

	echo "array (${array_to_test[*]}) matches expected array (${array_expected[*]})"
	return 0
}

function bashunit.test._assert_value()
{
	local output="$1"
	local expected="$2"
	if [[ "$output" = "$expected" ]] ; then
		echo "output [$output] matches expected [$expected]"
		return 0
	fi
	echo "output [$output] does not match expected [$expected]"
	return 1
}

function bashunit.test._assert_string_contains()
{
	if ! bashunit.utils.string_contains "$1" "$2" --literal; then
		echo "string [${1}] does not contain [${2}]"
		return 1
	fi
	echo "string [${1}] contains [${2}]"
	return 0
}

function bashunit.test._run_test_case()
{
	source "$1"
	cd "$(dirname "$1")"
	local testcase
	local testcases
	testcase=$(basename "$1")
	testcases=$(grep "testcase_" "$1" | sed -n -e "s#function \(.*\)().*#\1#p")
	for test in $testcases; do
		bashunit.test._start_testcase "$testcase"
		$test
		bashunit.test._inc_nr_testcases
		bashunit.test._end_testcase
	done
}

function bashunit.test._start_testcase()
{
	TESTCASE_NR_FAILED_TESTS=0
	TESTCASE_NR_TESTS=0
	TESTCASE=$1
	bashunit.test._restore_state
}

function bashunit.test._end_testcase()
{
	local rc=$TESTCASE_NR_FAILED_TESTS
	TESTCASE_NR_FAILED_TESTS=0
	TESTCASE_NR_TESTS=0
	bashunit.test._clear_mocks
	return $rc
}

function bashunit.test._start_suite()
{
	bashunit.utils.override_exit_handler "bashunit.test._ignore_traps"
	TESTSUITE_NR_TESTS=0
	TESTSUITE_NR_FAILED_TESTS=0
	TESTSUITE_NR_PASSED_TESTS=0
	TESTSUITE_OUTPUT=""
	TESTSUITE_NR_TESTCASES=0
	echo
}

function bashunit.test._end_suite()
{
	let TESTSUITE_NR_PASSED_TESTS=$TESTSUITE_NR_TESTS-$TESTSUITE_NR_FAILED_TESTS
	if [ -n "$TESTSUITE_OUTPUT" ]; then
		echo -e "\n$TESTSUITE_OUTPUT"
	fi
	if [ $TESTSUITE_NR_TESTS -gt 0 ]; then
		if [ $TESTSUITE_NR_FAILED_TESTS -gt 0 ]; then
			printf "\n\n%d tests (%d assertions, \033[32m%d passed, \033[m\033[31m%d failed\033[m)\n\n" $TESTSUITE_NR_TESTCASES $TESTSUITE_NR_TESTS $TESTSUITE_NR_PASSED_TESTS $TESTSUITE_NR_FAILED_TESTS
		else
			printf "\n\n\033[32mOK \033[m(%d tests, %d assertions)\n\n" $TESTSUITE_NR_TESTCASES $TESTSUITE_NR_TESTS
		fi
	else
		printf "No tests executed.\n\n"
	fi

	if [ $TESTSUITE_NR_FAILED_TESTS -gt 0 ]; then
		return 1
	fi
	return 0
}

function bashunit.test._inc_nr_tests()
{
	let TESTCASE_NR_TESTS++
	let TESTSUITE_NR_TESTS++
}

function bashunit.test._inc_nr_failed_tests()
{
	let TESTCASE_NR_FAILED_TESTS++
	let TESTSUITE_NR_FAILED_TESTS++
}

function bashunit.test._inc_nr_testcases()
{
	let TESTSUITE_NR_TESTCASES++
}

function bashunit.test._clear_mocks()
{
	local functions
	local mocked_function
	functions=$(declare -F | grep "$BASHUNIT_MOCK_PREFIX")
	for mock in $functions; do
		mocked_function=$(echo "$mock" | sed -n -e "s/.*${BASHUNIT_MOCK_PREFIX}\(.*\)/\1/p")
		if [ -n "$mocked_function" ]; then
			bashunit.test.unmock "$mocked_function"
		fi
	done
}

function bashunit.test._save_state()
{
	local var
	for var in ${!BASHUNIT_@}
	do
		if [[ ! $var =~ BASHUNIT_MOCK* ]]; then
			export SAVE_$var="${!var}"
		fi
	done
}

function bashunit.test._restore_state()
{
	local var
	for var in ${!SAVE_BASHUNIT_@}
	do
		if [[ ! $var =~ BASHUNIT_MOCK* ]]; then
			export ${var/SAVE_/}="${!var}"
		fi
	done
}
