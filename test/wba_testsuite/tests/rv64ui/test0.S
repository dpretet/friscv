# distributed under the mit license
# https://opensource.org/licenses/mit-license.php

# distributed under the mit license
# https://opensource.org/licenses/mit-license.php

#include "riscv_test.h"
#include "test_macros.h"

# Test 0: No instruction, just check the core boots correctly
#
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
