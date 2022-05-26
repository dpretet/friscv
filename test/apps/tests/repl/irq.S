# distributed under the mit license
# https://opensource.org/licenses/mit-license.php

.section .text

#------------------------------------------------------------------------------
# Export functions' symbols for C call
#------------------------------------------------------------------------------

.global irq_on
.type irq_on, @function

.global irq_off
.type irq_off, @function

.global msip_irq_on
.type msip_irq_on, @function

.global msip_irq_off
.type msip_irq_off, @function

.global mtip_irq_on
.type mtip_irq_on, @function

.global mtip_irq_off
.type mtip_irq_off, @function

.global meip_irq_on
.type meip_irq_on, @function

.global meip_irq_off
.type meip_irq_off, @function


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


#------------------------------------------------------------------------------
# Mask to manipulate bits into registers
#------------------------------------------------------------------------------

# Machine interrupt enable (MSTATUS)
.equ MIE_ON,    0x00000008
.equ MIE_OFF,   0xFFFFFFF7
# Supervisor interrupt enable (MSTATUS)
.equ SIE_ON,    0x00000002
.equ SIE_OFF,   0xFFFFFFFD

# Machine software interrupt enable (MIE)
.equ MSIE_ON,   0x00000008
.equ MSIE_OFF,  0xFFFFFFF7
# Supervisor software interrupt enable (MIE)
.equ SSIE_ON,   0x00000002
.equ SSIE_OFF,  0xFFFFFFFD

# Machine timer interrupt enable (MIE)
.equ MTIE_ON,   0x00000080
.equ MTIE_OFF,  0xFFFFFF7F
# Supervisor timer interrupt enable (MIE)
.equ STIE_ON,   0x00000020
.equ STIE_OFF,  0xFFFFFFDF

# Machine external interrupt enable (MIE)
.equ MEIE_ON,   0x00000800
.equ MEIE_OFF,  0xFFFFF7FF
# Supervisor external interrupt enable (MIE)
.equ SEIE_ON,   0x00000200
.equ SEIE_OFF,  0xFFFFFDFF


#------------------------------------------------------------------------------
# Functions to enable / disable IRQs
#------------------------------------------------------------------------------

# Global interrupt ON / OFF

irq_on:
    lui	t1, %hi(MIE_ON)
	addi t1, t1, %lo(MIE_ON)
    csrr t0, mstatus
    or t0, t0, t1
    csrw mstatus, t0
    ret

irq_off:
    lui	t1, %hi(MIE_OFF)
	addi t1, t1, %lo(MIE_OFF)
    csrr t0, mstatus
    and t0, t0, t1
    csrw mstatus, t0
    ret


# Machine software interrupt

msip_irq_on:
    lui	t1, %hi(MSIE_ON)
	addi t1, t1, %lo(MSIE_ON)
    csrr t0, mie
    or t0, t0, t1
    csrw mie, t0
    ret

msip_irq_off:
    lui	t1, %hi(MSIE_OFF)
	addi t1, t1, %lo(MSIE_OFF)
    csrr t0, mie
    and t0, t0, t1
    csrw mie, t0
    ret

# Machine timer interrupt

mtip_irq_on:
    lui	t1, %hi(MTIE_ON)
	addi t1, t1, %lo(MTIE_ON)
    csrr t0, mie
    or t0, t0, t1
    csrw mie, t0
    ret

mtip_irq_off:
    lui	t1, %hi(MTIE_OFF)
	addi t1, t1, %lo(MTIE_OFF)
    csrr t0, mie
    and t0, t0, t1
    csrw mie, t0
    ret

# Machine external interrupt

meip_irq_on:
    lui	t1, %hi(MEIE_ON)
	addi t1, t1, %lo(MEIE_ON)
    csrr t0, mie
    or t0, t0, t1
    csrw mie, t0
    ret

meip_irq_off:
    lui	t1, %hi(MEIE_OFF)
	addi t1, t1, %lo(MEIE_OFF)
    csrr t0, mie
    and t0, t0, t1
    csrw mie, t0
    ret
