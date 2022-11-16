#!/usr/bin/env bash

# distributed under the mit license
# https://opensource.org/licenses/mit-license.php

# -e: exit if one command fails
# -o pipefail: causes a pipeline to fail if any command fails
# set -e -o pipefail
set -e

#------------------------------------------------------------------------------
# Variables and setup
#------------------------------------------------------------------------------

# Disable runtime timeout check for this testbench
TIMEOUT=0

# Minumum value the program counter should reach in bytes
MIN_PC=65692

# Don't drop VCD, to avoid storing GB of raw data
NO_VCD=0

# Enable UART link to the processor (platform only)
INTERACTIVE=1

# Testbench configuration, platform only
TB_CHOICE=1

# Don't assert a testbench error if X31 is asserted
ERROR_STATUS_X31=0

TRACE_CONTROL=0
TRACE_CACHE=0
TRACE_BLOCKS=0
TRACE_FETCHER=0
TRACE_PUSHER=0
TRACE_TB_RAM=0

# Disable external IRQ generation
GEN_EIRQ=0

# Disable SVlogger at compile to avoid useless logs
NO_SVL=0

source ../common/functions.sh


#------------------------------------------------------------------------------
# Main
#------------------------------------------------------------------------------

main() {

    echo "INFO: Start Apps Testsuite"
    PID=$$
    echo "PID: $PID"

    get_args "$@"

    # Use Verilator only
    [[ $SIM == "icarus" ]] && echo "Apps support Verilator only. Will use it"
    SIM="verilator"

    # Use PLATFORM testbench only
    [[ $TB_CHOICE == 0 ]] && echo "Apps support only PLATFORM. Will use it"
    TB_CHOICE=1

    # No timeout for apps while it it's interactive with user inputs
    [[ $TIMEOUT -gt 0 ]] && echo "Deactivate timeout while testbench is in interactive mode"
    TIMEOUT=0

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
