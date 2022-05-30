# distributed under the mit license
# https://opensource.org/licenses/mit-license.php

.section .text
.equ REGW, 4
#------------------------------------------------------------------------------
# Export functions' symbols for C call
#------------------------------------------------------------------------------

.global _syscall
.global trap_entry


#------------------------------------------------------------------------------
# System call: can arrive here on ecall or from a trap handling
#------------------------------------------------------------------------------
.align 2
_syscall:
    # SBRK(), used to return program break on malloc()
    li t3, 214
    bne a7, t3, ret_syscall
    # Fake sbrk
    la a0, _edata

ret_syscall:
    # When coming from ecall, move to the next instruction
    csrr t0, mepc
	addi t0, t0, 4
	csrw mepc, t0
    mret


#------------------------------------------------------------------------------
# Entry point to handle a trap, either ecall(), an interrupt or an exception
#------------------------------------------------------------------------------
.align 2
trap_entry:

    addi sp, sp, -17*REGW
  
    sw ra, 0*REGW(sp)
    sw a0, 1*REGW(sp)
    sw a1, 2*REGW(sp)
    sw a2, 3*REGW(sp)
    sw a3, 4*REGW(sp)
    sw a4, 5*REGW(sp)
    sw a5, 6*REGW(sp)
    sw a6, 7*REGW(sp)
    sw a7, 8*REGW(sp)
    sw t0, 9*REGW(sp)
    sw t1, 10*REGW(sp)
    sw t2, 11*REGW(sp)
    sw t3, 12*REGW(sp)
    sw t4, 13*REGW(sp)
    sw t5, 14*REGW(sp)
    sw t6, 15*REGW(sp)

    jal handle_trap
  
    lw ra, 0*REGW(sp)
    lw a0, 1*REGW(sp)
    lw a1, 2*REGW(sp)
    lw a2, 3*REGW(sp)
    lw a3, 4*REGW(sp)
    lw a4, 5*REGW(sp)
    lw a5, 6*REGW(sp)
    lw a6, 7*REGW(sp)
    lw a7, 8*REGW(sp)
    lw t0, 9*REGW(sp)
    lw t1, 10*REGW(sp)
    lw t2, 11*REGW(sp)
    lw t3, 12*REGW(sp)
    lw t4, 13*REGW(sp)
    lw t5, 14*REGW(sp)
    lw t6, 15*REGW(sp)

    addi sp, sp, 17*REGW

    mret
