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
.equ MIE_ON,    0x00000088
.equ MIE_OFF,   0xFFFFFFF7
# Machine external interrupt enable (MIE)
.equ MEIE_ON,   0x00000800
.equ MEIE_OFF,  0xFFFFF7FF

.equ PMPCFG0,  0x0
.equ PMPCFG1,  0x0
.equ PMPCFG2,  0x0
.equ PMPCFG3,  0x0
.equ PMPADDR,  0xFFFFFFFF
.equ PMPCFG,   0x77777777

.equ S2MB,     0x200000
.equ S1MB,     0x100000
.equ S512K,    0x80000
.equ S256K,    0x40000
.equ S64KB,    0x10000
.equ S16KB,    0x10000
.equ S4KB,     0x4000
.equ S1KB,     0x1000




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


##################################################
#
# Testcases
#
##################################################

TEST:

# Erase first all PMP configuration
TEST1:
    li a7, 0
    ecall

// Try to write the PMP address/config with stupid values
// to check the registers are fully implemented
TEST2:
    li a7, 1
    ecall

// TOR region - 1MB RWX
TEST3_1TOR:
    // Configure the region
    li a0, 0       // pmp number
    li a1, S1MB    // base address
    li a2, 0       // size
    li a3, TOR_RWX // permissions
    li a4, TOR     // type
    li a7, 8
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

// NAPOT region - 1MB RWX
TEST4_1NAPOT:
    // Configure the region
    li a0, 0         // pmp number
    li a1, 0         // base address
    li a2, S1MB      // size
    li a3, NAPOT_RWX // permissions
    li a4, NAPOT     // type
    li a7, 8
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

// NA4 region - 2MB RWX
TEST5_NA4:
    // Configure a NAPOT 512 KB for code
    li a0, 0         // pmp number
    li a1, 0         // base address
    li a2, S256K     // size
    li a3, NAPOT_RWX // permissions
    li a4, NAPOT     // type
    li a7, 8
    ecall
    // Configure a NA4
    li a0, 1         // pmp number
    li a1, S512K     // base address
    li a2, 4         // size
    li a3, NA4_RWX   // permissions
    li a4, NA4       // type
    li a7, 8
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
