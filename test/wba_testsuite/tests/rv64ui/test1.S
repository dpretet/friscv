# distributed under the mit license
# https://opensource.org/licenses/mit-license.php

# distributed under the mit license
# https://opensource.org/licenses/mit-license.php

#include "riscv_test.h"
#include "test_macros.h"

# Test 1: Sequence of LUI / AUIPC / Arithmetic instructions
#
# Injects a set of alternating LUI / AUIPC / Aritmetic instructions to ensure the
# control unit correctly handles this kind of situation.
#
# All these instructions are handled in one cycle and shouldn't introduce any
# wait cycles between each others.

# x3/gp is the tes number in the unit test flow, must be greater than 0
# 0 means the processor din't move out the initialization correctly and is stucked

RVTEST_RV64U
RVTEST_CODE_BEGIN

j TEST

TEST:

lui  x1, 0
lui  x2, 0
lui  x3, 0

addi x11, x11, 1
auipc x12, 0
addi x12, x12, 36
lui x13, 1
addi x31, x31, 0

auipc x1, 0
lui  x1,0
addi x1, x1, 1

lui  x2, 0
auipc x2, 0
addi x2, x2, 4

addi x3, x3, 2
auipc x3, 2
lui x3, 1

auipc x10, 0
addi x10, x10, 12
bne x11, x1, fail

auipc x10, 0
addi x10, x10, 12
bne x12, x2, fail

auipc x10, 0
addi x10, x10, 12
bne x13, x3, fail

TEST_PASSFAIL

RVTEST_CODE_END

  .data
RVTEST_DATA_BEGIN

  TEST_DATA

RVTEST_DATA_END
