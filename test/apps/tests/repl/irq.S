# distributed under the mit license
# https://opensource.org/licenses/mit-license.php

.section .text

#------------------------------------------------------------------------------
# Trap code present in MCAUSE
#------------------------------------------------------------------------------

# Asynchronous traps:
# Bit 31 = 1
.equ MSIP,  0x3
.equ MTIP,  0x7
.equ MEIP,  0x8

# Synchronous traps:
# Bit 31 = 0
.equ ADDR_MISALIGNED,   0x0
.equ CSR_RO_WR,         0x1
.equ DEC_ERROR,         0x2
.equ ECALL,             0xB
.equ EBREAK,            0x3
.equ ST_MISALIGNED,     0x6
.equ LD_MISALIGNED,     0x4


