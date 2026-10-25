# distributed under the mit license
# https://opensource.org/licenses/mit-license.php

#include "riscv_test.h"
#include "test_macros.h"

.equ AMO_ATTEMPTS, 16
.equ AMO_OP_COUNT, 8
.equ AMO_TOTAL_ATTEMPTS, AMO_ATTEMPTS * AMO_OP_COUNT
.equ LRSC_ATTEMPTS, 16

/*
 * Test 12: the AMO operators other than AMOADD.W, plus LR.W and SC.W.
 * RANDOM_LOCK injects exclusive failures. AMOs must retry to completion;
 * LR returns its data even without a reservation, and SC reports success or
 * failure in rd without trapping.
 */

.macro RUN_AMO instruction, word, kind
    la   s0, \word
    li   s1, 0                  # completed AMOs for this operator
    li   s3, AMO_ATTEMPTS
    li   s6, 5                  # software shadow of the memory word
    li   s7, 3                  # rs2 operand

.Lamo_loop\@:
    \instruction t0, s7, (s0)
    bne  t0, s6, fail            # AMO rd must return the prior memory value

    .if \kind == 0              # AMOSWAP.W
        mv   s6, s7
    .elseif \kind == 1          # AMOXOR.W
        xor  s6, s6, s7
    .elseif \kind == 2          # AMOAND.W
        and  s6, s6, s7
    .elseif \kind == 3          # AMOOR.W
        or   s6, s6, s7
    .elseif \kind == 4          # AMOMIN.W (signed)
        bge  s7, s6, .Lamo_update_done\@
        mv   s6, s7
    .elseif \kind == 5          # AMOMAX.W (signed)
        bge  s6, s7, .Lamo_update_done\@
        mv   s6, s7
    .elseif \kind == 6          # AMOMINU.W
        bgeu s7, s6, .Lamo_update_done\@
        mv   s6, s7
    .elseif \kind == 7          # AMOMAXU.W
        bgeu s6, s7, .Lamo_update_done\@
        mv   s6, s7
    .endif
.Lamo_update_done\@:
    addi s1, s1, 1
    addi s5, s5, 1              # total successful AMOs

.Lamo_done\@:
    addi s3, s3, -1
    bnez s3, .Lamo_loop\@

    li   t0, AMO_ATTEMPTS
    bne  t0, s1, fail
    lw   t0, 0(s0)
    bne  t0, s6, fail
.endm

RVTEST_RV32U
RVTEST_CODE_BEGIN

    j TEST

TEST:
    li   TESTNUM, 12
    li   s5, 0                  # total successful AMOs
    li   s9, 0                  # successful LRs
    li   s11, 0                 # successful SCs
    li   s4, 0                  # failed SCs

    RUN_AMO amoswap.w, amo_swap_word, 0
    RUN_AMO amoxor.w, amo_xor_word, 1
    RUN_AMO amoand.w, amo_and_word, 2
    RUN_AMO amoor.w, amo_or_word, 3
    RUN_AMO amomin.w, amo_min_word, 4
    RUN_AMO amomax.w, amo_max_word, 5
    RUN_AMO amominu.w, amo_minu_word, 6
    RUN_AMO amomaxu.w, amo_maxu_word, 7

    # Every AMO must complete despite internal exclusive retries.
    li   t0, AMO_TOTAL_ATTEMPTS
    bne  t0, s5, fail

    # An SC without a preceding LR must fail and leave memory unchanged.
    la   s0, sc_fail_word
    li   t0, 0x7f
    li   t1, 9
    sc.w t0, t1, (s0)
    beqz t0, fail               # SC without LR must report nonzero
    lw   t2, 0(s0)
    bnez t2, fail

    # Pair every LR with an SC. LR data remains valid without a reservation;
    # SC reports failure in rd instead of trapping.
    la   s0, lrsc_word
    li   s3, LRSC_ATTEMPTS
    li   s6, 5                  # software shadow of lrsc_word
.Llrsc_loop:
    lr.w t0, (s0)
    bne  t0, s6, fail
    addi s9, s9, 1
    li   t0, 0x7f
    li   t1, 9
    sc.w t0, t1, (s0)
    beqz t0, .Lsc_succeeded
    addi s4, s4, 1
    lw   t2, 0(s0)
    bne  t2, s6, fail           # a failed SC must not modify memory
    j    .Lsc_counted
.Lsc_succeeded:
    addi s11, s11, 1
    li   s6, 9
.Lsc_counted:
    addi s3, s3, -1
    bnez s3, .Llrsc_loop

    li   t0, LRSC_ATTEMPTS
    bne  t0, s9, fail
    add  t1, s11, s4
    bne  t0, t1, fail
    # The standalone SC above guarantees a checked failure; randomized
    # reservation outcomes can make every paired SC succeed in one run.
    beqz s11, fail              # require successful paired SCs
    lw   t0, 0(s0)
    bne  t0, s6, fail

    TEST_PASSFAIL

RVTEST_CODE_END

    .data
RVTEST_DATA_BEGIN
    .align 2
amo_swap_word: .word 5
amo_xor_word:  .word 5
amo_and_word:  .word 5
amo_or_word:   .word 5
amo_min_word:  .word 5
amo_max_word:  .word 5
amo_minu_word: .word 5
amo_maxu_word: .word 5
lrsc_word:     .word 5
sc_fail_word:  .word 0
RVTEST_DATA_END
