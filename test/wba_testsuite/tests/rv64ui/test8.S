# distributed under the mit license
# https://opensource.org/licenses/mit-license.php

#include "riscv_test.h"
#include "test_macros.h"

# Test 8: Stress out WFI. The core enable interrupts and wait for an interrupt and wait for
# it with WFI. No smartness here, the core just jump in the trap and wait for the
# end of the EIRQ assertion (multipple WARNING are printed). If it fails, just mean the IRQ
# is not observed or the core doesn't handle it correctly, so the testcase will timeout. Else
# everything is OK.

# Machine interrupt enable (MSTATUS)
.equ MIE_ON,    0x00000008
.equ MIE_OFF,   0xFFFFFFF7
# Machine external interrupt enable (MIE)
.equ MEIE_ON,   0x00000800
.equ MEIE_OFF,  0xFFFFF7FF

RVTEST_RV64U
RVTEST_CODE_BEGIN

j TEST

INTP_SERVICE:
    add s0, s0, 1
    mret

TEST:
    // Test number
    li  x3, 0
    # Setup trap handler
    la x1, INTP_SERVICE
    csrw mtvec, x1

TEST1:
    li x3, 1
    # Enable EIRQ
    lui t1, %hi(MEIE_ON)
    addi t1, t1, %lo(MEIE_ON)
    csrr t0, mie
    or t0, t0, t1
    csrw mie, t0
    # Enable IRQ
    lui t1, %hi(MIE_ON)
    addi t1, t1, %lo(MIE_ON)
    csrr t0, mstatus
    or t0, t0, t1
    csrw mstatus, t0
    // Once enabled, the core will handle the pending
    // interrupt (already present)
    li t0, 1
    bne t0, s0, fail

# Wait an interrupt with MIE enabled
TEST2:
    li x3, 2
    wfi
    li t0, 2
    bne t0, s0, fail

# Wait an interrupt with MIE disabled
TEST3:
    li x3, 3
    # Disable IRQ
    lui t1, %hi(MIE_OFF)
    addi t1, t1, %lo(MIE_OFF)
    csrr t0, mstatus
    and t0, t0, t1
    csrw mstatus, t0
    wfi

# Wait for interrupt without any enabled, a NOP
TEST4:
    csrw mie, zero
    nop
    nop
    nop
    nop
    wfi
    nop
    nop
    nop
    nop


SUCCESS:
    bne x0, x0, fail

TEST_PASSFAIL

RVTEST_CODE_END

  .data
RVTEST_DATA_BEGIN

  TEST_DATA

RVTEST_DATA_END
