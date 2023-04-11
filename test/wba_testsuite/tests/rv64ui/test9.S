# distributed under the mit license
# https://opensource.org/licenses/mit-license.php

#include "riscv_test.h"
#include "test_macros.h"

# Test 8: Stress out WFI

# x3/gp is the tes number in the unit test flow, must be greater than 0
# 0 means the processor din't move out the initialization correctly and is stucked

# Machine interrupt enable (MSTATUS)
.equ MIE_ON,    0x00000008
.equ MIE_OFF,   0xFFFFFFF7
# Machine external interrupt enable (MIE)
.equ MEIE_ON,   0x00000800
.equ MEIE_OFF,  0xFFFFF7FF

RVTEST_RV64U
RVTEST_CODE_BEGIN

j TEST

TEST:
    # x3/gp is the tes number in the unit test flow, must be greater than 0
    # 0 means the processor din't move out the initialization correctly and is stucked
    li  x3, 0

# Stress out mul
TEST1:
    li x3, 1
    li x10, 2
    li x11, 5
    li x12, 10
    mul x2, x11, x10
    bne x2, x12, fail

# Stress out div
TEST2:
    li x3, 2
    li x10, 2
    li x11, 10
    li x12, 5
    div x2, x11, x10
    bne x2, x12, fail

# Stress out mul surrounded by load store
TEST3:
    li x3, 3
    li x10, 2
    li x11, 5
    li x12, 10
    mul x2, x11, x10
    sw x2, 0(x0)
    lw x2, 0(x0)
    bne x2, x12, fail

# Stress out div surrounded by load store
TEST4:
    li x3, 4
    li x10, 2
    li x11, 10
    li x12, 5
    div x2, x11, x10
    sw x2, 0(x0)
    lw x2, 0(x0)
    bne x2, x12, fail


TEST_PASSFAIL

RVTEST_CODE_END

  .data
RVTEST_DATA_BEGIN

  TEST_DATA

RVTEST_DATA_END
