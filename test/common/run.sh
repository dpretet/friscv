#!/usr/bin/env bash

# distributed under the mit license
# https://opensource.org/licenses/mit-license.php

# -e: exit if one command fails
# -o pipefail: causes a pipeline to fail if any command fails
# set -e -o pipefail

#------------------------------------------------------------------------------
# Variables and setup
#------------------------------------------------------------------------------

# Don't assert a testbench error if X31 is asserted
ERROR_STATUS_X31=1

source ../common/functions.sh


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

    # Compile appplication if necessary
    if [ $NO_COMPILE -eq 0 ]; then
        if [ -n "$(find tests/ -maxdepth 1 -name \*.v -print -quit)" ] ; then
            echo "INFO: Found compiled programs, execute ./run -C to rebuild from scratch"
        else
            make -C ./tests XLEN=$XLEN
        fi
    fi

    # If user specified a testcase, or a testsuite, use it
    if [[ -n $TC ]]; then
        run_testsuite "$TC"
    # Else run all the supported testsuite
    else
        # Execute the testsuites
        run_testsuite "./tests/rv32ui-p*.v"
        if [[ -f "./tests/rv32um-p*.v" ]]; then run_testsuite "./tests/rv32um-p*.v"; fi
    fi

    # OK, sounds good, exit gently
    echo -e "${GREEN}SUCCESS: RISCV compliance testsuite successfully terminated ^^${NC}"

    exit 0
}

main "$@"
