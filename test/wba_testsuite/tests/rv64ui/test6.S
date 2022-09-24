# distributed under the mit license
# https://opensource.org/licenses/mit-license.php

#include "riscv_test.h"
#include "test_macros.h"

# Test 6: RW Outstanding requests
# Check the outstanding requests are properly managed by the
# memfy module by launching batch of requets

# x3/gp is the tes number in the unit test flow, must be greater than 0
# 0 means the processor din't move out the initialization correctly and is stucked


RVTEST_RV64U
RVTEST_CODE_BEGIN

j TEST

TEST:

    # x3/gp is the tes number in the unit test flow, must be greater than 0
    # 0 means the processor din't move out the initialization correctly and is stucked
    li  x3, 1

    # setup expected values in x20-x29
    addi x20, x20, 0
    addi x21, x21, 1
    addi x22, x22, 2
    addi x23, x23, 3
    addi x24, x24, 4
    addi x25, x25, 5
    addi x26, x26, 6
    addi x27, x27, 7
    addi x28, x28, 8
    addi x29, x29, 9

    # First launch a batch of 10 R/W then check the values
    sw x20, 0(x0)
    sw x21, 4(x0)
    sw x22, 8(x0)
    sw x23, 12(x0)
    sw x24, 16(x0)
    sw x25, 20(x0)
    sw x26, 24(x0)
    sw x27, 28(x0)
    sw x28, 32(x0)
    sw x29, 36(x0)

# Bunch of store then load to ensure ordering is correct
TEST_1:

    li  x3, 1

    lw x10, 0(x0)
    lw x11, 4(x0)
    lw x12, 8(x0)
    lw x13, 12(x0)
    lw x14, 16(x0)
    lw x15, 20(x0)
    lw x16, 24(x0)
    lw x17, 28(x0)
    lw x18, 32(x0)
    lw x19, 36(x0)
    
    bne x10, x20, fail
    bne x11, x21, fail
    bne x12, x22, fail
    bne x13, x23, fail
    bne x14, x24, fail
    bne x15, x25, fail
    bne x16, x26, fail
    bne x17, x27, fail
    bne x18, x28, fail
    bne x19, x29, fail

# Multiple load interleaved or not with arithmetic
TEST_2:

    li  x3, 2

    lw x10, 0(x0)
    addi x10, x10, 1
    lw x11, 4(x0)
    addi x11, x11, 2
    
    li x1, 1
    bne x10, x1, fail
    li x1, 3
    bne x11, x1, fail

    lw x10, 0(x0)
    lw x11, 4(x0)
    addi x10, x10, 1
    addi x11, x11, 2
    
    li x1, 1
    bne x10, x1, fail
    li x1, 3
    bne x11, x1, fail



TEST_PASSFAIL

RVTEST_CODE_END

  .data
RVTEST_DATA_BEGIN

  TEST_DATA

RVTEST_DATA_END
