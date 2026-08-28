#!/usr/bin/env bash

# distributed under the mit license
# https://opensource.org/licenses/mit-license.php

# -e: exit if one command fails
# -o pipefail: causes a pipeline to fail if any command fails
# set -e -o pipefail

#------------------------------------------------------------------------------
# Variables and setup
#------------------------------------------------------------------------------

do_clean=0

RED='\033[0;31m'
BLUE='\033[0;34m'
GREEN='\033[0;32m'
NC='\033[0m' # No Color


#----------------------------------------------------------------
# This section gathers parameters enabled or setup conditionally
# in a flow (WBA, C, RISCV, ...)
#----------------------------------------------------------------

# Used to format the RAM file
INST_PER_LINE=
# Boot address, will be determined by python during elf extraction
BOOT_ADDR=0
# Force run without trying to compile again C or ASM programs
# Can be overridden by -- no-compile argument
NO_COMPILE=0
# Timeout upon which the simulation is ran
[[ -z $TIMEOUT ]] && TIMEOUT=100000
# Testbench configuration: 0="CORE", 1="PLATFORM"
[[ -z $TB_CHOICE ]] && TB_CHOICE=0
# Specific testcase(s) to run
TC=
# Use Icarus Verilog simulator
[[ -z $SIM ]] && SIM="verilator"
# Minimum program counter value a test needs to reach, in bytes
[[ -z $MIN_PC ]] && MIN_PC=65908
# Don't dump waveform during simulation, dumped by default
[[ -z $NO_WAVE ]] && NO_WAVE=0
# INTERACTIVE enable a UART to read/write from Verilator
[[ -z $INTERACTIVE ]] && INTERACTIVE=0
# RAM is by default in compliance mode
[[ -z $RAM_MODE ]] && RAM_MODE="compliance"

# Enable logging of some core events to trace the execution
[[ -z $TRACE_CONTROL ]] && TRACE_CONTROL=1
[[ -z $TRACE_CACHE ]] && TRACE_CACHE=1
[[ -z $TRACE_BLOCKS ]] && TRACE_BLOCKS=1
[[ -z $TRACE_FETCHER ]] && TRACE_FETCHER=1
[[ -z $TRACE_PUSHER ]] && TRACE_PUSHER=1
[[ -z $TRACE_TB_RAM ]] && TRACE_TB_RAM=1
[[ -z $TRACE_REGISTERS ]] && TRACE_REGISTERS=1

# Variable used to check if RTL sources or testbench changed. Only compile if 1
to_compile=0

# Gather the testsuite status
ts_res=""
ts_ret=0


#------------------------------------------------------------------------------
# Read a configuration file listing parameters and values, comma separated
#------------------------------------------------------------------------------
read_config() {

    cen=0 # cache enable
    cw=32 # cache width

    DEFINES="FRISV_SIM=1;"

    while IFS=, read -r name value; do
        DEFINES="${DEFINES}${name}=${value};"
        [[ "$name" == "CACHE_BLOCK_W" ]] && cw="$value"
        [[ "$name" == "CACHE_EN" ]] && cen="$value"
    done < "$1"

    # Compute the number of instruction per line to format in RAM init file for the instruction cache
    [[ "$cen" -eq 1 ]] && INST_PER_LINE=$(($cw/32)) || INST_PER_LINE=1
}
#------------------------------------------------------------------------------

#------------------------------------------------------------------------------
# Clean compiled programs
#------------------------------------------------------------------------------
clean() {
    make -C ./tests clean
    rm -fr build
    rm -f "./rv*.*v"
    rm -f "./*.vcd"
    rm -f "./*.fst"
    rm -f "./*.txt"
    rm -f "./*.log"
    rm -f "./*.csv"
    rm -f "./*.out"
    rm -f "./rtl.md5*"
    rm -f "./testcase.name"
    rm -f "./test.v"
    exit 0
}
#------------------------------------------------------------------------------


#------------------------------------------------------------------------------
# Get testbench defines and print them
#------------------------------------------------------------------------------

