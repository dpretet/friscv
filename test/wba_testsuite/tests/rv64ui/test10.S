# distributed under the mit license
# https://opensource.org/licenses/mit-license.php

#include "riscv_test.h"
#include "test_macros.h"

/*
 *  Test 10: RW Outstanding requests + Collision
 *  The test checks concurrent outstanding requests can be issued by Memfy module.
 *  If AXI_ORDERING set to 1 and no data corruption occurs. The test is complementary
 *  to the test 6 which stress out oustanding request issuing and interactions
 *  with ALU modules.
 */

# x3/gp is the test number in the unit test flow, must be greater than 0
# 0 means the processor didn't move out the initialization correctly and is stucked


RVTEST_RV64U
RVTEST_CODE_BEGIN

j TEST

TEST:

# Bunch of store/load to ensure outstanding request issue, STORE then LOAD is OK
TEST_10:

    li x3, 10

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

# First STORE instructions
TEST_11:

    li x3, 11

    # First save values we expect to read back correctly later
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

# Then LOAD instructions
TEST_12:

    li x3, 12

    // Load from memory values we just saved
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

TEST_13:
    // Ensure everything matches
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

# Interleave read and write which target the same address
TEST_21:

    li x3, 21
    li x4, 0
    li x5, 0
    li x6, 0
    li x7, 100
    nop

loop_wr1:
    addi x4, x4, 1
    sw x4, 0(x0)
    lw x6, 0(x0)
    addi x5, x5, 1
    bne x5, x7, loop_wr1
    # check the store then load are ok
    bne x6, x7, fail

/*
    x5 |  x6 |  x7 | (0) | (4) | ix
    ---------------------------------
    0  |  0  |  0  |  0  |  0  | init
    ---------------------------------
    2  |  0  |  1  |  1  |  2  |  1
    4  |  2  |  3  |  3  |  4  |  2
    6  |  4  |  5  |  5  |  6  |  3
    8  |  6  |  7  |  7  |  8  |  4

    x5 = max*2
    x6 = max-1 * 2
    x7 = x5-1
*/

TEST_22:

    li x3, 22
    li x4, 0 // loop index
    li x5, 0
    li x6, 0
    li x7, 0
    li x8, 0 // temp to check results
    sw x0, 0(x0)
    sw x0, 4(x0)
    li x9, 100 // max loop
    nop

loop_wr2:
    addi x5, x5, 1
    sw x5, 0(x0)
    lw x6, 4(x0)
    addi x5, x5, 1
    sw x5, 4(x0)
    lw x7, 0(x0)
    addi x4, x4, 1
    bne x4, x9, loop_wr2

    # x5 = max * 2
    slli x8, x9, 1
    bne x5, x8, fail

    # x6 = (max-1) * 2
    li x8, 1
    sub x8, x9, x8
    slli x8, x8, 1
    bne x6, x8, fail

    # x7 = max*2 -1
    slli x8, x9, 1
    li x9, 1
    sub x8, x8, x9
    bne x7, x8, fail



TEST_PASSFAIL

RVTEST_CODE_END

  .data
RVTEST_DATA_BEGIN

  TEST_DATA

RVTEST_DATA_END
