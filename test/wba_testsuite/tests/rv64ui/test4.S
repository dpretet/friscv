#include "riscv_test.h"
#include "test_macros.h"

# Test 4: JAL/JALR: Throttle execution by jumping back and forth
# 
# This testcase executes memory and arithmetic instructions break up by JAL and
# JALR instruction to ensure branching doesn't introduce failures.

RVTEST_RV64U
RVTEST_CODE_BEGIN

j TEST

BACKnFORTH:
    jalr x0, 0(x20)

TEST:

# x1 register used along the testcase
addi x1, x1, 1
addi x3, x3, 1

# Registers used to compare the results
addi x11, x11, 3
addi x12, x12, 3
addi x13, x13, 4
lui x14, 1

jal x20, BACKnFORTH
jal x20, BACKnFORTH
jal x20, BACKnFORTH

addi x1, x1, 1
sw x1, 0(x0)
jal x20, BACKnFORTH
lw x1, 0(x0)
addi x1, x1, 1
bne x11, x1, fail

sw x1, 0(x0)
addi x1, x1, 1
jal x20, BACKnFORTH
lw x1, 0(x0)
bne x12, x1, fail

lw x1, 0(x0)
jal x20, BACKnFORTH
addi x1, x1, 1
sw x1, 0(x0)
bne x13, x1, fail

lw x1, 0(x0)
jal x20, BACKnFORTH
addi x1, x1, 1
sw x1, 0(x0)
lui x1, 1
bne x14, x1, fail

TEST_PASSFAIL

RVTEST_CODE_END

  .data
RVTEST_DATA_BEGIN

  TEST_DATA

RVTEST_DATA_END
