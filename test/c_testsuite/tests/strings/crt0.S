# distributed under the mit license
# https://opensource.org/licenses/mit-license.php

.section .text.init;
.global _start

_start:

    # First init all the registers to 0
    li x1, 0
    li x2, 0
    li x3, 0
    li x4, 0
    li x5, 0
    li x6, 0
    li x7, 0
    li x8, 0
    li x9, 0
    li x10, 0
    li x11, 0
    li x12, 0
    li x13, 0
    li x14, 0
    li x15, 0
    li x16, 0
    li x17, 0
    li x19, 0
    li x20, 0
    li x21, 0
    li x22, 0
    li x23, 0
    li x24, 0
    li x25, 0
    li x26, 0
    li x27, 0
    li x28, 0
    li x29, 0
    li x30, 0
    li x31, 0

    # Init the max boundary of the stack section
    # _estack will be linked later with the linker file symbols
    la sp, _estack

    # Setup ecall
    la t0, _syscall
    csrw    mtvec,t0

    # Jump to the main
    j _stext

_syscall:
    # a7 = 214
    li t3, 214
    bne a7, t3, ret_syscall
    # Fake sbrk
    la a0, _edata

ret_syscall:
    # Consider everything was fine, we'll move to the next instruction
    csrr t0, mepc
	addi t0, t0, 4
	csrw mepc, t0
    mret



# Add vector tables for exceptions and interrupts
# https://www.youtube.com/watch?v=2Hm8eEHsgls&list=PLERTijJOmYrDiiWd10iRHY0VRHdJwUH4g&index=3
# https://gcc.gnu.org/onlinedocs/gcc/Common-Variable-Attributes.html#Common-Variable-Attributes
# Check existing processor for inspiration


# The BSS section reserves RAM space for declared but uninitialized variables.
# TODO: intialize with startup
