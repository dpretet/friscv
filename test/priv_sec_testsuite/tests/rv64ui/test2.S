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

.equ S1MB,     0x100000
.equ S64KB,    0x10000
.equ S16KB,    0x10000
.equ S4KB,     0x4000
.equ S1KB,     0x1000

.equ OFF,       0
.equ TOR_RWX,   0x8F
.equ TOR_RW,    0x8B
.equ TOR_RX,    0x8D
.equ NA4_RWX,   0x97
.equ NA4_RW,    0x93
.equ NA4_RX,    0x95
.equ NAPOT_RWX, 0x9F
.equ NAPOT_RW , 0x9B
.equ NAPOT_RX , 0x9D

.equ TOR,       0x08
.equ NA4,       0x10
.equ NAPOT,     0x18


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


////////////////////////////////////////////
// Erase all PMP configurations
////////////////////////////////////////////
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
    j RET_ECALL

///////////////////////////////////////////////////////////////////////
// Write all PMP registers to check it's accessible without limitations
///////////////////////////////////////////////////////////////////////
CHECK_RW_PMP:

    // pmpaddr0
    lui t4, %hi(PMPADDR)
    addi t4, t4, %lo(PMPADDR)
    csrw pmpaddr0, t4
    csrr t5, pmpaddr0
    bne t4, t5, fail
    csrw pmpaddr0, x0

    // pmpaddr1
    lui t4, %hi(PMPADDR)
    addi t4, t4, %lo(PMPADDR)
    csrw pmpaddr1, t4
    csrr t5, pmpaddr1
    bne t4, t5, fail
    csrw pmpaddr1, x0

    // pmpaddr2
    lui t4, %hi(PMPADDR)
    addi t4, t4, %lo(PMPADDR)
    csrw pmpaddr2, t4
    csrr t5, pmpaddr2
    bne t4, t5, fail
    csrw pmpaddr2, x0

    // pmpaddr3
    lui t4, %hi(PMPADDR)
    addi t4, t4, %lo(PMPADDR)
    csrw pmpaddr3, t4
    csrr t5, pmpaddr3
    bne t4, t5, fail
    csrw pmpaddr3, x0

    // pmpaddr4
    lui t4, %hi(PMPADDR)
    addi t4, t4, %lo(PMPADDR)
    csrw pmpaddr4, t4
    csrr t5, pmpaddr4
    bne t4, t5, fail
    csrw pmpaddr4, x0

    // pmpaddr5
    lui t4, %hi(PMPADDR)
    addi t4, t4, %lo(PMPADDR)
    csrw pmpaddr5, t4
    csrr t5, pmpaddr5
    bne t4, t5, fail
    csrw pmpaddr5, x0

    // pmpaddr6
    lui t4, %hi(PMPADDR)
    addi t4, t4, %lo(PMPADDR)
    csrw pmpaddr6, t4
    csrr t5, pmpaddr6
    bne t4, t5, fail
    csrw pmpaddr6, x0

    // pmpaddr7
    lui t4, %hi(PMPADDR)
    addi t4, t4, %lo(PMPADDR)
    csrw pmpaddr7, t4
    csrr t5, pmpaddr7
    bne t4, t5, fail
    csrw pmpaddr7, x0

    // pmpaddr8
    lui t4, %hi(PMPADDR)
    addi t4, t4, %lo(PMPADDR)
    csrw pmpaddr8, t4
    csrr t5, pmpaddr8
    bne t4, t5, fail
    csrw pmpaddr8, x0

    // pmpaddr9
    lui t4, %hi(PMPADDR)
    addi t4, t4, %lo(PMPADDR)
    csrw pmpaddr9, t4
    csrr t5, pmpaddr9
    bne t4, t5, fail
    csrw pmpaddr9, x0

    // pmpaddr10
    lui t4, %hi(PMPADDR)
    addi t4, t4, %lo(PMPADDR)
    csrw pmpaddr10, t4
    csrr t5, pmpaddr10
    bne t4, t5, fail
    csrw pmpaddr10, x0

    // pmpaddr1
    lui t4, %hi(PMPADDR)
    addi t4, t4, %lo(PMPADDR)
    csrw pmpaddr11, t4
    csrr t5, pmpaddr11
    bne t4, t5, fail
    csrw pmpaddr11, x0

    // pmpaddr12
    lui t4, %hi(PMPADDR)
    addi t4, t4, %lo(PMPADDR)
    csrw pmpaddr12, t4
    csrr t5, pmpaddr12
    bne t4, t5, fail
    csrw pmpaddr12, x0

    // pmpaddr13
    lui t4, %hi(PMPADDR)
    addi t4, t4, %lo(PMPADDR)
    csrw pmpaddr13, t4
    csrr t5, pmpaddr13
    bne t4, t5, fail
    csrw pmpaddr13, x0

    // pmpaddr14
    lui t4, %hi(PMPADDR)
    addi t4, t4, %lo(PMPADDR)
    csrw pmpaddr14, t4
    csrr t5, pmpaddr14
    bne t4, t5, fail
    csrw pmpaddr14, x0

    // pmpaddr15
    lui t4, %hi(PMPADDR)
    addi t4, t4, %lo(PMPADDR)
    csrw pmpaddr15, t4
    csrr t5, pmpaddr15
    bne t4, t5, fail
    csrw pmpaddr15, x0

    // pmpcfg0
    lui t4, %hi(PMPCFG)
    addi t4, t4, %lo(PMPCFG)
    csrw pmpcfg0, t4
    csrr t5, pmpcfg0
    bne t4, t5, fail
    csrw pmpcfg0, x0

    // pmpcfg1
    lui t4, %hi(PMPCFG)
    addi t4, t4, %lo(PMPCFG)
    csrw pmpcfg1, t4
    csrr t5, pmpcfg1
    bne t4, t5, fail
    csrw pmpcfg1, x0

    // pmpcfg2
    lui t4, %hi(PMPCFG)
    addi t4, t4, %lo(PMPCFG)
    csrw pmpcfg2, t4
    csrr t5, pmpcfg2
    bne t4, t5, fail
    csrw pmpcfg2, x0

    // pmpaddr3
    lui t4, %hi(PMPCFG)
    addi t4, t4, %lo(PMPCFG)
    csrw pmpcfg3, t4
    csrr t5, pmpcfg3
    bne t4, t5, fail
    csrw pmpcfg3, x0
    j RET_ECALL

