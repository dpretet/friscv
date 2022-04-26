# distributed under the mit license
# https://opensource.org/licenses/mit-license.php

#include "riscv_test.h"
#include "test_macros.h"

# Test 5: CSRs: Throttle execution by acessing the ISA CSRs
#
# This testcase executes memory and arithmetic instructions break up by CSR
# accesses. CSR instructions require several cycles to complete, thus could lead
# to failure in control unit.

RVTEST_RV64U
RVTEST_CODE_BEGIN

j TEST

BACKnFORTH:
    jalr x0, 0(x20)

TEST:

# x1 register used along the testcase
addi x1, x1, 0x5
addi x2, x2, 0xA
addi x3, x3, 0xF

# Registers used to compare the results
addi x11, x11, 0x5
addi x12, x12, 0xA
addi x13, x13, 0x0
lui x14, 1
lui x15, 2
lui x16, 2
addi x17, x17, 3
# Register used to store origin
addi x20, x20, 0
# Register used to store nb of errors
lui x31, 0

# Swap x1 and CSR 305
csrrw x1, 0x305, x1
csrrw x1, 0x305, x1
# x1 must store x11 value
auipc x10, 0
addi x10, x10, 12
bne x11, x1, fail

TEST_PASSFAIL

RVTEST_CODE_END

  .data
RVTEST_DATA_BEGIN

  TEST_DATA

