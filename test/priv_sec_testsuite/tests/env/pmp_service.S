# distributed under the mit license
# https://opensource.org/licenses/mit-license.php

#include "pmp.S"

.equ SVC_ERASE,        0
.equ SVC_CHECK,        1
.equ SVC_SETUP,        8
.equ SVC_INTP,         9
.equ SVC_MPRV,         10
.equ SVC_READ,         11
.equ SVC_WRITE,        12
.equ SVC_EXE,          13
.equ SVC_CHECK_REGION, 14

.EQU MPRV_ON,  0x00020000
.EQU MPRV_OFF, 0xFFFDFFFF

////////////////////////////////////////////
// Erase all PMP configurations
////////////////////////////////////////////
ERASE_PMP:
    csrw pmpcfg0, zero
    csrw pmpcfg1, zero
    csrw pmpcfg2, zero
    csrw pmpcfg3, zero
    csrw pmpaddr0, zero
    csrw pmpaddr1, zero
    csrw pmpaddr2, zero
    csrw pmpaddr3, zero
    csrw pmpaddr4, zero
    csrw pmpaddr5, zero
    csrw pmpaddr6, zero
    csrw pmpaddr7, zero
    csrw pmpaddr8, zero
    csrw pmpaddr9, zero
    csrw pmpaddr10, zero
    csrw pmpaddr11, zero
    csrw pmpaddr12, zero
    csrw pmpaddr13, zero
    csrw pmpaddr14, zero
    csrw pmpaddr15, zero
    j RET_ECALL

///////////////////////////////////////////////////////////////////////
// Write all PMP registers to check it's accessible without limitations
///////////////////////////////////////////////////////////////////////
CHECK_RW_PMP:

    li t0, 0
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
    lui t5, %hi(MPIE_ON)
    addi t5, t5, %lo(MPIE_ON)
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

////////////////////////////////////////////
// Check a configured region matches a 
// a configuration
// TODO: support another region than 1
////////////////////////////////////////////
CHECK_PMP_REGION:
    csrr t0, pmpcfg0
    li t1, 0xFF 
    srli t0, t0, 8
    and t0, t0, t1
    bne t0, a3, 1f
    li a0, 0
    j RET_ECALL
1:
    li a0, 1
    j RET_ECALL

////////////////////////////////////////////
# Setup MPRV bit
////////////////////////////////////////////
MPRV_SERVICE:
    csrr t0, mstatus
    bne a0, zero,2f
1:
    li t1, MPRV_OFF
    and t0, t0, t1
    j 3f
2: 
    li t1, MPRV_ON
    or t0, t0, t1
3:
    csrw mstatus, t0
    j RET_ECALL

MACHINE_READ_SERVICE:
    lw x0, 0(a0)
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop

MACHINE_WRITE_SERVICE:
    sw x0, 0(a0)
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop

MACHINE_EXE_SERVICE:
    jalr zero, 0(a0)
    nop
    nop
    nop
    nop

////////////////////////////////////////////
# Configure a NAPOT / NA4 region
////////////////////////////////////////////
SET_NA4:
SET_NAPOT:
    # napot_size
    addi a2, a2, -1
    srli a2, a2, 3
    # pmp_addr
    srli a1, a1, 2
    or a1, a1, a2
    j SET_PMP


////////////////////////////////////////////
# Configure a TOR region
////////////////////////////////////////////
SET_TOR:
    // prepare address, must be store by removing 2 LSBs
    srli a1, a1, 2
SET_PMP:
    // select the right pmpcfg place
    li t0, 4
    blt a0, t0, CFGREG0
    li t0, 8
    blt a0, t0, CFGREG1
    li t0, 12
    blt a0, t0, CFGREG2
    li t0, 16
    blt a0, t0, CFGREG3
    // region number not supported (>16)
    j RET_ECALL

CFGREG0:
    // load configuration to update
    csrr t1, pmpcfg0
    // select pmp region to configure
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
    // load configuration to update
    csrr t1, pmpcfg1
    // select pmp region to configure
    li t0, 4
    beq t0, a0, 0f
    li t0, 5
    beq t0, a0, 1f
    li t0, 6
    beq t0, a0, 2f
    li t0, 7
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
    csrw pmpcfg1, t1
    j RET_ECALL

CFGREG2:
    // load configuration to update
    csrr t1, pmpcfg2
    // select pmp region to configure
    li t0, 8
    beq t0, a0, 0f
    li t0, 9
    beq t0, a0, 1f
    li t0, 10
    beq t0, a0, 2f
    li t0, 11
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
    csrw pmpaddr10, a1
    li t0, 0xFF00FFFF
    and t1, t1, t0
    slli a3, a3, 16
    j 4f
3:
    csrw pmpaddr11, a1
    li t0, 0x00FFFFFF
    and t1, t1, t0
    slli a3, a3, 24
    j 4f
4:
    or t1, t1, a3
    csrw pmpcfg2, t1
    j RET_ECALL


CFGREG3:
    // load configuration to update
    csrr t1, pmpcfg3
    // select pmp region to configure
    li t0, 12
    beq t0, a0, 0f
    li t0, 13
    beq t0, a0, 1f
    li t0, 14
    beq t0, a0, 2f
    li t0, 15
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
// @a0: region number
// @a1: region base address
// @a2: region size (NAPOT/
// NA4 only)
// @a3: region permission
// @a4: region type (NAPOT/NA4/TOR/OFF) + R/W/X
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
    li t4, SVC_ERASE
    beq a7, t4, ERASE_PMP
    # Setup PMPADDRs/CFGs with 0xFFFFFFFF/0x77777777
    li t4, SVC_CHECK
    beq a7, t4, CHECK_RW_PMP
    # PMP service
    li t4, SVC_SETUP
    beq a7, t4, PMP_SERVICE
    # Interrupt service
    li t4, SVC_INTP
    beq a7, t4, INTP_SERVICE
    # MPRV service
    li t4, SVC_MPRV
    beq a7, t4, MPRV_SERVICE
    # Machine read service
    li t4, SVC_READ
    beq a7, t4, MACHINE_READ_SERVICE
    # Machine write service
    li t4, SVC_WRITE
    beq a7, t4, MACHINE_WRITE_SERVICE
    # Machine execute service
    li t4, SVC_EXE
    beq a7, t4, MACHINE_EXE_SERVICE
    # Check a region matches a configuration
    li t4, SVC_CHECK_REGION
    beq a7, t4, CHECK_PMP_REGION
    # Unrecognized service
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
