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
    csrr s0, mcause
    li t0, CAUSE_LOAD_ACCESS
    beq s0, t0, EXP_MRET
    li t0, CAUSE_STORE_ACCESS
    beq s0, t0, EXP_MRET
    li t0, CAUSE_FETCH_ACCESS
    beq s0, t0, EXP_INST_FAULT

EXP_MRET:
    mret

EXP_INST_FAULT:
    // increment error
    addi s2, s2, 1
    // move back to test4
    li t0, 1
    beq t0, s2, EXP_BACK4
EXP_BACK4:
    // replace mepc with TEST4_CHECK because
    // it contains the access fault address
    la t0, TEST4_CHECK
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
    li a7, 8
    ecall


// Check store access fault 
TEST2_SETUP:

    # Reset error flag
    li s0, 0

    // Configure a NAPOT 256 KB for data
    li a0, 1         // pmp number
    li a1, S256K     // base address
    li a2, S256K     // size
    li a3, NAPOT_R   // permissions
    li a4, NAPOT     // type
    li a7, 8
    ecall

TEST2:
    // raise an exception, which will increment s0
    li t0, S256K
    sw x0, 0(t0)

    // Check the exception has been handled correctly
    li t0, CAUSE_STORE_ACCESS
    bne s0, t0, fail

TEST2_TEARDOWN:

// Check load access fault 
TEST3_SETUP:

    # Reset error flag
    li s0, 0

    // Configure a NAPOT 256 KB for data
    li a0, 1         // pmp number
    li a1, S256K     // base address
    li a2, S256K     // size
    li a3, NAPOT_W   // permissions
    li a4, NAPOT     // type
    li a7, 8
    ecall

TEST3:
    // raise an exception, which will increment s0
    li t0, S256K
    lw x0, 0(t0)

    // Check the exception has been handled correctly
    li t0, CAUSE_LOAD_ACCESS
    bne s0, t0, fail

TEST3_TEARDOWN:


// Check execute access fault in u-mode
TEST4_SETUP:

    # Reset error flag
    li s0, 0

    // Configure a NAPOT 256 KB for data
    li a0, 1         // pmp number
    li a1, S256K     // base address
    li a2, S256K     // size
    li a3, NAPOT_RW  // permissions
    li a4, NAPOT     // type
    li a7, 8
    ecall

TEST4:
    // raise an exception, which will increment s0
    li t0, S256K
    jalr x0, 0(t0)
TEST4_CHECK:
    li t0, CAUSE_FETCH_ACCESS
    bne s0, t0, fail
    li s0, 1
    bne s0, t0, fail

TEST4_TEARDOWN:
    j pass

//////////////////////////////////////////////////////
// Stupid loop to access the memory over a small range
//////////////////////////////////////////////////////
LD_ST_ARITH:
    li t0, 0
    li t1, 10
    li t2, 0
    li t3, 0
1:
    add t2, t2, t0
    sw t2, 0(t3)
    addi t2, t2, 1
    lw t2, 0(t3)
    addi t0, t0, 1
    slli t3, t0, 2
    bne t0, t1, 1b
    ret
//////////////////////////////////////////////////////


TEST_PASSFAIL

RVTEST_CODE_END

.data

RVTEST_DATA_BEGIN

TEST_DATA

RVTEST_DATA_END
