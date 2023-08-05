# distributed under the mit license
# https://opensource.org/licenses/mit-license.php

#include "riscv_test.h"
#include "test_macros.h"

# Test 7: Check Zicntr / Zihpm extensions

# x3/gp is the tes number in the unit test flow, must be greater than 0
# 0 means the processor din't move out the initialization correctly and is stucked


RVTEST_RV64U
RVTEST_CODE_BEGIN

j TEST

TEST:
    # x3/gp is the tes number in the unit test flow, must be greater than 0
    # 0 means the processor din't move out the initialization correctly and is stucked
    li  x3, 0

TEST1:

    li  x3, 1
    csrr x1, cycle
    csrr x2, time
    blt x2, x1, fail

TEST2:

    li  x3, 2
    csrr x1, instret
    csrr x2, instret
    sub x4, x2, x1
    li x5, 1
    bne x4, x5, fail

TEST_PASSFAIL

RVTEST_CODE_END

  .data
RVTEST_DATA_BEGIN

  TEST_DATA

RVTEST_DATA_END
