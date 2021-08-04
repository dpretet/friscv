#!/usr/bin/env bash

RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m' # No Color

echo "Start RTL Unit Tests flow"
echo "PID: $$"

ts="./friscv_rv32i_control_jump_branch_testbench.sv"

# Check if a specific testsuite is passed
if [[ -n $1 ]]; then
    ts="$1"
fi

timeout 2s svutRun -test "$ts" | tee icarus.log
ret=$?

if [[ $ret != 0 ]]; then
    echo "Execution testsuite failed"
    exit 1
fi

ec=$(grep -c "ERROR:" icarus.log)

if [[ $ec != 0 ]]; then
    echo -e "${RED}ERROR: !! Execution failed !!${NC}"
    exit 1
fi

echo -e "${GREEN}SUCCESS: RTL Unit Test flow successfully terminated ^^${NC}"
exit 0
