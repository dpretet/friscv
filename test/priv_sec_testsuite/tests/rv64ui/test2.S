######################################################################
# distributed under the mit license
# https://opensource.org/licenses/mit-license.php
######################################################################

#include "riscv_test.h"
#include "test_macros.h"
#include "pmp_service.S"
#include "pmp.S"

######################################################################
# Test 2: PMP configuration and checking

# Configure PMP and check the address matching are OK and out-of-range
# and forbidden access are correctly handled
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
    addi s0, s0, 1
    mret


##################################################
#
# Testcases
#
##################################################

TEST:

# Erase first all PMP configuration
TEST1:
    li a7, SVC_ERASE
    ecall

// Try to write the PMP address/config with stupid values
// to check the registers are fully implemented
TEST2:
    li a7, SVC_CHECK
    ecall

// TOR region - 1MB RWX
TEST3_SETUP:
    li s1, 0
    li s2, 16

TEST3_1TOR:
    // Configure the region
    add a0, s1, zero // pmp number
    li a1, S1MB      // base address
    li a2, 0         // size
    li a3, TOR_RWX   // permissions
    li a4, TOR       // type
    li a7, SVC_SETUP
    ecall

// Run some duties into the region
TEST3_RW_ACCESS:
    call LD_ST_ARITH

// Try to access the extreme boundaries of the memory region
TEST3_BOUNDS:
    li t0, S1MB
    // Check lowest bound
    sw t0, 0(zero)
    lw t1, 0(zero)
    bne t0, t1, fail
    // Check highest bound
    sw t0, -4(t0)
    lw t1, -4(t0)
    bne t0, t1, fail

TEST3_OUT_OF_BOUND:
    li t0, S1MB
    sw x0, 0(t0) // raise an exception, which will increment s0
    # bunch of nop to wait for exception handling
    nop
    nop
    nop
    // Check the exception has been handled correctly
    li t0, 1
    bne s0, t0, fail

TEST3_TEARDOWN:
    # Erase PMP configuration
    li a7, 0
    ecall
    # Reset error count
    li s0, 0
    # Continue to loop over all PMP region until reaching region 15
    addi s1, s1, 1
    bne s1, s2, TEST3_1TOR


// NAPOT region - 1MB RWX
TEST4_SETUP:
    li s1, 0
    li s2, 16

TEST4_1NAPOT:
    // Configure the region
    add a0, s1, zero // pmp number
    li a1, 0         // base address
    li a2, S1MB      // size
    li a3, NAPOT_RWX // permissions
    li a4, NAPOT     // type
    li a7, SVC_SETUP
    ecall

// Run some duties into the region
TEST4_RW_ACCESS:
    call LD_ST_ARITH

// Try to access the extreme boundaries of the memory region
TEST4_BOUNDS:
    li t0, S1MB
    // Check lowest bound
    sw t0, 0(zero)
    lw t1, 0(zero)
    bne t0, t1, fail
    // Check highest bound
    sw t0, -4(t0)
    lw t1, -4(t0)
    bne t0, t1, fail

// Try to access outside the memory region
TEST4_OUT_OF_BOUND:
    li t0, S1MB
    sw x0, 0(t0) // raise an exception, which will increment s0
    # bunch of nop to wait for exception handling
    nop
    nop
    nop
    // Check the exception has been handled correctly
    li t0, 1
    bne s0, t0, fail

TEST4_TEARDOWN:
    # Erase PMP configuration
    li a7, 0
    ecall
    # Reset error count
    li s0, 0
    # Continue to loop over all PMP region until reaching region 15
    addi s1, s1, 1
    bne s1, s2, TEST4_1NAPOT

// NA4 region - 2MB RWX
TEST5_NA4:
    // Configure a NAPOT 512 KB for code
    li a0, 0         // pmp number
    li a1, 0         // base address
    li a2, S256K     // size
    li a3, NAPOT_RWX // permissions
    li a4, NAPOT     // type
    li a7, SVC_SETUP
    ecall
    // Configure a NA4
    li a0, 1         // pmp number
    li a1, S512K     // base address
    li a2, 4         // size
    li a3, NA4_RWX   // permissions
    li a4, NA4       // type
    li a7, SVC_SETUP
    ecall
// Try to access the extreme boundaries of the memory region
TEST5_REGION:
    li t0, S512K
    sw t0, 0(t0)
    lw t1, 0(t0)
    bne t0, t1, fail
// Try to access outside the memory region
TEST5_OUT_OF_BOUND:
    li t0, S512K
    sw x0, -4(t0) // raise an exception, which will increment s0
    # bunch of nop to wait for exception handling
    nop
    nop
    nop
    // Check the exception has been handled correctly
    li t0, 1
    bne s0, t0, fail
    li t0, S512K
    sw x0, 4(t0) // raise an exception, which will increment s0
    # bunch of nop to wait for exception handling
    nop
    nop
    nop
    // Check the exception has been handled correctly
    li t0, 2
    bne s0, t0, fail

TEST5_TEARDOWN:
    # Erase PMP configuration
    li a7, 0
    ecall
    # Reset error count
    li s0, 0
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
