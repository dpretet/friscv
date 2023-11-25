######################################################################
# distributed under the mit license
# https://opensource.org/licenses/mit-license.php
######################################################################

#include "riscv_test.h"
#include "test_macros.h"
#include "pmp_service.S"
#include "pmp.S"

######################################################################
# Test 4: machine mode access fault
#
# Checks machine mode experience access fault on MPRV or locked region
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

# Trap for malformed / unsupported instruction
ILLEGAL_INSTRUCTION:
    add x31, x31, 1
    ebreak


EXP_SERVICE:
    csrr s0, mcause
    li t0, CAUSE_LOAD_ACCESS
    beq s0, t0, EXP_LOAD_ACCESS
    li t0, CAUSE_STORE_ACCESS
    beq s0, t0, EXP_STORE_ACCESS
    li t0, CAUSE_FETCH_ACCESS
    beq s0, t0, EXP_INST_FAULT

EXP_LOAD_ACCESS:
    // increment error
    addi s2, s2, 1
    li a0, CAUSE_LOAD_ACCESS
    la t0, TEST1_CHECK
    csrw mepc, t0
    j EXP_MRET

EXP_STORE_ACCESS:
    // increment error
    addi s2, s2, 1
    li a0, CAUSE_STORE_ACCESS
    la t0, TEST2_CHECK
    csrw mepc, t0
    j EXP_MRET

EXP_INST_FAULT:
    // increment error
    addi s2, s2, 1
    li a0, CAUSE_FETCH_ACCESS
    la t0, TEST3_CHECK
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


// Check machine mode experience an read access fault
TEST1_SETUP:
    // First set the MPRV bit in MSTATUS
    li a0, 1
    li a7, SVC_MPRV
    ecall
    // enable a write only region
    li a0, 1         // pmp number
    li a1, S256K     // base address
    li a2, S256K     // size
    li a3, NAPOT_W   // permissions
    li a4, NAPOT     // type
    li a7, SVC_SETUP
    ecall

// Request a read access
TEST1:
    li a0, S256K
    li a7, SVC_READ
    ecall

TEST1_CHECK:
    // Check the exception has been handled correctly
    li t0, CAUSE_LOAD_ACCESS
    bne s0, a0, fail
    li t0, 1
    bne s2, t0, fail

TEST1_TEARDOWN:
    nop

// Check machine mode experience an store access fault
TEST2_SETUP:
    // enable a read only region
    li a0, 1         // pmp number
    li a1, S256K     // base address
    li a2, S256K     // size
    li a3, NAPOT_R   // permissions
    li a4, NAPOT     // type
    li a7, SVC_SETUP
    ecall

TEST2:
    li a0, S256K
    li a7, SVC_WRITE
    ecall

TEST2_CHECK:
    // Check the exception has been handled correctly
    li t0, CAUSE_STORE_ACCESS
    bne s0, a0, fail
    li t0, 2
    bne s2, t0, fail

TEST2_TEARDOWN:
    nop

// Check execute access misaligned in u-mode
TEST3_SETUP:
    // enable a read only region
    li a0, 1         // pmp number
    li a1, S256K     // base address
    li a2, S256K     // size
    li a3, NAPOT_LRW // permissions
    li a4, NAPOT     // type
    li a7, SVC_SETUP
    ecall

TEST3:
    // Store a NOP instruction
    li t0, NOP_INST
    li t1, S256K
    sw t0, 0(t1)
    // Go jump in locked/read/write only region
    li a0, S256K
    li a7, SVC_EXE
    ecall

TEST3_CHECK:
    // Check the exception has been handled correctly
    li t0, CAUSE_FETCH_ACCESS
    bne s0, a0, fail
    li t0, 3
    bne s2, t0, fail

TEST3_TEARDOWN:
    nop

TEST4_SETUP:
    // enable a read only region
    li a0, 1         // pmp number
    li a1, S256K     // base address
    li a2, 32        // size
    li a3, NAPOT_RWX // permissions
    li a4, NAPOT     // type
    li a7, SVC_SETUP
    ecall
TEST4:
    li a0, NAPOT_RWX
    li a7, SVC_CHECK_REGION
    ecall
TEST4_CHECK:
    li t0, 1
    bne a0, t0, fail
TEST4_TEARDOWN:
    j pass

TEST_PASSFAIL

RVTEST_CODE_END

.data

RVTEST_DATA_BEGIN

TEST_DATA

RVTEST_DATA_END
