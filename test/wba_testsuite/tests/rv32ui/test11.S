# distributed under the mit license
# https://opensource.org/licenses/mit-license.php

#include "riscv_test.h"
#include "test_macros.h"

.equ AMO_ATTEMPTS, 32

/*
 * Test 11: AMOADD.W retries after exclusive failures
 *
 * RANDOM_LOCK makes the AXI RAM model sometimes return OKAY for an exclusive
 * read or write. The AMO must retry internally and eventually complete without
 * trapping or changing the architectural result.
 */

RVTEST_RV32U
RVTEST_CODE_BEGIN

    j TEST

TEST:
    li   TESTNUM, 11
    la   s0, amo_counter
    li   s1, 0                  # expected old value / completed AMOs
    li   s3, AMO_ATTEMPTS       # total attempts
    li   t1, 1

amo_loop:
    amoadd.w t0, t1, (s0)
    bne  t0, s1, fail           # each AMO returns the previous counter value
    addi s1, s1, 1
    addi s3, s3, -1
    bnez s3, amo_loop

    # All attempts must complete architecturally and update memory once.
    li   t0, AMO_ATTEMPTS
    bne  s1, t0, fail

    # Failed internal exclusive attempts must not produce extra writes.
    lw   t0, 0(s0)
    bne  t0, s1, fail

    TEST_PASSFAIL

RVTEST_CODE_END

    .data
RVTEST_DATA_BEGIN
    .align 2
amo_counter:
    .word 0
RVTEST_DATA_END