get_defines() {

    read_config "$1"

    # Print testcase description and its configuration
    echo "  - Config file:      $cfg_file"
    echo "  - BOOT_ADDR:        $BOOT_ADDR"
    echo "  - TIMEOUT:          $TIMEOUT"
    echo "  - MIN_PC:           $MIN_PC"
    echo "  - TB_CHOICE:        $TB_CHOICE (0=CORE, 1=PLATFORM)"
    echo "  - TCNAME:           $test_name"
    echo "  - SIMULATOR:        $SIM"
    echo "  - NO_WAVE:          $NO_WAVE"
    echo "  - INTERACTIVE:      $INTERACTIVE"
    echo "  - RAM_MODE:         $RAM_MODE"

    DEFINES="${DEFINES}BOOT_ADDR=$BOOT_ADDR;"
    DEFINES="${DEFINES}TIMEOUT=$TIMEOUT;"
    DEFINES="${DEFINES}MIN_PC=$MIN_PC;"
    DEFINES="${DEFINES}TB_CHOICE=$TB_CHOICE;"
    DEFINES="${DEFINES}INTERACTIVE=$INTERACTIVE;"

    [[ $RAM_MODE == "performance" ]] && DEFINES="${DEFINES}RAM_MODE_PERF=1;"

    [[ $TRACE_CONTROL   -eq 1 ]] && DEFINES="${DEFINES}TRACE_CONTROL=$TRACE_CONTROL;"
    [[ $TRACE_CACHE     -eq 1 ]] && DEFINES="${DEFINES}TRACE_CACHE=$TRACE_CACHE;"
    [[ $TRACE_BLOCKS    -eq 1 ]] && DEFINES="${DEFINES}TRACE_BLOCKS=$TRACE_BLOCKS;"
    [[ $TRACE_FETCHER   -eq 1 ]] && DEFINES="${DEFINES}TRACE_FETCHER=$TRACE_FETCHER;"
    [[ $TRACE_PUSHER    -eq 1 ]] && DEFINES="${DEFINES}TRACE_PUSHER=$TRACE_PUSHER;"
    [[ $TRACE_REGISTERS -eq 1 ]] && DEFINES="${DEFINES}TRACE_REGISTERS=$TRACE_REGISTERS;"
    [[ $TRACE_TB_RAM    -eq 1 ]] && DEFINES="${DEFINES}TRACE_TB_RAM=$TRACE_TB_RAM;"

    [[ $NO_WAVE -eq 1 ]] && DEFINES="${DEFINES}NO_WAVE=1;"

    return 0
}
#------------------------------------------------------------------------------


#------------------------------------------------------------------------------
# Prepare a string to print once all the testsuite has been executed.
#------------------------------------------------------------------------------
gather_result() {

    ec=$(grep -c "ERROR:" tc.log)
    msg=$(grep -ni "ERROR:" tc.log)

    if [ "$2" -eq 1 ] || [ "$ec" != 0 ]; then
        ts_res="${ts_res}  ❌ $1\n"
        ts_res="${ts_res}$msg\n"
    else
        ts_res="${ts_res}  ✅ $1\n"
    fi
}
#------------------------------------------------------------------------------

