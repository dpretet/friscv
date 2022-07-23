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

TEST_PASSFAIL

RVTEST_CODE_END

  .data
RVTEST_DATA_BEGIN

  TEST_DATA

