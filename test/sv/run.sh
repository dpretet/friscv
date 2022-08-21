#!/usr/bin/env bash

# distributed under the mit license
# https://opensource.org/licenses/mit-license.php

# -e: exit if one command fails
# -o pipefail: causes a pipeline to fail if any command fails
# set -e -o pipefail

#------------------------------------------------------------------------------
# Variables and setup
#------------------------------------------------------------------------------

test_ret=0
do_clean=0

RED='\033[0;31m'
BLUE='\033[0;34m'
GREEN='\033[0;32m'
NC='\033[0m' # No Color

# Instruction width
ILEN=32
# Cache block width in bits
CACHE_BLOCK_W=128
# Number of instruction per cache block
INST_PER_BLOCK=$((CACHE_BLOCK_W/ILEN))
# Timeout upon which the simulation is ran
[[ -z $TIMEOUT ]] && TIMEOUT=10000
# Testbench to use
TB="./icache_testbench.sv"
# Use Icarus Verilog simulator
[[ -z $SIM ]] && SIM="icarus"
# Don't dump VCD during simulation
[[ -z $NO_VCD ]] && NO_VCD=0
# Force run without trying to compile again C or ASM programs
NO_COMPILE=0
# Number of fetch requests issued by the driver
MAX_TRAFFIC=1000


#------------------------------------------------------------------------------


#------------------------------------------------------------------------------
# Clean compiled programs
#------------------------------------------------------------------------------
clean() {
    make -C ./tests clean
    rm -f ./rv*.*v
    rm -f ./*.vcd
    rm -f ./*.txt
    rm -f data.v
    exit 0
}
#------------------------------------------------------------------------------


#------------------------------------------------------------------------------
# Tests execution
#------------------------------------------------------------------------------
run_tests() {

    # Print testcase description and its configuration
    echo ""
    echo -e "${BLUE}INFO: Execute ${test}${NC}"
    echo ""
    echo "  - CACHE_BLOCK_W:    $CACHE_BLOCK_W"
    echo "  - TIMEOUT:          $TIMEOUT"
    echo "  - TB:               $TB"
    echo "  - SIMULATOR:        $SIM"
    echo "  - MAX_TRAFFIC:      $MAX_TRAFFIC"
    if [[ -n $NO_RAM_LOG ]]; then
        echo "  - NO_RAM_LOG:    $NO_RAM_LOG"
    fi

    # build defines list passed to the testbench
    if [[ $SIM == "icarus" ]]; then
        # Use SVlogger only with Icarus, Verilator sv support being too limited
        DEFINES="USE_ICARUS=1;USE_SVL=1;"
        SIM="icarus"
    else
        DEFINES=""
        SIM="verilator"
    fi

    # Let the internal cache block RAMs to be init to 0
    DEFINES="${DEFINES}CACHE_SIM_ENV=1;"
    DEFINES="${DEFINES}CACHE_BLOCK_W=$CACHE_BLOCK_W;"
    DEFINES="${DEFINES}TIMEOUT=$TIMEOUT;"
    DEFINES="${DEFINES}NO_VCD=$NO_VCD;"
    DEFINES="${DEFINES}MAX_TRAFFIC=$MAX_TRAFFIC;"
    if [[ -n $NO_RAM_LOG ]]; then
        DEFINES="${DEFINES}NO_RAM_LOG=$NO_RAM_LOG;"
    fi
    DEFINES="${DEFINES}TBNAME=${TB}"

    # Execute the testcase with SVUT
    svutRun -t $TB \
            -define "$DEFINES" \
            -sim $SIM \
            -include ../../dep/svlogger ../../rtl \
            | tee -a simulation.log

    # Grab the return code used later to determine the status
    test_ret=$((test_ret+$?))
    echo "Test return code: $test_ret"


}
#------------------------------------------------------------------------------


#------------------------------------------------------------------------------
# Execute a testsuite
#------------------------------------------------------------------------------
run_testsuite() {

    echo "Start testsuite execution"

    # Erase first the temporary files
    rm -f ./test*.v
    rm -f ./*.log
    rm -f ./*.out
    rm -f ./*.o
    rm -f ./*.vpi

    # Execute the testsuite
    run_tests "$@"

    # Clean-up before exiting
    rm -f ./*.out

    # Check status of the execution
    check_status
}
#------------------------------------------------------------------------------


#------------------------------------------------------------------------------
# Check the execution ran well
#------------------------------------------------------------------------------
check_status() {

    echo "Check status"

    # Exit if execution failed.
    # Double check the execution status by parsing the log
    ec=$(grep -c "ERROR:" simulation.log)

    if [[ $ec != 0 || $test_ret != 0 ]]; then
        echo -e "${RED}ERROR: Testsuite failed!${NC}"
        grep -i "Failling" simulation.log
        exit 1
    fi
}
#------------------------------------------------------------------------------


#------------------------------------------------------------------------------
# Grab arguments and values
#------------------------------------------------------------------------------

get_args() {
    # First handle the arguments
    while [ "$1" != "" ]; do
        case $1 in
            -l | --cache_block )
                shift
                CACHE_BLOCK_W=$1
            ;;
            -x | --xlen )
                shift
                XLEN=$1
            ;;
            -m | --max-traffic )
                shift
                MAX_TRAFFIC=$1
            ;;
            -c | --clean )
                do_clean=1
            ;;
            -t | --timeout )
                shift
                TIMEOUT=$1
            ;;
            --tb )
                shift
                TB=$1
            ;;
            --simulator )
                shift
                SIM=$1
            ;;
            --novcd )
                shift
                NO_VCD=1
            ;;
            --nocompile )
                shift
                NO_COMPILE=$1
            ;;
            -h | --help )
                usage
                exit 0
            ;;
            * )
                usage
                exit 1
            ;;
        esac
        shift
    done
}
#------------------------------------------------------------------------------


#------------------------------------------------------------------------------
# Helper
#------------------------------------------------------------------------------
usage()
{
cat << EOF
usage: bash ./run.sh ...
-h    | --help              Brings up this menu
-l    | --cache_block       cache line width in bits (128 by default)
-t    | --timeout           Timeout in number of cycles (10000 by default, 0 inactivate it)
-c    | --clean             Clean-up and exit
-m    | --max-traffic       Maximun number of requests injected by the driver
        --tb                Testbench file path
        --simulator         Choose between icarus or verilator. icarus is default
        --novcd             Don't dump VCD during simulation
        --nocompile         Don't try to compile C or assembler (CI tests only)
EOF
}
#------------------------------------------------------------------------------


#------------------------------------------------------------------------------
# Main
#------------------------------------------------------------------------------

main() {

    echo "INFO: Start Cache Testsuite"
    PID=$$
    echo "PID: $PID"

    get_args "$@"

    # Init files used to initialize the testbench RAMs
    if [ ! -f ram_32b.txt ] ; then
        echo "Create random instruction"
        ./dump_rand_ram.py
    fi

    # Then clean temp files into testcase folders
    if [ $do_clean -eq 1 ]; then clean; fi


    run_testsuite "$TB"

    echo -e "${GREEN}SUCCESS: Cache testsuite successfully terminated ^^${NC}"

    exit 0
}

main "$@"