#------------------------------------------------------------------------------
# Check the RTL files changed. If yes, rerun the complete build, else only run
# Returns:
#   - 1 if never has been compiled
#   - 1 if sources didn't changed
#   - 0 otherwise
#------------------------------------------------------------------------------
code_changed() {

    echo "INFO: Check design changes"
    md5sum ../../rtl/* ../common/*.*v ./friscv_testbench.sv ../common/*.cpp > rtl.md5.new

    if [ ! -e rtl.md5 ]; then
        echo "INFO: No precompiled RTL found"
        mv rtl.md5.new rtl.md5
        to_compile=1
    else
        if ! cmp "./rtl.md5" "./rtl.md5.new" > /dev/null 2>&1
        then
            echo "INFO: RTL changed. Will recompile it"
            mv rtl.md5.new rtl.md5
            to_compile=1
        fi
    fi
}
#------------------------------------------------------------------------------


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

        echo -e "${BLUE}INFO: Execute ${test}${NC}"

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

        # The testbench executable may be reused by a testsuite. Pass the
        # testcase name at runtime instead of recompiling it into the binary.
        printf '%s\n' "$test_name" > testcase.name

        # Grab all defines necessary for testbench & flow setup
        get_defines "$2"

        # Execute the testcase with SVUT
        svutRun -t ./friscv_testbench.sv \
                -define "$DEFINES" \
                -sim "$SIM" \
                -fst \
                $run_only \
                -include ../../dep/svlogger ../../rtl ../../dep/axi-crossbar/rtl \
                | tee tc.log

        _tc_ret=$?

        # Grab the return code used later to determine the compliance status
        ts_ret=$((ts_ret+_tc_ret))
        # Prepare results to print
        gather_result "$test_name" "$_tc_ret"
        # Pack all intermediate results into a single file
        cat tc.log >> simulation.log
        rm -f tc.log

        # Gather all reports together sorted by timestamp
        python3 ../../dep/svlogger/svlogger.py *.log *.txt
        cp ./svlogger.txt "./tests/$test_name.log"

        # Copy the waveform generated for further debug
        if [ -f "./friscv_testbench.fst" ]; then
            cp ./friscv_testbench.fst "./tests/$test_name.fst"
        fi

        # Create the trace of the C execution (function jumps)
        if [ -f "./trace_control.csv" ] && [ -f "tests/${test_name}.symbols" ]; then
            ../common/trace.py --itrace trace_control.csv \
                               --otrace "tests/${test_name}_trace.csv" \
                               --symbols "tests/${test_name}.symbols"
        fi

        # A flag to indicate next test run within a testsuite can be run-only
        did_compile=1

    done
}
#------------------------------------------------------------------------------


#------------------------------------------------------------------------------
# Execute a testsuite
#------------------------------------------------------------------------------

run_testsuite() {

    echo "INFO: Start testsuite execution"

    # Erase first the temporary files
    rm -f ./test*.v
    rm -f ./*.log
    rm -f ./*.txt
    rm -f ./*.csv
    rm -f simulation.log

    ts_res=""

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

    echo "Execution result:"

    # Exit if execution failed.
    # Double check the execution status within the log
    ec=$(grep -c "ERROR:" simulation.log)

    echo -e "$ts_res"

    if [[ $ec != 0 || $ts_ret != 0 ]]; then
        echo -e "${RED}ERROR: Testsuite failed!${NC}"
        echo "  - error count: $ec"
        echo "  - testsuite status: $ts_ret"
        exit 1
    else
        # OK, sounds good, exit gently
        echo -e "${GREEN}SUCCESS: Testsuite successfully terminated ^^${NC}"
    fi
}
#------------------------------------------------------------------------------


#------------------------------------------------------------------------------
# Grab arguments and values
#------------------------------------------------------------------------------

setup_simulator_env() {
    # Verilator 5.050 uses the Homebrew LZ4 library for FST support on macOS.
    if [[ "$(uname -s)" == "Darwin" ]] && command -v brew >/dev/null 2>&1; then
        brew_prefix=$(brew --prefix)
        export CXXFLAGS="${CXXFLAGS:-} -I${brew_prefix}/include"
        export LDFLAGS="${LDFLAGS:-} -L${brew_prefix}/lib -llz4"
    fi
}

get_args() {

    while [ "$1" != "" ]; do
        case $1 in
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
            --cfg )
                shift
                cfg_file=$1
            ;;
            --nowave )
                shift
                NO_WAVE=1
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

    setup_simulator_env
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
-t    | --timeout           Timeout in number of cycles before the simulation stops (10000 by default, 0 inactivate it)
        --tb                'core' or 'platform' ('core' by default)
        --tc                A specific testcase to launch, can use wildcard if enclosed with ' (Run all by default)
        --simulator         Choose between icarus or verilator (icarus is default)
        --novcd             Don't dump VCD during simulation (Dump by default)
        --nocompile         Don't try to compile C or assembler (CI tests only)
        --cfg               Pass a specific configuration files
EOF
}
#------------------------------------------------------------------------------
