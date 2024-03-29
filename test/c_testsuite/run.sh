#!/usr/bin/env bash

# distributed under the mit license
# https://opensource.org/licenses/mit-license.php

# -e: exit if one command fails
# -o pipefail: causes a pipeline to fail if any command fails
# set -e -o pipefail

#------------------------------------------------------------------------------
# Variables and setup
#------------------------------------------------------------------------------

cfg_file="config.cfg"

# Timeout upon which the simulation is ran
TIMEOUT=200000
# Minumum value the program counter should reach in bytes
MIN_PC=65692

source ../common/functions.sh


#------------------------------------------------------------------------------
# Main
#------------------------------------------------------------------------------

main() {

    echo "INFO: Start C Testsuite"
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
        clean
    fi

    # Build all applications
    if [ "$NO_COMPILE" -eq 0 ]; then
        echo "INFO: C tests"
        set -e
        for dir in tests/*/; do
            if [ "$dir" != "tests/common/" ]; then
                echo "INFO: Compile $dir"
                make -C "$dir";
            fi
        done
        set +e
    fi

    # If user specified a testcase, or a testsuite, use it
    if [[ -n $TC ]]; then
        run_testsuite "$TC" "$cfg_file"
    # Else run all the supported testsuite
    else
        # Execute the testsuites
        run_testsuite "./tests/*.v" "$cfg_file"
    fi
}

main "$@"
