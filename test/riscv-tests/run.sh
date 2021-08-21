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

#------------------------------------------------------------------------------
# Clean compiled programs
#------------------------------------------------------------------------------
clean() {
    make -C ./tests clean
    rm -f ./rv*.*v
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
-l    | --cache_line        (optional)            cache line width in bits (128 by default)
-x    | --xlen              (optional)            XLEN (32 or 64 bits, 32 by default)
-c    | --clean             (false)               Clean up and exit
-h    | --help                                    Brings up this menu
EOF
}
#------------------------------------------------------------------------------


#------------------------------------------------------------------------------
# Tests execution
#------------------------------------------------------------------------------
run_tests() {

    if [ -n "$(find tests/ -maxdepth 1 -name \*.elf -print -quit)" ] ; then
        echo "Found compiled programs, execute ./run -C to rebuild from scratch"
    else
        make -C ./tests XLEN=$XLEN
    fi

    # Parse all available tests one by one and copy them into test.v
    # This test.v file name is expected in the testbench to init the data RAM
    for test in ./tests/rv32ui-p*.v; do

        echo $test

        echo "./bin2hex.py ${test} test.v $INST_PER_LINE"
        BOOT_ADDR=$(./bin2hex.py "$test" test.v $INST_PER_LINE)

        # Get test name by removing the extension
        test_file=$(basename $test)
        test_name=${test_file%%.*}
        gtk_file="./${test_name}_testbench.gtkw"

        # Print testcase description
        echo ""
        echo -e "${GREEN}INFO: Execute ${test}${NC}"
        echo ""

        echo "XLEN:         $XLEN"
        echo "BOOT_ADDR:    $BOOT_ADDR"
        echo "CACHE_LINE_W: $CACHE_LINE_W"

        # Execute the testcase with SVUT. Will stop once it reaches a EBREAK instruction
        svutRun -t ./friscv_rv32i_testbench.sv -define "CACHE_LINE_W=$CACHE_LINE_W;BOOT_ADDR=$BOOT_ADDR;XLEN=$XLEN;TCNAME=${test_name}" | tee -a simulation.log
        test_ret=$((test_ret+$?))

        # Copy the VCD generated, create a GTKWave file from the template then
        # add into the path to the good VCD file.
        cp ./friscv_rv32i_testbench.vcd "./tests/$test_name.vcd"
        cp ./friscv_rv32i_testbench.gtkw.tmpl "./tests/$gtk_file"
        sed -i '' "s|__TMPL__|\"$test_name.vcd\"|g" "./tests/$gtk_file"

    done
}
#------------------------------------------------------------------------------


#------------------------------------------------------------------------------
# Check the execution ran well
#------------------------------------------------------------------------------
check_status() {
    # Exit if execution failed
    if [[ $test_ret != 0 ]]; then
        echo -e "${RED}RISCV compliance testssuite failed!${NC}"
        exit 1
    fi
    # Double check the execution status by parsing the log
    ec=$(grep -c "ERROR:" simulation.log)
    if [[ $ec != 0 ]]; then
        echo -e "${RED}ERROR: RISCV compliance testsuite failed!${NC}"
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
            -x | --xlen )
                XLEN=$1
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

    echo "INFO: Start RISCV Testsuite"
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

    # Clean-up before exiting
    rm -f *.vcd
    rm -f test.v
    rm -f *.out

    # Check status of the execution
    check_status

    # OK, sounds good, exit gently
    echo -e "${GREEN}SUCCESS: RISCV compliance testssuite successfully terminated ^^${NC}"

    exit 0
}

main "$@"
