# Distributed under the MIT license.
# https://opensource.org/licenses/mit-license.php

# RV32U wrapper for Test 5: user-mode access to the machine counters through
# the MCOUNTEREN configuration.
# The implementation is shared with the RV64U test; redefining RVTEST_RV64U
# selects the RV32U test environment before the implementation is included.

#include "riscv_test.h"
#undef RVTEST_RV64U
#define RVTEST_RV64U RVTEST_RV32U

#include "../rv64ui/test5.S"
