######################################################################
# distributed under the mit license
# https://opensource.org/licenses/mit-license.php
######################################################################

#include "riscv_test.h"
#include "test_macros.h"

######################################################################
# Test 2: PMP configuration and checking

# Configure PMP and check the address matching are OK and out-of-range
# and forbidden access are correctly handled
# a7 is the syscall number
#   - 7: erase PMP registers
#   - 8: PMP_SERVICE syscall
#   - 9: Interrupt setup syscall
# a0-a6 are the arguments for PMP_SERVICE syscall
# 
# x31 is the error status register to trigger the testbench status
# when encounter a problem during the testcase
######################################################################

# Machine interrupt enable (MSTATUS)
.equ MIE_ON,    0x00000088
.equ MIE_OFF,   0xFFFFFFF7
# Machine external interrupt enable (MIE)
.equ MEIE_ON,   0x00000800
.equ MEIE_OFF,  0xFFFFF7FF

.equ PMPCFG0,  0x0
.equ PMPCFG1,  0x0
.equ PMPCFG2,  0x0
.equ PMPCFG3,  0x0

RVTEST_RV64U
RVTEST_CODE_BEGIN

j TEST

#################################
# Not supported for the moment
#################################
ECALL_SUPERVISOR_MODE:
    add x31, x31, 1
    ebreak

#################################
# No service for machine-mode
#################################
ECALL_MACHINE_MODE:
    j RET_ECALL

#################################
# Services
#################################

# Trap for malformed / unsupported instruction
ILLEGAL_INSTRUCTION:
    add x31, x31, 1
    ebreak

# Get NAPOT region setup
GET_NAPOT:
    jalr x0, 0(x20)

PMP_SERVICE:
    jal x0, GET_NAPOT
    j RET_ECALL

ERASE_PMP: 
    csrw pmpcfg0, x0
    csrw pmpcfg1, x0
    csrw pmpcfg2, x0
    csrw pmpcfg3, x0
    csrw pmpaddr0, x0
    csrw pmpaddr1, x0
    csrw pmpaddr2, x0
    csrw pmpaddr3, x0
    csrw pmpaddr4, x0
    csrw pmpaddr5, x0
    csrw pmpaddr6, x0
    csrw pmpaddr7, x0
    csrw pmpaddr8, x0
    csrw pmpaddr9, x0
    csrw pmpaddr10, x0
    csrw pmpaddr11, x0
    csrw pmpaddr12, x0
    csrw pmpaddr13, x0
    csrw pmpaddr14, x0
    csrw pmpaddr15, x0

# Enalbe asynchronous traps
INTP_SERVICE:
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
    j RET_ECALL

# Entry point for user-mode system call
# Redirect to the right service
ECALL_USER_MODE:
    # Init PMP registers
    li t4, 7
    beq a7, t4, ERASE_PMP
    # PMP service
    li t4, 8
    beq a7, t4, PMP_SERVICE
    # Interrupt service
    li t4, 9
    beq a7, t4, INTP_SERVICE
    j RET_ECALL

# Return to user-mode after ecall
RET_ECALL:
    csrr t4, mepc
    add t4, t4, 4
    csrw mepc, t4
    mret

# Simple trap to count async interrupts
# To check we passed thru the async trap
INTP:
    add x20, x20, 1
    mret

##################################################
# Testcase Starting point
##################################################

TEST:
    # Erase first all PMP configuration
    li a7, 7
    ecall
    j pass

// 
TEST1:

j pass

TEST_PASSFAIL

RVTEST_CODE_END

  .data
RVTEST_DATA_BEGIN

  TEST_DATA

RVTEST_DATA_END
