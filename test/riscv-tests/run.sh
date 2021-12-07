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

    echo "INFO: Start RISCV Testsuite"
    PID=$$
    echo "PID: $PID"

    get_args "$@"

    # Erase first the temporary files
    rm -f ./test*.v
    rm -f ./*.log
    rm -f ./*.out
    rm -f ./*.o
    rm -f ./*.vpi

    # Then clean temp files into testcase folders
    if [ $do_clean -eq 1 ]; then clean; fi

    # Execute the tests
    run_tests "./tests/rv32ui-p*.v"

    # Clean-up before exiting
    rm -f *.vcd
    rm -f *.out

    # Check status of the execution
    check_status

    # OK, sounds good, exit gently
    echo -e "${GREEN}SUCCESS: RISCV compliance testsuite successfully terminated ^^${NC}"

    exit 0
}

main "$@"
