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

# Architecture choice
XLEN=32
# Instruction width
ILEN=32
# Cache block width in bits
CACHE_BLOCK_W=128
# Number of instruction per cache block
INST_PER_BLOCK=$(($CACHE_BLOCK_W/$ILEN))
# Boot address
BOOT_ADDR=0
# Timeout upon which the simulation is ran
[[ -z $TIMEOUT ]] && TIMEOUT=10000
# Testbench configuration: 0="CORE", 1="PLATFORM"
[[ -z $TB_CHOICE ]] && TB_CHOICE=0
# Specific testcase(s) to run
TC=
# Use Icarus Verilog simulator
[[ -z $SIM ]] && SIM="icarus"
# Minimum program counter value a test needs to reach, in bytes
[[ -z $MIN_PC ]] && MIN_PC=65908
# Don't dump VCD during simulation
[[ -z $NO_VCD ]] && NO_VCD=0
# Force run without trying to compile again C or ASM programs
NO_COMPILE=0
# INTERACTIVE enable a UART to read/write from Verilator
[[ -z $INTERACTIVE ]] && INTERACTIVE=0

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

    # Execute one by one the available tests
    for test in $1; do

        # Convert the verilog content into a file to init the RAM
        BOOT_ADDR=$(../common/bin2hex.py "$test" test.v $INST_PER_LINE)

        # Get test name by removing the extension
        test_file=$(basename $test)
        test_name=${test_file%%.*}

        # Print testcase description and its configuration
        echo ""
        echo -e "${BLUE}INFO: Execute ${test}${NC}"
        echo ""
        echo "  - XLEN:             $XLEN"
        echo "  - BOOT_ADDR:        $BOOT_ADDR"
        echo "  - CACHE_BLOCK_W:    $CACHE_BLOCK_W"
        echo "  - TIMEOUT:          $TIMEOUT"
        echo "  - TB_CHOICE:        $TB_CHOICE (0=CORE, 1=PLATFORM)"
        echo "  - TCNAME:           ${test_name}"
        echo "  - SIMULATOR:        $SIM"
        echo "  - INTERACTIVE:      $INTERACTIVE"
        echo "  - ERROR_STATUS_X31: $ERROR_STATUS_X31"
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

        DEFINES="${DEFINES}CACHE_BLOCK_W=$CACHE_BLOCK_W;"
        DEFINES="${DEFINES}BOOT_ADDR=$BOOT_ADDR;"
        DEFINES="${DEFINES}XLEN=$XLEN;"
        DEFINES="${DEFINES}TIMEOUT=$TIMEOUT;"
        DEFINES="${DEFINES}MIN_PC=$MIN_PC;"
        DEFINES="${DEFINES}TB_CHOICE=$TB_CHOICE;"
        DEFINES="${DEFINES}NO_VCD=$NO_VCD;"
        DEFINES="${DEFINES}INTERACTIVE=$INTERACTIVE;"
        DEFINES="${DEFINES}ERROR_STATUS_X31=$ERROR_STATUS_X31;"
        if [[ -n $NO_RAM_LOG ]]; then
            DEFINES="${DEFINES}NO_RAM_LOG=$NO_RAM_LOG;"
        fi
        DEFINES="${DEFINES}TCNAME=${test_name}"

        # Execute the testcase with SVUT
        svutRun -t ./friscv_testbench.sv \
                -define "$DEFINES" \
                -sim $SIM \
                -include ../../dep/svlogger ../../rtl ../../dep/axi-crossbar/rtl \
                | tee -a simulation.log

        # Grab the return code used later to determine the compliance status
        test_ret=$((test_ret+$?))
        echo "Test return code: $test_ret"

        # Copy the VCD generated for further debug
        if [ -f "./friscv_testbench.vcd" ]; then
            cp ./friscv_testbench.vcd "./tests/$test_name.vcd"
        fi
        # Create the trace of the execution
        if [ -f "./trace.csv" ] && [ -f "tests/${test_name}.symbols" ]; then
            ../common/trace.py --itrace trace.csv \
                               --otrace "./tests/${test_name}_trace.csv" \
                               --symbols "tests/${test_name}.symbols"
        fi
    done

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
    rm -f ./*.vcd
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
            -c | --clean )
                do_clean=1
            ;;
            --tb )
                shift
                if [ "$1" == "CORE" ]; then
                    TB_CHOICE=0
                elif [ "$1" == "PLATFORM" ]; then
                    TB_CHOICE=1
                else
                    usage
                    exit 1
                fi
            ;;
            -t | --timeout )
                shift
                TIMEOUT=$1
            ;;
            --tc )
                shift
                TC=$1
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
-x    | --xlen              XLEN, 32 or 64 bits (32 by default)
-t    | --timeout           Timeout in number of cycles (10000 by default, 0 inactivate it)
-c    | --clean             Clean-up and exit
        --tb                CORE or PLATFORM, CORE is optional. Platform embbeds a core + an AXI4 crossbar
        --tc                A specific testcase to launch, can use wildcard
        --simulator         Choose between icarus or verilator. icarus is default
        --novcd             Don't dump VCD during simulation
        --nocompile         Don't try to compile C or assembler (CI tests only)
EOF
}
#------------------------------------------------------------------------------
