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
# Enable both instruction & data caches
CACHE_EN=1
# Cache block width in bits
CACHE_BLOCK_W=128
# Number of instruction per cache block
INST_PER_BLOCK=$(($CACHE_BLOCK_W/$ILEN))
# Boot address, will be determined by python during elf extraction
BOOT_ADDR=0


#----------------------------------------------------------------
# This section gathers parameters enabled or setup conditionally
# in a flow (WBA, C, RISCV, ...)
#----------------------------------------------------------------

# Force run without trying to compile again C or ASM programs
# Can be overridden by -- no-compile argument
NO_COMPILE=0
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
# INTERACTIVE enable a UART to read/write from Verilator
[[ -z $INTERACTIVE ]] && INTERACTIVE=0
# Generate an external IRQ in the core
[[ -z $GEN_EIRQ ]] && GEN_EIRQ=0

[[ -z $TRACE_CONTROL ]] && TRACE_CONTROL=1
[[ -z $TRACE_CACHE ]] && TRACE_CACHE=1
[[ -z $TRACE_BLOCKS ]] && TRACE_BLOCKS=1
TRACE_FETCHER=1
TRACE_PUSHER=1
[[ -z $TRACE_TB_RAM ]] && TRACE_TB_RAM=1

# Variable used to check if RTL sources or testbench changed. Only compile if 1
to_compile=0

