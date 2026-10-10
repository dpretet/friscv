# Distributed under the MIT license.
# https://opensource.org/licenses/mit-license.php

# RV32U wrapper for Test 1: interrupts while executing in U-mode.
# The implementation is shared with the RV64U test; redefining RVTEST_RV64U
# selects the RV32U test environment before the implementation is included.

#include "riscv_test.h"
#include "test_macros.h"
#undef RVTEST_RV64U
#define RVTEST_RV64U RVTEST_RV32U

#include "../rv64ui/test1.S"
