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
.equ MIE_ON,    0x00000088
.equ MIE_OFF,   0xFFFFFFF7
# Machine external interrupt enable (MIE)
.equ MEIE_ON,   0x00000800
.equ MEIE_OFF,  0xFFFFF7FF

RVTEST_RV64U
RVTEST_CODE_BEGIN

j TEST

# Not supported for the moment
ECALL_SUPERVISOR_MODE:
    add x31, x31, 1
    ebreak

ECALL_USER_MODE:
    # Check if ECALL is a syscall to enable interrupts 
    li t4, 9
    bne a7, t4, RET_ECALL
    # Enable IRQ
    lui t5, %hi(MIE_ON)
    addi t5, t5, %lo(MIE_ON)
    csrr t4, mstatus
    or t4, t4, t5
    csrw mstatus, t4
    # Enable EIRQ
    lui t5, %hi(MEIE_ON)
    addi t5, t5, %lo(MEIE_ON)
    csrr t4, mie
    or t4, t4, t5
    csrw mie, t4
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
    li a7, 9
    ecall

// Loop to wait for a interrupt
TEST1:
    li t0, 0
    li t1, 0
    li t2, 10
LOOP_OVER:
    addi t0, t0, 1
    sw t0, 0(x0)
    lw t1, 0(x0)
    bne t0, t2, LOOP_OVER
    bne t0, t1, fail

// Use WFI to wait for the interrupt
TEST2:
    li x20, 0
    li t1, 1
    wfi
    bne x20, t1, fail

j pass

TEST_PASSFAIL

RVTEST_CODE_END

  .data
RVTEST_DATA_BEGIN

  TEST_DATA

RVTEST_DATA_END
