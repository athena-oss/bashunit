# This function checks if the given directory name is valid. If not execution is
# stopped and an error message is thrown. The displayed error message can be passed as
# second argument.
# USAGE:  bashunit.utils.dir_exists_or_fail <directory name> <message>
# RETURN: --
function bashunit.utils.dir_exists_or_fail()
{
	if [ -d "$1" ]; then
		return 0
	fi

	if [ -n "$2" ]; then
		bashunit.utils.exit_with_msg "$2"
		return 1
	fi

	bashunit.utils.exit_with_msg "'$1' is not a directory!"
	return 1
}

# This function prints the given string on STDOUT formatted as info message.
# USAGE:  bashunit.utils.print_info <string>
# RETURN: --
function bashunit.utils.print_info()
{
	bashunit.utils.print_color "blue" "[INFO]" " $1"
}

# This function prints the given string on STDOUT formatted as error message.
# USAGE:  bashunit.utils.print_error <string>
# RETURN: --
function bashunit.utils.print_error()
{
	bashunit.utils.print_color "red" "[ERROR]" " $1"
}

# This function prints the given string on STDOUT formatted as ok message.
# USAGE:  bashunit.utils.print_ok <string>
# RETURN: --
function bashunit.utils.print_ok()
{
	bashunit.utils.print_color "green" "[OK]" " $1"
}

# This function prints the given string on STDOUT formatted as warn message.
# USAGE:  bashunit.utils.print_warn <string>
# RETURN: --
function bashunit.utils.print_warn()
{
	bashunit.utils.print_color "yellow" "[WARN]" " $1"
}

# This function prints the given string on STDOUT formatted as debug message if debug
# mode is set.
# USAGE:  bashunit.utils.print_debug <string>
# RETURN: --
function bashunit.utils.print_debug()
{
	bashunit.utils.print_color "cyan" "[DEBUG]" " $1"
}

# This function prints the given string on STDOUT formatted as fatal message and exit with 1 or the given code.
# USAGE: bashunit.utils.print_fatal <string> [<exit_code>]
# RETURN: --
function bashunit.utils.print_fatal()
{
	exit_code=${2:-1}
	bashunit.utils.print_color "red" "[FATAL]" " $1"
	exit $exit_code
}

# This function prints the given string in a given.utils.on STDOUT. Available.utils.
# are "green", "red", "blue", "yellow", "cyan", and "normal".
# USAGE:  bashunit.utils.print_color <string> [<non.utils.d_string>]
# RETURN: --
function bashunit.utils.print_color
{
	local green
	local red
	local blue
	local yellow
	local cyan
	local normal
	local other
	green=$(printf "\033[32m")
	red=$(printf "\033[31m")
	blue=$(printf "\033[94m")
	yellow=$(printf "\033[43m")
	cyan=$(printf "\033[36m")
	normal=$(printf "\033[m")
	other=${3:-""}
	case $1 in
		"red")
			printf "%s%b\n" "${red}$2${normal}" "$other"
			;;
		"green")
			printf "%s%b\n" "${green}$2${normal}" "$other"
			;;
		"blue")
			printf "%s%b\n" "${blue}$2${normal}" "$other"
			;;
		"yellow")
			printf "%s%b\n" "${yellow}$2${normal}" "$other"
			;;
		"cyan")
			printf "%s%b\n" "${cyan}$2${normal}" "$other"
			;;
		"normal")
			printf "%s%b\n" "${normal}$2${normal}" "$other"
			;;
		*)
			printf "%b" "$2"
			;;
	esac
}

# This function exits with an error message (see athena.utils.exit).
# USAGE:  bashunit.utils.exit_with_msg <error message> [<exit_code>]
# RETURN: --
function bashunit.utils.exit_with_msg()
{
	local exit_code=${2:-1}
	bashunit.utils.print_error "$1" 1>&2
	bashunit.utils.print_stacktrace
	exit $exit_code
}

