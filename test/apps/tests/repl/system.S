# distributed under the mit license
# https://opensource.org/licenses/mit-license.php

.section .text

#------------------------------------------------------------------------------
# Export functions' symbols for C call
#------------------------------------------------------------------------------

.global shutdown
.type shutdown, @function

.global _syscall

#------------------------------------------------------------------------------
# Stop the processor with EBREAK
#------------------------------------------------------------------------------
shutdown:
    ebreak


#------------------------------------------------------------------------------
# System call: can arrive here on ecall or from a trap handling
#------------------------------------------------------------------------------
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
