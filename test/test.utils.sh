function testcase_bashunit.utils.dir_exists_or_fail()
{
	bashunit.test.assert_exit_code.expects_fail "bashunit.utils.dir_exists_or_fail" "/non/existing/dir"

	tmpfile=$(bashunit.test.create_tempdir)
	bashunit.test.assert_exit_code "bashunit.utils.dir_exists_or_fail" "$tmpfile"
	rm -r $tmpfile

	bashunit.test.mock "bashunit.utils.exit_with_msg" "_echo_arguments"
	bashunit.test.assert_output "bashunit.utils.dir_exists_or_fail" "My custom message" "/non/existing/dir" "My custom message"
}

function _echo_arguments()
{
	echo -n "$@"
}

function testcase_bashunit.utils.print_info()
{
	expected=$(printf "\033[94m[INFO]\033[m test\n")
	bashunit.test.assert_output "bashunit.utils.print_info" "$expected" "test"
}

function testcase_bashunit.utils.print_error()
{
	expected=$(printf "\033[31m[ERROR]\033[m test\n")
	bashunit.test.assert_output "bashunit.utils.print_error" "$expected" "test"
}

function testcase_bashunit.utils.print_ok()
{
	expected=$(printf "\033[32m[OK]\033[m test\n")
	bashunit.test.assert_output "bashunit.utils.print_ok" "$expected" "test"
}

function testcase_bashunit.utils.print_warn()
{
	expected=$(printf "\033[43m[WARN]\033[m test\n")
	bashunit.test.assert_output "bashunit.utils.print_warn" "$expected" "test"
}

function testcase_bashunit.utils.print_fatal()
{
	expected=$(printf "\033[31m[FATAL]\033[m test\n")
	bashunit.test.assert_output "bashunit.utils.print_fatal" "$expected" "test"
	bashunit.test.assert_exit_code.expects_fail "bashunit.utils.print_fatal" "$expected" "test"
}

function testcase_bashunit.utils.print_debug()
{
	expected=$(printf "\033[36m[DEBUG]\033[m test\n")
	bashunit.test.assert_output "bashunit.utils.print_debug" "$expected" "test"
}

function testcase_bashunit.utils.print_color()
{
	bashunit.test.assert_output "bashunit.utils.print_color" "test" "other" "test"
}

function testcase_bashunit.utils.exit_with_msg()
{
	bashunit.test.assert_exit_code.expects_fail "bashunit.utils.exit_with_msg" "my msg"
}

function testcase_bashunit.utils.function_exists()
{
	bashunit.test.assert_exit_code.expects_fail "bashunit.utils.function_exists" ""
	bashunit.test.assert_return.expects_fail "bashunit.utils.function_exists" "my-non-existing-function"

	bashunit.test.mock.exits "_my_os_function" 1
	bashunit.test.assert_return "bashunit.utils.function_exists" "_my_os_function"
}

function testcase_bashunit.utils.function_exists_or_fail()
{
	bashunit.test.assert_exit_code.expects_fail "bashunit.utils.function_exists_or_fail" ""
	bashunit.test.assert_exit_code.expects_fail "bashunit.utils.function_exists_or_fail" "my-non-existing-function"

	bashunit.test.mock.exits "_my_os_function" 1
	bashunit.test.assert_return "bashunit.utils.function_exists_or_fail" "_my_os_function"
}

function testcase_bashunit.utils.register_exit_handler()
{
	bashunit.test.mock "bashunit.utils._trap" "_my_os_trap"

	bashunit.test.assert_output "bashunit.utils.register_exit_handler" "myfunc sig1 sig1" "myfunc" "sig1"

	bashunit.test.assert_exit_code.expects_fail "bashunit.utils.register_exit_handler"
}

function testcase_bashunit.utils.override_exit_handler()
{
	bashunit.test.mock.outputs "bashunit.utils.print_info" "overriden"
	bashunit.test.mock.returns "bashunit.utils._trap" 0
	bashunit.test.mock.returns "bashunit.utils.register_exit_handler" 0

	bashunit.test.assert_output "bashunit.utils.override_exit_handler" "overriden"
}

function _my_os_trap()
{
	echo "$@"
}

function testcase_bashunit.utils.string_contains()
{
	bashunit.test.assert_return "bashunit.utils.string_contains" "one two three" "three"
	bashunit.test.assert_return.expects_fail "bashunit.utils.string_contains" "one two three" "four"
}

function testcase_bashunit.utils.absolutepath()
{
	bashunit.test.assert_exit_code.expects_fail "bashunit.utils.absolutepath" "/non/existing/dir"

	tmpfile=$(bashunit.test.create_tempfile)
	bashunit.test.assert_output "bashunit.utils.absolutepath" "$tmpfile" "$tmpfile"
	rm $tmpfile
}
