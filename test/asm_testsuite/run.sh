#!/usr/bin/env bash

RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m' # No Color

# -e: exit if one command fails
# -o pipefail: causes a pipeline to fail if any command fails
set -e -o pipefail

# erase first lonely testcases previously built
rm -f ./test*.v
rm -f ./*.log
rm -f ./*.out
# Then clean temp files into testcase folders
 if [ "$#" -eq 1 ] && [ "$1" == 'clean' ]; then
    find . -type d -exec make -C {} clean \;
    rm -f ./test*.*v
    rm -f *.vcd
    exit 0
fi

# Search for all folders and execute makefile to create the asm/verilog files
# Once created, the program are converted along this script to init the RAMs
find . -type d ! -name common -exec make -C {} clean all \; -exec ./bin2hex.py {}/{}.v {}.v \;

echo "INFO: Start ASM Testsuite"
echo "PID: $$"
ret=0
# Parse all available tests one by one and copy them into test.v
# This test.v file name is expected in the testbench to init the data RAM
for test in test*.v; do

    # Get test name by removing the extension
    test_name=${test%%.*}

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
    svutRun -t ./friscv_rv32i_testbench.sv | tee -a simulation.log

    # Copy the VCD generated, create a GTKWave file from the template then
    # add into the path to the good VCD file.
    cp ./friscv_rv32i_testbench.vcd "$test_name.vcd"
    cp ./friscv_rv32i_testbench.gtkw.tmpl "./friscv_rv32i_${test_name}_testbench.gtkw"
    vcd_path=$(realpath "$test_name.vcd")
    sed -i '' "s|__TMPL__|\"${vcd_path}\"|g" "./friscv_rv32i_${test_name}_testbench.gtkw"
done

# Exit if execution failed
if [[ $ret != 0 ]]; then
    echo -e "${RED}Execution testsuite failed"
    exit 1
fi

# Double check the execution status by parsing the log
ec=$(grep -c "ERROR:" simulation.log)

if [[ $ec != 0 ]]; then
    echo -e "${RED}ERROR: !! Execution failed !!"
    exit 1
fi

# OK sounds good, exit gently
echo -e "${GREEN}SUCCESS: RTL Unit Tests flow successfully terminated ^^"
exit 0


###############################################################################
# Tried to use verilator to "syn" the design after a design issue
###############################################################################

# Remove Verilator build folder
# rm -fr build

# verilator -Wall --trace --Mdir build +1800-2017ext+sv +1800-2005ext+v \
#           -Wno-STMTDLY -Wno-UNUSED -Wno-UNDRIVEN -Wno-TIMESCALEMOD -Wno-PINCONNECTEMPTY\
#           -DTEST_INSTRUCTION_NUMBER="$inst_num" -f files.f --cc ./friscv_rv32i_verilator.sv
