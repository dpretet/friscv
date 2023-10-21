# distributed under the mit license
# https://opensource.org/licenses/mit-license.php

#include "riscv_test.h"
#include "test_macros.h"

# Test 6: RW Outstanding requests
# Check the outstanding requests are properly managed by the
# memfy module by launching batch of load / store tranfers, intricated with
# ALU instructions to create hazards between the instructions

# x3/gp is the test number in the unit test flow, must be greater than 0
# 0 means the processor didn't move out the initialization correctly and is stucked


RVTEST_RV64U
RVTEST_CODE_BEGIN

j TEST

TEST:

# Bunch of store/load to ensure ordering is correct and data correct
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

# Interleave arithmetic and store, sometime having dependencies,
# sometimes not. The test is repeated multiple times to check impact
# a branch instruction which pause the processing pipeline.
# x4 will be the dependency free ALU instruction while x6 will always be
# linked to the store instruction, being its input and so will depends
# to the addi output
TEST_21:

    li x3, 21

    li x4, 0
    li x5, 0
    li x6, 0
    li x7, 100
    nop

loop_wr1:
    # loop over this sequence an hundred times
    addi x4, x4, 1
    sw x4, 0(x0)
    addi x5, x5, 1
    bne x5, x7, loop_wr1
    // load the address 0 supposed to store 100
    lw x6, 0(x0)
    bne x6, x7, fail

TEST_22:

    li x3, 22

# Second sequence
    li x4, 0
    li x5, 0
    li x6, 0
    li x7, 100
    nop

loop_wr2:
    # loop over this sequence an hundred times
    addi x4, x4, 1
    sw x4, 0(x0)
    addi x4, x4, 1
    sw x4, 0(x0)
    addi x5, x5, 1
    bne x5, x7, loop_wr2
    // load the address 0 supposed to store 100
    lw x6, 0(x0)
    li x7, 200
    bne x6, x7, fail

TEST_23:

    li x3, 23

    li x4, 0
    li x5, 0
    li x6, 0
    li x7, 100
    nop

loop_wr3:
    # loop over this sequence an hundred times
    addi x4, x4, 1
    sw x4, 0(x0)
    addi x4, x4, 1
    sw x4, 0(x0)
    addi x4, x4, 1
    sw x4, 0(x0)
    addi x5, x5, 1
    bne x5, x7, loop_wr3
    // load the address 0 supposed to store 100
    lw x6, 0(x0)
    li x7, 300
    bne x6, x7, fail

TEST_24:

    li x3, 24

    li x4, 0
    li x5, 0
    li x6, 0
    li x7, 100
    nop
loop_wr4:
    # loop over this sequence an hundred times
    addi x4, x4, 1
    sw x7, 0(x0)
    sw x7, 0(x0)
    sw x7, 0(x0)
    sw x7, 0(x0)
    sw x7, 0(x0)
    sw x7, 0(x0)
    sw x7, 0(x0)
    sw x4, 0(x0)
    addi x5, x5, 1
    bne x5, x7, loop_wr4
    // load the address 0 supposed to store 100
    lw x6, 0(x0)
    li x7, 100
    bne x6, x7, fail

# Multiple load interleaved with arithmetic or load immediate
TEST_30:

    li  x3, 30

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

TEST_31:

    li x3, 31
    li x5, 0
    li x7, 100

loop_rd1:
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

    addi x5, x5, 1
    bne x5, x7, loop_rd1


TEST_32:
    li  x3, 32
    li x5, 0

loop_rd2:

    lw x10, 0(x0)
    lw x10, 0(x0)
    lw x10, 0(x0)
    lw x10, 0(x0)
    addi x10, x10, 1
    lw x11, 4(x0)
    lw x11, 4(x0)
    lw x11, 4(x0)
    lw x11, 4(x0)
    addi x11, x11, 2

    li x1, 1
    bne x10, x1, fail
    li x1, 3
    bne x11, x1, fail

    lw x10, 0(x0)
    lw x11, 4(x0)
    lw x10, 0(x0)
    lw x11, 4(x0)
    lw x10, 0(x0)
    lw x11, 4(x0)
    lw x10, 0(x0)
    lw x11, 4(x0)
    addi x10, x10, 1
    addi x11, x11, 2

    li x1, 1
    bne x10, x1, fail
    li x1, 3
    bne x11, x1, fail

    addi x5, x5, 1
    bne x5, x7, loop_rd2


TEST_PASSFAIL

RVTEST_CODE_END

  .data
RVTEST_DATA_BEGIN

  TEST_DATA

RVTEST_DATA_END
