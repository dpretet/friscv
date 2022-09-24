# distributed under the mit license
# https://opensource.org/licenses/mit-license.php

#include "riscv_test.h"
#undef RVTEST_RV64U
#define RVTEST_RV64U RVTEST_RV32U

#include "../rv64ui/test7.S"
