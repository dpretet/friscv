# distributed under the mit license
# https://opensource.org/licenses/mit-license.php

#include "riscv_test.h"
#include "test_macros.h"

# Test 5: CSRs: Throttle execution by accessing the ISA CSRs
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
addi x13, x13, 0xA
lui x14, 1
lui x15, 2
lui x16, 2
addi x17, x17, 3
# Register used to store origin
addi x20, x20, 0
# Register used to store nb of errors
addi x31, x31, 0

# Swap x1 and CSR 305
csrrw x1, 0x305, x1
csrrw x1, 0x305, x1
# x1 must store x11 value
auipc x10, 0
addi x10, x10, 12
bne x11, x1, fail

# Swap x2 and CSR 305
csrrw x2, 0x305, x2
jal x20, BACKnFORTH
csrrw x2, 0x305, x2
# x2 must store x12 value
auipc x10, 0
addi x10, x10, 12
bne x12, x2, fail
# Swap and break with JAL
jal x20, BACKnFORTH
csrrw x2, 0x305, x2
jal x20, BACKnFORTH
# x2 must contains 0 (init val of the CSRs)
auipc x10, 0
addi x10, x10, 12
csrrw x2, 0x305, x2
bne x13, x2, fail

# Surrender CSRRW with LUI
lui x3, 2
csrrw x3, 0x305, x3
lui x3, 1
# x3 must contains 0x1000
auipc x10, 0
addi x10, x10, 12
bne x14, x3, fail
# Swap again and
csrrw x3, 0x305, x3
# Now must contains its init val 0x2000
auipc x10, 0
addi x10, x10, 12
bne x15, x3, fail

# Surrender CSRRW with SW and LW
lui x4, 2
lui x1, 0
addi x1, x1, 3
csrrw x4, 0x305, x4
sw x1, 0(x0)
csrrw x4, 0x305, x4
lw x1, 0(x0)
# x4 must contains 0x1000
auipc x10, 0
addi x10, x10, 12
bne x16, x4, fail
# x1 must contains 3
auipc x10, 0
addi x10, x10, 12
bne x17, x1, fail

TEST_PASSFAIL

RVTEST_CODE_END

  .data
RVTEST_DATA_BEGIN

  TEST_DATA

