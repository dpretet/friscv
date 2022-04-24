#!/usr/bin/env bash

# -e: exit if one command fails
# -o pipefail: causes a pipeline to fail if any command fails
# set -e -o pipefail
set -e

#------------------------------------------------------------------------------
# Variables and setup
#------------------------------------------------------------------------------

# Timeout upon which the simulation is ran
TIMEOUT=200000
# Minumum value the program counter should reach in bytes
MIN_PC=65692
NO_VCD=0

source ../common/functions.run.sh


#------------------------------------------------------------------------------
# Main
#------------------------------------------------------------------------------

main() {

    echo "INFO: Start Apps Testsuite"
    PID=$$
    echo "PID: $PID"

    get_args "$@"

    # Clean up compiled applications and exit
    if [ $do_clean -eq 1 ]; then
        for dir in tests/*/; do
            if [ "$dir" != "tests/common/" ]; then
                echo "INFO: Clean $dir"
                make clean -C "$dir";
            fi
        done
        exit 0;
    fi

    # Build all applications
    echo "INFO: Compile applications"
    for dir in tests/*/; do
        if [ "$dir" != "tests/common/" ]; then
            echo "INFO: Compile $dir"
            make -C "$dir";
        fi
    done

    # If user specified a testcase, or a testsuite, use it
    if [[ -n $TC ]]; then
        run_testsuite "$TC"
    # Else run all the supported testsuite
    else
        # Execute the testsuites
        run_testsuite "./tests/*.v"
    fi

    # OK, sounds good, exit gently
    echo -e "${GREEN}SUCCESS: Apps testsuite successfully terminated ^^${NC}"

    exit 0
}

main "$@"