////////////////////////////////////////////
# Enable asynchronous traps
////////////////////////////////////////////
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

EXP_SERVICE:
    addi s0, s0, 1
    # j RET_ECALL
    mret

////////////////////////////////////////////
# Configure a NAPOT / NA4 region
////////////////////////////////////////////
SET_NA4:
    j RET_ECALL
SET_NAPOT:
    # napot_size = ((size/2)-1)
    srli a2, a2, 1
    addi a2, a2, -1
    # pmp_addr = (base + napot_size)>>2
    add a1, a1, a2
    srli a1, a1, 2
    j SET_PMP


////////////////////////////////////////////
# Configure a TOR region
////////////////////////////////////////////
SET_PMP:
SET_TOR:
    li t0, 4
    blt a0, t0, CFGREG0
    li t0, 8
    blt a0, t0, CFGREG1
    li t0, 12
    blt a0, t0, CFGREG2
    li t0, 16
    blt a0, t0, CFGREG3
    // region number not supported (>16)
    li a0, 1
    j RET_ECALL

CFGREG0:
    // prepare address, must be store by removing 2 LSBs
    srli a1, a1, 2
    // load configuration to update
    csrr t1, pmpcfg0
    // check pmp region to configure
    li t0, 0
    beq t0, a0, 0f
    li t0, 1
    beq t0, a0, 1f
    li t0, 2
    beq t0, a0, 2f
    li t0, 3
    beq t0, a0, 3f
0:
    csrw pmpaddr0, a1
    li t0, 0xFFFFFF00
    and t1, t1, t0
    j 4f
1:
    csrw pmpaddr1, a1
    li t0, 0xFFFF00FF
    and t1, t1, t0
    slli a3, a3, 8
    j 4f
2:
    csrw pmpaddr2, a1
    li t0, 0xFF00FFFF
    and t1, t1, t0
    slli a3, a3, 16
    j 4f
3:
    csrw pmpaddr3, a1
    li t0, 0x00FFFFFF
    and t1, t1, t0
    slli a3, a3, 24
    j 4f
4:
    // Store config and start MPU
    or t1, t1, a3
    csrw pmpcfg0, t1
    j RET_ECALL

CFGREG1:
    srli a1, a1, 2
    csrr t1, pmpcfg1
    li t0, 0
    beq t0, a0, 0f
    li t0, 1
    beq t0, a0, 1f
    li t0, 2
    beq t0, a0, 2f
    li t0, 3
    beq t0, a0, 3f
0:
    csrw pmpaddr4, a1
    li t0, 0xFFFFFF00
    and t1, t1, t0
    j 4f
1:
    csrw pmpaddr5, a1
    li t0, 0xFFFF00FF
    and t1, t1, t0
    slli a3, a3, 8
    j 4f
2:
    csrw pmpaddr6, a1
    li t0, 0xFF00FFFF
    and t1, t1, t0
    slli a3, a3, 16
    j 4f
3:
    csrw pmpaddr7, a1
    li t0, 0x00FFFFFF
    and t1, t1, t0
    slli a3, a3, 24
    j 4f
4:
    or t1, t1, a3
    csrw pmpcfg0, t1
    j RET_ECALL

