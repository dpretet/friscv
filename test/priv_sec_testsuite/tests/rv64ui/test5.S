######################################################################
# distributed under the mit license
# https://opensource.org/licenses/mit-license.php
######################################################################

#include "riscv_test.h"
#include "test_macros.h"
#include "pmp_service.S"
#include "pmp.S"

######################################################################
# Test 5: mcounter access
#
# Checks user mode can access or not based in MCOUNTEREN setup
#
# x31 is the error status register to trigger the testbench status
# when encounter a problem during the testcase
######################################################################

######################################################################
# Defines / Constants
######################################################################

# Machine interrupt enable (MSTATUS)
.equ MPIE_ON,   0x00000080
.equ MPIE_OFF,  0xFFFFFFF7
# Machine external interrupt enable (MIE)
.equ MEIE_ON,   0x00000800
.equ MEIE_OFF,  0xFFFFF7FF

.equ NOP_INST,  0x00000013

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
#
# Services
#
#################################

# Trap for illegal / malformed / unsupported instruction
ILLEGAL_INSTRUCTION:
    add s0, s0, 1
    # Increment PC value to return next instruction
    csrr t4, mepc
    add t4, t4, 4
    csrw mepc, t4
    mret


EXP_SERVICE:
    csrr s0, mcause
    li t0, CAUSE_ILLEGAL_INSTRUCTION
    beq s0, t0, EXP_INST_FAULT
    j fail

EXP_INST_FAULT:
    // increment error
    addi s2, s2, 1
    li a0, CAUSE_ILLEGAL_INSTRUCTION
    la t0, TEST2_CHECK
    csrw mepc, t0
    j EXP_MRET

EXP_MRET:
    mret


##################################################
#
# Testcases
#
##################################################

TEST:

// Configure a NAPOT 256 KB for code
TEST_SETUP:
    li a0, 0         // pmp number
    li a1, 0         // base address
    li a2, S256K     // size
    li a3, NAPOT_RWX // permissions
    li a4, NAPOT     // type
    li a7, SVC_SETUP
    ecall

    # Reset error flag
    li s0, 0

// Check user mode can access the IR TM CY counters
TEST1_SETUP:
    // Enable access
    li a0, 1
    li a7, SVC_MCOUNTEREN
    ecall

// Read CY (allowed)
TEST1:
    // check data is read
    li t0, 0x55555555
    li t1, 0x55555555
    csrr t0, mcycle
    beq t0, t1, fail
    // check it didn't experience an illegal instruction
    bne s0, zero, fail

TEST1_TEARDOWN:
    nop
    j pass

// Check user mode can access the IR TM CY counters
TEST2_SETUP:
    // Enable access
    li a0, 0
    li a7, SVC_MCOUNTEREN
    ecall

// Read CY (allowed)
TEST2:
    // check data is read
    li t0, 0x55555555
    li t1, 0x55555555
    csrr t0, mcycle
TEST2_CHECK:
    bne t0, t1, fail
    // check it didn't experience an illegal instruction
    bne s0, zero, fail

TEST2_TEARDOWN:
    nop
    j pass



TEST_PASSFAIL

RVTEST_CODE_END

.data

RVTEST_DATA_BEGIN

TEST_DATA

RVTEST_DATA_END
