# distributed under the mit license
# https://opensource.org/licenses/mit-license.php

# distributed under the mit license
# https://opensource.org/licenses/mit-license.php

#include "riscv_test.h"
#include "test_macros.h"

# Test 0: M-mode <-> U-mode transition.
#
# Basic test to ensure we can move back and forth the modes and manage correctly ecall/mret and
# execute a basic program. It also checks the error management if u-mode runtime tries to use m-mode
# instructions or tries to access CSR registers reserved to m-mode
#
# x3/gp is the tes number in the unit test flow, must be greater than 0
# 0 means the processor din't move out the initialization correctly and is stucked
#
# x20/s4 stores a count of ecall/trap executed, used to ensure
# we enter the right number of time into them along the test
#
# x31 is the error status register to trigger the testbench status
# when encounter a problem during the testcase

RVTEST_RV64U
RVTEST_CODE_BEGIN

j TEST

EXP_SERVICE:

# Not supported for the moment
ECALL_SUPERVISOR_MODE:
    add x31, x31, 1
    ebreak

ECALL_USER_MODE:
    add x20, x20, 1
    # Check mstatus.mpp is correct, storing u-mode
    li t3, 0x1800
    csrr t4, mstatus
    and t4, t4, t3
    bne x0, t4, fail
    # Increment PC value to return next instruction
    csrr t4, mepc
    add t4, t4, 4
    csrw mepc, t4
    mret

ECALL_MACHINE_MODE:
    ebreak

ILLEGAL_INSTRUCTION:
    add x20, x20, 1
    # Increment PC value to return next instruction
    csrr t4, mepc
    add t4, t4, 4
    csrw mepc, t4
    mret

TEST:

# Try a basic ecall instruction
TEST1:
    ecall
    li x1, 1
    bne x20, x1, fail

# Try to mret with user mode
TEST2:
    mret
    add x1, x1, 1
    bne x20, x1, fail

# Try to access machine-mode CSR
TEST3:
    csrr t4, mstatus
    add x1, x1, 1
    bne x20, x1, fail

INTP:
    ebreak


j pass

TEST_PASSFAIL

RVTEST_CODE_END

  .data
RVTEST_DATA_BEGIN

  TEST_DATA

RVTEST_DATA_END