# This function prints the stacktrace.
# USAGE: bashunit.utils.print_stacktrace
# RETURN: --
function bashunit.utils.print_stacktrace()
{
	local source
	local level=${#FUNCNAME[@]}
	if [ $level -gt 1 ]; then
		printf "\nStacktrace:\n" >&2
		for ((idx=2; idx<$level; idx++)) do
			source="${BASH_SOURCE[$idx]//$ATHENA_BASE_DIR/}:${BASH_LINENO[(($idx - 1))]}"
			printf "\t%s\n" "$source" >&2
		done
	fi
}

# This functions checks if the function with the given name exists.
# USAGE: bashunit.utils.function_exists <name>
# RETURN: 0 (true) 1 (false)
function bashunit.utils.function_exists()
{
	if [ -z "$1" ]; then
		bashunit.utils.exit_with_msg "function name must be specified."
		return 1
	fi

	if ! type -t "$1" 1>/dev/null 2>/dev/null ; then
		return 1
	fi

	return 0
}

# This functions checks if the function with the given name exists,
# if not it will abort the current execution.
# USAGE: athena.utils.function_exists_or_fail <name>
# RETURN: 0 (true) 1 (false)
function bashunit.utils.function_exists_or_fail()
{
	if ! bashunit.utils.function_exists "$1" ; then
		bashunit.utils.exit_with_msg "function does not exist '$1'."
		return 1
	fi

	return 0
}

# This functions overrides the exit handler with the default signals to catch.
# USAGE: bashunit.utils.override_exit_handler <function_name>
# RETURN: --
function bashunit.utils.override_exit_handler()
{
	bashunit.utils.print_info "System traps are now disabled."
	local signals
	# unset the previous traps
	signals="EXIT QUIT ABRT INT TERM ERR KILL STOP HUP"
	bashunit.utils._trap - $signals
	bashunit.utils.register_exit_handler "$1" $signals
}

# This function register the exit handler that takes the decision of
# what to do when interpreting the exit codes and signals.
# USAGE: bashunit.utils.register_exit_handler <function_name> <list_of_signals_to_trap>
# RETURN: --
function bashunit.utils.register_exit_handler()
{
	if [ -z "$1" ]; then
		bashunit.utils.exit_with_msg "function name cannot be empty"
	fi
	local func=$1
	shift
	for sig in "$@"
	do
		bashunit.utils._trap "$func $sig" "$sig"
	done
}

# This function if a string contains a substring. With --literal, regex is not parsed, and there's a literal comparison.
# USAGE:  bashunit.utils.string_contains <string> <sub-string> [--literal]
# RETURN: 0 (true), 1 (false)
function bashunit.utils.string_contains()
{
	if [[ -n "$3" ]] && [[ "$3" == "--literal" ]]; then

		if ! (echo "${1}" | grep -F -- "${2}" 1>/dev/null); then
			return 1
		fi
		return 0
	else
		if [[ ! "$1" =~ $2 ]]; then
			return 1
		fi
		return 0
	fi

	return $?
}

# This function checks if the given argument is a valid absolute path to a directory
# or file. If not, execution is stopped and an error message is thrown. Otherwise the
# absolute path is returned.
# USAGE:  bashunit.utils.absolutepath <file or directory name>
# RETURN: string
function bashunit.utils.absolutepath()
{
	if [[ -z "$1" ]]; then
		return 1
	fi

	local dir
	dir="$(dirname "$1")"
	if [[ ! -d "$dir" ]]; then
		bashunit.utils.exit_with_msg "'$dir' does not exist!"
		return 1
	fi

	local path
	path="$(cd "$dir" && pwd)/$(basename "$1")"
	if [[ ! -f "$path" ]] && [[ ! -d "$path" ]]; then
		bashunit.utils.exit_with_msg "'$path' does not exist!"
		return 1
	fi
	echo "$path"
	return 0
}

# This function executes the native bash trap command.
# USAGE: bashunit.utils._trap <arguments>
# RETURN: --
function bashunit.utils._trap()
{
	trap "$@"
}