#------------------------------------------------------------------------------
# Clean compiled programs
#------------------------------------------------------------------------------
clean() {
    make -C ./tests clean
    rm -fr build
    rm -f ./rv*.*v
    rm -f ./*.vcd
    rm -f ./*.txt
    rm -f ./*.csv
    rm -f ./*.out
    rm -f ./rtl.md5*
    exit 0
}


#------------------------------------------------------------------------------
# Get testbench defines and print them
#------------------------------------------------------------------------------

get_defines() {

    # Print testcase description and its configuration
    echo ""
    echo -e "${BLUE}INFO: Execute ${test}${NC}"
    echo ""
    echo "  - XLEN:             $XLEN"
    echo "  - BOOT_ADDR:        $BOOT_ADDR"
    echo "  - CACHE_EN:         $CACHE_EN"
    echo "  - CACHE_BLOCK_W:    $CACHE_BLOCK_W"
    echo "  - TIMEOUT:          $TIMEOUT"
    echo "  - MIN_PC:           $MIN_PC"
    echo "  - TB_CHOICE:        $TB_CHOICE (0=CORE, 1=PLATFORM)"
    echo "  - TCNAME:           $test_name"
    echo "  - SIMULATOR:        $SIM"
    echo "  - NO_VCD:           $NO_VCD"
    echo "  - INTERACTIVE:      $INTERACTIVE"
    echo "  - ERROR_STATUS_X31: $ERROR_STATUS_X31"
    echo "  - GEN_EIRQ:         $GEN_EIRQ"
    echo "  - TRACE_CONTROL:    $TRACE_CONTROL"
    echo "  - TRACE_CACHE:      $TRACE_CACHE"
    echo "  - TRACE_BLOCKS:     $TRACE_BLOCKS"
    echo "  - TRACE_FETCHER:    $TRACE_FETCHER"
    echo "  - TRACE_PUSHER:     $TRACE_PUSHER"
    echo "  - TRACE_TB_RAM:     $TRACE_TB_RAM"

    DEFINES="${DEFINES}XLEN=$XLEN;"
    DEFINES="${DEFINES}BOOT_ADDR=$BOOT_ADDR;"
    DEFINES="${DEFINES}CACHE_EN=$CACHE_EN;"
    DEFINES="${DEFINES}CACHE_BLOCK_W=$CACHE_BLOCK_W;"
    DEFINES="${DEFINES}TIMEOUT=$TIMEOUT;"
    DEFINES="${DEFINES}MIN_PC=$MIN_PC;"
    DEFINES="${DEFINES}TB_CHOICE=$TB_CHOICE;"
    DEFINES="${DEFINES}TCNAME=$test_name;"
    DEFINES="${DEFINES}NO_VCD=$NO_VCD;"
    DEFINES="${DEFINES}INTERACTIVE=$INTERACTIVE;"
    DEFINES="${DEFINES}ERROR_STATUS_X31=$ERROR_STATUS_X31;"
    DEFINES="${DEFINES}GEN_EIRQ=$GEN_EIRQ;"
    [[ $TRACE_CONTROL -eq 1 ]] && DEFINES="${DEFINES}TRACE_CONTROL=$TRACE_CONTROL;"
    [[ $TRACE_CACHE   -eq 1 ]] && DEFINES="${DEFINES}TRACE_CACHE=$TRACE_CACHE;"
    [[ $TRACE_BLOCKS  -eq 1 ]] && DEFINES="${DEFINES}TRACE_BLOCKS=$TRACE_BLOCKS;"
    [[ $TRACE_FETCHER -eq 1 ]] && DEFINES="${DEFINES}TRACE_FETCHER=$TRACE_FETCHER;"
    [[ $TRACE_PUSHER  -eq 1 ]] && DEFINES="${DEFINES}TRACE_PUSHER=$TRACE_PUSHER;"
    [[ $TRACE_TB_RAM  -eq 1 ]] && DEFINES="${DEFINES}TRACE_TB_RAM=$TRACE_TB_RAM;"

    return 0
}

#------------------------------------------------------------------------------
# Check the RTL files changed. If yes, rerun the complete build, else only run
# Returns:
#   - 1 if never has been compiled
#   - 1 if sources didn't changed
#   - 0 otherwise
#------------------------------------------------------------------------------
code_changed() {

    echo "INFO: Check design changes"
    md5sum ../../rtl/* ./friscv_testbench.sv > rtl.md5.new

    if [ ! -e rtl.md5 ]; then
        echo "No precompiled RTL found"
        mv rtl.md5.new rtl.md5
        to_compile=1
    else
        if ! cmp "./rtl.md5" "./rtl.md5.new" > /dev/null 2>&1
        then
            echo "RTL changed. Will recompile it"
            mv rtl.md5.new rtl.md5
            to_compile=1
        fi
    fi
}

#------------------------------------------------------------------------------
# Tests execution
#------------------------------------------------------------------------------
run_tests() {

    # Check first if we need to compile the sources
    code_changed

    if [[ "$to_compile" -gt 0 ]]; then
        echo "INFO: Compile testbench and sources"
        run_only=""
    else
        run_only="-run-only"
        echo "INFO: Sources didn't change, will not compile the testbench"
    fi

    did_compile=0

    # Execute one by one the available tests
    for test in $1; do

        # Go to run-only once we know the testbench has been compiled one time
        if [[ $did_compile -eq 1 ]]; then
            run_only="-run-only"
            did_compile=0
            echo "Sources didn't change, will not compile the testbench"
        fi

        # Convert the verilog content into a file to init the RAM
        # and grab first address written, expected to be the boot adddress
        BOOT_ADDR=$(../common/bin2hex.py "$test" test.v $INST_PER_LINE)

        # Get test name by removing the extension
        test_file=$(basename "$test")
        test_name=${test_file%%.*}

        ## SVLogger and so extra logging/tracing can be deactivated. Usefull for Apps testsuite
        if [[ -z $NO_SVL ]]; then
            DEFINES="FRISV_SIM=1;USE_SVL=1;"
        else
            DEFINES="FRISV_SIM=1;"
        fi
        get_defines

        # Execute the testcase with SVUT
        svutRun -t ./friscv_testbench.sv \
                -define "$DEFINES" \
                -sim $SIM \
                $run_only \
                -include ../../dep/svlogger ../../rtl ../../dep/axi-crossbar/rtl \
                | tee -a simulation.log

        # A flag to indicate next test run within a testsuite can be run-only
        did_compile=1

        # Grab the return code used later to determine the compliance status
        test_ret=$((test_ret+$?))

        # Copy the VCD generated for further debug
        if [ -f "./friscv_testbench.vcd" ]; then
            cp ./friscv_testbench.vcd "./tests/$test_name.vcd"
        fi

        # Create the trace of the C execution
        if [ -f "./trace_control.csv" ] && [ -f "tests/${test_name}.symbols" ]; then
            ../common/trace.py --itrace trace_control.csv \
                               --otrace "tests/${test_name}_trace.csv" \
                               --symbols "tests/${test_name}.symbols"
        fi

    done

}


#------------------------------------------------------------------------------
# Execute a testsuite
#------------------------------------------------------------------------------

run_testsuite() {

    echo "Start testsuite execution"

    # Erase first the temporary files
    rm -f ./test*.v
    rm -f ./*.log
    rm -f ./*.txt
    rm -f ./*.csv

    # Execute the testsuite
    run_tests "$@"

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
        exit 1
    fi
}
#------------------------------------------------------------------------------


#------------------------------------------------------------------------------
# Grab arguments and values
#------------------------------------------------------------------------------

get_args() {

    while [ "$1" != "" ]; do
        case $1 in
            --cache_en )
                shift
                CACHE_EN=$1
            ;;
            --cache_block )
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
                if [ "$1" == "core" ]; then
                    TB_CHOICE=0
                elif [ "$1" == "platform" ]; then
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

-c    | --clean             Clean-up and exit
-h    | --help              Brings up this menu
-x    | --xlen              XLEN, 32 or 64 bits (32 bits by default)
-t    | --timeout           Timeout in number of cycles before the simulation stops (10000 by default, 0 inactivate it)
        --cache_en          Enable instruction and data caches (Enabled by default)
        --cache_block       Cache line width in bits (128 bits by default)
        --tb                'core' or 'platform' ('core' by default)
        --tc                A specific testcase to launch, can use wildcard if enclosed with ' (Run all by default)
        --simulator         Choose between icarus or verilator (icarus is default)
        --novcd             Don't dump VCD during simulation (Dump by default)
        --nocompile         Don't try to compile C or assembler (CI tests only)
EOF
}
#------------------------------------------------------------------------------
