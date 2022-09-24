# distributed under the mit license
# https://opensource.org/licenses/mit-license.php

#include "riscv_test.h"
#include "test_macros.h"

# Test 3: Check FENCE/FENCE.i instructions
# 
# Place FENCE and FENCE.i between ALU and memfy instructions. The test is for the
# moment harmess because the processor doesn't support fence

# x3/gp is the tes number in the unit test flow, must be greater than 0
# 0 means the processor din't move out the initialization correctly and is stucked

RVTEST_RV64U
RVTEST_CODE_BEGIN
   
j TEST

TEST:

# intialize the x1 register used along the testcase
addi x1, x1, 1
# lui  x2, 0
addi x3, x3, 1


# initialize the registers used to compare the results
addi x11, x11, 3
addi x12, x12, 3
addi x13, x13, 4
lui x14, 1

addi x1, x1, 1
sw x1, 0(x0)
fence
lw x1, 0(x0)
addi x1, x1, 1
bne x11, x1, fail

sw x1, 0(x0)
addi x1, x1, 1
fence.i
lw x1, 0(x0)
bne x12, x1, fail

lw x1, 0(x0)
fence.i
addi x1, x1, 1
sw x1, 0(x0)
bne x13, x1, fail

lw x1, 0(x0)
fence
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
