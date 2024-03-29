# distributed under the mit license
# https://opensource.org/licenses/mit-license.php

# distributed under the mit license
# https://opensource.org/licenses/mit-license.php

#include "riscv_test.h"
#include "test_macros.h"

# Test 1: Interrupts

# Try to handle interrupts like did in WBA testsuite but now with U-mode activated
# Loop over a regular loop to wait for interrupts and also uses WFI.
# Activation of the interrupts is done by a fake sys call, placed in a7 before
# an ecall.
#
# x31 is the error status register to trigger the testbench status
# when encounter a problem during the testcase

# Machine interrupt enable (MSTATUS)
.equ MPIE_ON,   0x00000080
.equ MPIE_OFF,  0xFFFFFF7F
# Machine external interrupt enable (MIE)
.equ MEIE_ON,   0x00000800
.equ MEIE_OFF,  0xFFFFF7FF

.equ SVC_DIS_EIRQ, 7
.equ SVC_DIS_INTP, 8
.equ SVC_EN_INTP, 9

RVTEST_RV64U
RVTEST_CODE_BEGIN

j TEST

EXP_SERVICE:

# Not supported for the moment
ECALL_SUPERVISOR_MODE:
    add x31, x31, 1
    ebreak

ECALL_USER_MODE:
    li t4, SVC_DIS_EIRQ
    beq t4, a7, DISABLE_EIRQ
    li t4, SVC_DIS_INTP
    beq t4, a7, DISABLE_INTP
    li t4, SVC_EN_INTP
    beq a7, t4, ENABLE_INTP
    j RET_ECALL

ENABLE_INTP:
    # Enable IRQ
    lui t5, %hi(MPIE_ON)
    addi t5, t5, %lo(MPIE_ON)
    csrr t4, mstatus
    or t4, t4, t5
    csrw mstatus, t4
    # Enable EIRQ
    lui t5, %hi(MEIE_ON)
    addi t5, t5, %lo(MEIE_ON)
    csrr t4, mie
    or t4, t4, t5
    csrw mie, t4
    j RET_ECALL

DISABLE_INTP:
    lui t5, %hi(MPIE_OFF)
    addi t5, t5, %lo(MPIE_OFF)
    csrr t4, mstatus
    and t4, t4, t5
    csrw mstatus, t4
    j RET_ECALL

DISABLE_EIRQ:
    lui t5, %hi(MEIE_OFF)
    addi t5, t5, %lo(MEIE_OFF)
    csrr t4, mie
    and t4, t4, t5
    csrw mie, t4
    j RET_ECALL

RET_ECALL:
    # Increment PC value to return next instruction
    csrr t4, mepc
    add t4, t4, 4
    csrw mepc, t4
    mret

ECALL_MACHINE_MODE:
    ebreak

ILLEGAL_INSTRUCTION:
    add x20, x20, 1
    # Increment PC value to return next instruction
    csrr t4, mepc
    add t4, t4, 4
    csrw mepc, t4
    mret

INTP:
    # To check we passed thru the trap
    add x20, x20, 1
    mret

TEST:
    # Enable interrupts thru a syscall
    li a7, SVC_EN_INTP
    ecall

// Loop to wait for a interrupt
TEST1:
    li t0, 0
    li t1, 0
    li t2, 100
LOOP_OVER:
    addi t0, t0, 1
    sw t0, 0(x0)
    lw t1, 0(x0)
    bne t0, t2, LOOP_OVER
    bne t0, t1, fail

// Use WFI to wait for the interrupt with EIRQ enable
TEST2:
    li x20, 0
    li t1, 1
    wfi
    bne x20, t1, fail

// Use WFI to wait for the interrupt with EIRQ disabled
TEST3:
    li a7, SVC_DIS_INTP
    ecall
    wfi

// Use WFI without interrupt enabled, must be a NOP
TEST4:
    li a7, SVC_DIS_EIRQ
    ecall
    nop
    wfi
    nop
    wfi
    nop

j pass

TEST_PASSFAIL

RVTEST_CODE_END

  .data
RVTEST_DATA_BEGIN

  TEST_DATA

RVTEST_DATA_END
