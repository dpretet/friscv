# Distributed under the MIT license
# https://opensource.org/licenses/mit-license.php

# Test 1: Interrupts while executing the test in U-mode.
#
# The test uses a minimal M-mode trap handler to emulate three services.
# The service number is passed in a7 before ecall:
#   7: disable machine external interrupt enable (mie.MEIE)
#   8: clear mstatus.MPIE
#   9: set mstatus.MPIE and enable mie.MEIE
#
# Note: MPIE is not the global interrupt-enable bit itself. On mret,
# mstatus.MIE is restored from mstatus.MPIE. Thus, services 8 and 9
# control the MIE value after returning from the trap.
#
# x31 is the error-status register used by the testbench.

#include "riscv_test.h"
#include "test_macros.h"

# mstatus.MPIE: Previous value of mstatus.MIE
.equ MPIE_ON,   0x00000080
.equ MPIE_OFF,  0xFFFFFF7F

# mie.MEIE: Machine external interrupt enable
.equ MEIE_ON,   0x00000800
.equ MEIE_OFF,  0xFFFFF7FF

.equ SVC_DIS_EIRQ, 7
.equ SVC_DIS_INTP, 8
.equ SVC_EN_INTP,  9

RVTEST_RV64U
RVTEST_CODE_BEGIN

    j TEST

# Trap entry point used by the test environment.
EXP_SERVICE:

# Supervisor-mode traps are not supported by this test.
ECALL_SUPERVISOR_MODE:
    add x31, x31, 1
    ebreak

# Handle the fake services issued by U-mode ecall.
ECALL_USER_MODE:
    li t4, SVC_DIS_EIRQ
    beq t4, a7, DISABLE_EIRQ

    li t4, SVC_DIS_INTP
    beq t4, a7, DISABLE_INTP

    li t4, SVC_EN_INTP
    beq a7, t4, ENABLE_INTP

    j RET_ECALL

ENABLE_INTP:
    # Set mstatus.MPIE. mret will copy MPIE into MIE.
    lui t5, %hi(MPIE_ON)
    addi t5, t5, %lo(MPIE_ON)
    csrr t4, mstatus
    or t4, t4, t5
    csrw mstatus, t4

    # Enable machine external interrupts individually.
    lui t5, %hi(MEIE_ON)
    addi t5, t5, %lo(MEIE_ON)
    csrr t4, mie
    or t4, t4, t5
    csrw mie, t4
    j RET_ECALL

DISABLE_INTP:
    # Clear mstatus.MPIE. On mret, MIE becomes zero.
    # This does not clear mie.MEIE.
    lui t5, %hi(MPIE_OFF)
    addi t5, t5, %lo(MPIE_OFF)
    csrr t4, mstatus
    and t4, t4, t5
    csrw mstatus, t4
    j RET_ECALL

DISABLE_EIRQ:
    # Clear the individual machine external interrupt enable.
    # This is separate from the global MIE bit in mstatus.
    lui t5, %hi(MEIE_OFF)
    addi t5, t5, %lo(MEIE_OFF)
    csrr t4, mie
    and t4, t4, t5
    csrw mie, t4
    j RET_ECALL

RET_ECALL:
    # Skip the ecall instruction so execution resumes at the next one.
    csrr t4, mepc
    add t4, t4, 4
    csrw mepc, t4
    mret

ECALL_MACHINE_MODE:
    ebreak

ILLEGAL_INSTRUCTION:
    # Record that the illegal-instruction trap handler was reached.
    add s4, s4, 1

    # Skip the faulting instruction and return.
    csrr t4, mepc
    add t4, t4, 4
    csrw mepc, t4
    mret

INTP:
    # Record that the interrupt handler was reached.
    add s4, s4, 1
    mret

TEST:
    # Ask the trap handler to enable MEIE and set MPIE.
    # After mret, MIE is restored from MPIE.
    li a7, SVC_EN_INTP
    ecall

# TEST1: Exercise a regular loop while the testbench may provide interrupts.
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

# TEST2: Wait for an interrupt with MEIE enabled.
TEST2:
    li s4, 0
    wfi
    beq s4, x0, fail

# TEST3: Clear MPIE, then wait with MEIE still enabled.
# On mret from the service ecall, MIE becomes zero. Since execution is
# in U-mode, that MIE value does not by itself mask an M-mode interrupt.
# A locally enabled pending interrupt can wake WFI; the testbench must
# provide the interrupt if this test is expected to complete.
TEST3:
    li a7, SVC_DIS_INTP
    ecall
    wfi

# TEST4: Disable MEIE, then execute WFI.
# WFI may be treated as a NOP by an implementation; this test assumes
# the test environment permits execution to continue.
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
