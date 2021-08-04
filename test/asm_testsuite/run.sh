#!/usr/bin/env bash

# -e: exit if one command fails
# -o pipefail: causes a pipeline to fail if any command fails
# set -e -o pipefail

#------------------------------------------------------------------------------
# Varible and setup
#------------------------------------------------------------------------------

test_ret=0
do_clean=0

RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m' # No Color

# Number of bits per cache line
CACHE_LINE_W=128
INST_PER_LINE=$(($CACHE_LINE_W/32))

#------------------------------------------------------------------------------
# Clean compiled programs
#------------------------------------------------------------------------------
clean() {
    find . -type d -exec make -C {} clean \;
    rm -f ./test*.*v
    rm -f ./*.vcd
    rm -f ./*testbench.gtkw
    rm -f ./*.txt
    exit 0
}
#------------------------------------------------------------------------------


#------------------------------------------------------------------------------
# Helper
#------------------------------------------------------------------------------
usage()
{
cat << EOF
usage: bash ./run.sh ...
-l    | --cache_line        (optional)            cache line width in bits
-c    | --clean             (false)               Clean compilation and exit
-h    | --help                                    Brings up this menu
EOF
}
#------------------------------------------------------------------------------


#------------------------------------------------------------------------------
# Tests execution
#------------------------------------------------------------------------------
run_tests() {

    # Search for all folders and execute makefile to create the asm/verilog files
    # Once created, the program are converted along this script to init the RAMs
    echo "INFO: Build ASM/C testcases and create RAM initialization files"
    find . -type d ! -name common -exec make -C {} all \; -exec ./bin2hex.py {}/{}.v {}.v $INST_PER_LINE \;

    # Parse all available tests one by one and copy them into test.v
    # This test.v file name is expected in the testbench to init the data RAM
    for test in test*.v; do

        # Get test name by removing the extension
        test_name=${test%%.*}
        gtk_file="./friscv_rv32i_${test_name}_testbench.gtkw"

        # Copy the testcase to run
        rm -f test.v
        cp "${test_name}.v" test.v

        # Print testcase description
        echo ""
        echo -e "${GREEN}INFO: Execute ${test}${NC}"
        echo ""
        echo "-------------------------------------------------------------------------------------"
        cat "${test_name}/${test_name}.md"
        echo "-------------------------------------------------------------------------------------"
        echo ""

        # Execute the testcase with SVUT. Will stop once it reaches a EBREAK instruction
        svutRun -t ./friscv_rv32i_testbench.sv -define "CACHE_LINE_W=$CACHE_LINE_W" | tee -a simulation.log
        test_ret=$((test_ret+$?))

        # Copy the VCD generated, create a GTKWave file from the template then
        # add into the path to the good VCD file.
        cp ./friscv_rv32i_testbench.vcd "$test_name.vcd"
        cp ./friscv_rv32i_testbench.gtkw.tmpl "$gtk_file"
        sed -i '' "s|__TMPL__|\"$test_name.vcd\"|g" "$gtk_file"
    done
}
#------------------------------------------------------------------------------


#------------------------------------------------------------------------------
# Check the execution ran well
#------------------------------------------------------------------------------
check_status() {
    # Exit if execution failed
    if [[ $test_ret != 0 ]]; then
        echo -e "${RED}ASM testsuite failed :( ${NC}"
        exit 1
    fi
    # Double check the execution status by parsing the log
    ec=$(grep -c "ERROR:" simulation.log)
    if [[ $ec != 0 ]]; then
        echo -e "${RED}ASM testsuite failed :( ${NC}"
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
            -l | --cache_line )
                shift
                CACHE_LINE_W=$1
            ;;
            -c | --clean )
                do_clean=1
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
# Main
#------------------------------------------------------------------------------

main() {

    echo "INFO: Start ASM Testsuite"
    PID=$$
    echo "PID: $PID"

    get_args "$@"

    # erase temporary files
    rm -f ./test*.v
    rm -f ./*.log
    rm -f ./*.out
    rm -f ./*.o
    rm -f ./*.vpi

    # Then clean temp files into testcase folders
    if [ $do_clean -eq 1 ]; then clean; fi

    # Execute the tests
    run_tests

    # Check status of the execution
    check_status

    # OK, sounds good, exit gently
    echo -e "${GREEN}SUCCESS: ASM Unit Test flow successfully terminated ^^${NC}"
    exit 0
}

main "$@"
