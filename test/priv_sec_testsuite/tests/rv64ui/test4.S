######################################################################
# distributed under the mit license
# https://opensource.org/licenses/mit-license.php
######################################################################

#include "riscv_test.h"
#include "test_macros.h"
#include "pmp_service.S"
#include "pmp.S"

######################################################################
# Test 3: PMP permissions

# Configure PMP and check permissions are correctly followed by the
# mpu and control/memfy units with U-mode
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

# Trap for malformed / unsupported instruction
ILLEGAL_INSTRUCTION:
    add x31, x31, 1
    ebreak


EXP_SERVICE:
    // increment error
    addi s2, s2, 1
    csrr s0, mcause
    li t0, CAUSE_MISALIGNED_LOAD
    beq s0, t0, EXP_MRET
    li t0, CAUSE_MISALIGNED_STORE
    beq s0, t0, EXP_MRET
    li t0, CAUSE_MISALIGNED_FETCH
    beq s0, t0, EXP_INST_FAULT

EXP_MRET:
    mret

EXP_INST_FAULT:
    // move back to test4
    li t0, 3
    bne t0, s2, fail
EXP_BACK3:
    // replace mepc with TEST4_CHECK because
    // it contains the access fault address
    la t0, TEST3_CHECK
    csrw mepc, t0
    j EXP_MRET



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


// Check store access misaligned 
TEST1_SETUP:

TEST1:
    // raise an exception, which will increment s0
    li t0, 1
    sw x0, 0(t0)
    nop
    nop
    nop
    nop
    nop

    // Check the exception has been handled correctly
    li t0, CAUSE_MISALIGNED_STORE
    bne s0, t0, fail

TEST1_TEARDOWN:

// Check load access misaligned 
TEST2_SETUP:

TEST2:
    // raise an exception, which will increment s0
    li t0, 3
    lw x0, 0(t0)

    // Check the exception has been handled correctly
    li t0, CAUSE_MISALIGNED_LOAD
    bne s0, t0, fail

TEST2_TEARDOWN:

// Check execute access misaligned in u-mode
TEST3_SETUP:

TEST3:
    // raise an exception, which will increment s0
    li t0, 2
    jalr x0, 0(t0)
TEST3_CHECK:
    li t0, CAUSE_MISALIGNED_FETCH
    bne s0, t0, fail
    li t0, 3
    bne s2, t0, fail

TEST3_TEARDOWN:
    j pass

TEST_PASSFAIL

RVTEST_CODE_END

.data

RVTEST_DATA_BEGIN

TEST_DATA

RVTEST_DATA_END