CFGREG2:
    srli a1, a1, 2
    csrr t1, pmpcfg1
    li t0, 0
    beq t0, a0, 0f
    li t0, 1
    beq t0, a0, 1f
    li t0, 2
    beq t0, a0, 2f
    li t0, 3
    beq t0, a0, 3f
0:
    csrw pmpaddr8, a1
    li t0, 0xFFFFFF00
    and t1, t1, t0
    j 4f
1:
    csrw pmpaddr9, a1
    li t0, 0xFFFF00FF
    and t1, t1, t0
    slli a3, a3, 8
    j 4f
2:
    li t0, 0xFF00FFFF
    and t1, t1, t0
    slli a3, a3, 16
    j 4f
3:
    csrw pmpaddr10, a1
    li t0, 0x00FFFFFF
    and t1, t1, t0
    slli a3, a3, 24
    j 4f
4:
    csrw pmpaddr11, a1
    or t1, t1, a3
    csrw pmpcfg0, t1
    j RET_ECALL


CFGREG3:
    srli a1, a1, 2
    csrr t1, pmpcfg3
    li t0, 0
    beq t0, a0, 0f
    li t0, 1
    beq t0, a0, 1f
    li t0, 2
    beq t0, a0, 2f
    li t0, 3
    beq t0, a0, 3f
0:
    csrw pmpaddr12, a1
    li t0, 0xFFFFFF00
    and t1, t1, t0
    j 4f
1:
    csrw pmpaddr13, a1
    li t0, 0xFFFF00FF
    and t1, t1, t0
    slli a3, a3, 8
    j 4f
2:
    csrw pmpaddr14, a1
    li t0, 0xFF00FFFF
    and t1, t1, t0
    slli a3, a3, 16
    j 4f
3:
    csrw pmpaddr15, a1
    li t0, 0x00FFFFFF
    and t1, t1, t0
    slli a3, a3, 24
    j 4f
4:
    or t1, t1, a3
    csrw pmpcfg3, t1
    j RET_ECALL

//////////////////////////////////////////////////
// Set a PMP region and its attributes
//
// @a0: the region number
// @a1: the region base address
// @a2: the region size (NAPOT) only
// @a3: the region type (NAPOT/NA4/TOR/OFF) + R/W/X
// @returns 1 if wrong region type, otherwise 0
//////////////////////////////////////////////////
PMP_SERVICE:
    li t0, OFF
    beq a4, t0, RET_ECALL
    li t0, TOR
    beq a4, t0, SET_TOR
    li t0, NA4
    beq a4, t0, SET_NA4
    li t0, NAPOT
    beq a4, t0, SET_NAPOT
    // region type unsupported, returns an error
    li a0, 1
    j RET_ECALL


/////////////////////////////////////////////////////
# Entry point for user-mode system call
# Redirect to the right service
#
# a7 is the syscall number
#   - 0: erase PMP registers
#   - 1: setup pmp addr with 0xFFFFFFFF
#   - 8: PMP_SERVICE syscall
#   - 9: Interrupt setup syscall
# a0-a6 are the arguments for PMP_SERVICE syscall
/////////////////////////////////////////////////////
ECALL_USER_MODE:
    # Init PMP registers
    li t4, 0
    beq a7, t4, ERASE_PMP
    # Setup PMPADDRs/CFGs with 0xFFFFFFFF/0x77777777
    li t4, 1
    beq a7, t4, CHECK_RW_PMP
    # PMP service
    li t4, 8
    beq a7, t4, PMP_SERVICE
    # Interrupt service
    li t4, 9
    beq a7, t4, INTP_SERVICE
    j RET_ECALL

////////////////////////////////////////////
# Return to user-mode after ecall
////////////////////////////////////////////
RET_ECALL:
    csrr t4, mepc
    add t4, t4, 4
    csrw mepc, t4
    mret

////////////////////////////////////////////
# Simple trap to count async interrupts
# To check we passed thru the async trap
////////////////////////////////////////////
INTP:
    add x20, x20, 1
    mret


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
    li a7, 0
    ecall
    li s0, 0

// NAPOT region - 1MB RWX
TEST4_1NAPOT:
    // Configure the region
    li a0, 0         // pmp number
    li a1, 0         // base address
    li a2, S1MB      // size
    li a3, NAPOT_RWX // permissions
    li a3, NAPOT     // type
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
    # lui t0, %hi(S1MB)
    # addi t0, t0, %lo(S1MB)
    sw x0, 0(t0) // raise an exception, which will increment s0
    # bunch of nop to wait for exception handling
    nop
    nop
    nop
    // Check the exception has been handled correctly
    li t0, 1
    bne s0, t0, fail
    li s0, 0

TEST4_TEARDOWN:
    li a7, 0
    ecall
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
