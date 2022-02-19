#!/usr/bin/env bash

# -e: exit if one command fails
# -o pipefail: causes a pipeline to fail if any command fails
# set -e -o pipefail

#------------------------------------------------------------------------------
# Variables and setup
#------------------------------------------------------------------------------

source ../common/functions.run.sh


#------------------------------------------------------------------------------
# Main
#------------------------------------------------------------------------------

main() {

    echo "INFO: Start RISCV Compliance Testsuite"
    PID=$$
    echo "PID: $PID"

    get_args "$@"

    # Then clean temp files into testcase folders
    if [ $do_clean -eq 1 ]; then clean; fi

    # If user specified a testcase, or a testsuite, use it
    if [ $TC!="" ]; then
        run_testsuite "$TC"
    # Else run all the supported testsuite
    else
        # Execute the testsuites
        run_testsuite "./tests/rv32ui-p*.v"
        run_testsuite "./tests/rv32um-p*.v"
    fi

    # OK, sounds good, exit gently
    echo -e "${GREEN}SUCCESS: RISCV compliance testsuite successfully terminated ^^${NC}"

    exit 0
}

main "$@"
