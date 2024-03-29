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

j pass

TEST_PASSFAIL

RVTEST_CODE_END

  .data
RVTEST_DATA_BEGIN

  TEST_DATA

RVTEST_DATA_END
