#!/usr/bin/env bash

# -e: exit if one command fails
# -o pipefail: causes a pipeline to fail if any command fails
# set -e -o pipefail

#------------------------------------------------------------------------------
# Variables and setup
#------------------------------------------------------------------------------

source ../common/functions.run.sh
test_ret=0
do_clean=0

RED='\033[0;31m'
BLUE='\033[0;34m'
GREEN='\033[0;32m'
NC='\033[0m' # No Color

# Architecture choice
XLEN=32
# Instruction width
ILEN=32
# Cache line width in bits
CACHE_LINE_W=128
# Number of instruction per cache line
INST_PER_LINE=$(($CACHE_LINE_W/$ILEN))
# Boot address
BOOT_ADDR=0
# Timeout upon which the simulation is ran
TIMEOUT=10000
# Select between CORE and PLATFORM
TB_CHOICE="CORE"



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
