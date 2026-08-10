## cli.sh
------------
parse_arguments

## common.sh
----------
banner 
log
info
success
warning
error
check_environment
check_commands
print_summary
print_help
section

## constants.sh
------------

STATUS_OK
STATUS_ALREADY_INSTALLED
STATUS_DRY_RUN
STATUS_FAILED

readonly REQUIRED_COMMANDS=(
    bash
    git
    grep
    find
    sort
    awk
    sed
)

readonly PACKAGE_MANAGER_COMMANDS=(
    apt
    apt-cache
    dpkg
)


## doctor.sh
----------
doctor
run_check
check_shellcheck
check_file
check_directory
check_project

## exit_codes.sh
-------------
EXIT_SUCCESS
EXIT_FAILURE
EXIT_BAD_ARGUMENTS
EXIT_ENVIRONMENT


## install_core
----------------
install_all_modules
install_module
install_named_module
print_install_status
install_package
install_with_apt
print_install_summary


## modules.sh
-----------

find_module
find_modules
count_modules
process_modules
print_modules
test_read_module

## packages.sh

Public
------

read_package_list()
count_packages()
count_all_packages()
package_exists()
package_installed()

Private
-------

verify_package()


## system.sh
--------------

detect_system
check_os
check_architecture
check_sudo
check_network
check_commands
check_package_manager
check_required_commands
