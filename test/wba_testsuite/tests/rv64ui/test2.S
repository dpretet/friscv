#include "riscv_test.h"
#include "test_macros.h"

# Test 2: Sequence of LOAD/STORE/ARITHMETIC instructions
# 
# Injects a set of alternating LUI / AUIPC / Aritmetic instructions to ensure
# the control unit correctly handles this kind of situation.  # # While aritmetic
# instructions are completed in one cycle, LOAD and STORE can span over several
# cycles. This test will ensure incoming instructions between them will not be
# lost and so the control unit properly manages this situation.

RVTEST_RV64U
RVTEST_CODE_BEGIN

j TEST

TEST:

lui  x1, 1
lui  x2, 1
lui  x3, 1

# initialize the registers used to compare the results
lui  x11, 1
addi x11, x11, 2
lui  x12, 1
addi x12, x12, 2
lui  x13, 1
addi x13, x13, 3
lui x14, 1
addi x31, x31, 0

addi x1, x1, 1
sw x1, 0(x0)
lw x1, 0(x0)
addi x1, x1, 1
bne x11, x1, fail
 
sw x1, 0(x0)
addi x1, x1, 1 
lw x1, 0(x0)
bne x12, x1, fail

lw x1, 0(x0)
addi x1, x1, 1 
sw x1, 0(x0)
bne x13, x1, fail

lw x1, 0(x0)
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
