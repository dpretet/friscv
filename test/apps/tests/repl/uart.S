# distributed under the mit license
# https://opensource.org/licenses/mit-license.php

.section .text

#-------------------------------------------------------------
# Export functions' symbols for C call
#-------------------------------------------------------------

.global uart_putchar
.type uart_putchar, @function

.global uart_getchar
.type uart_getchar, @function

.global uart_is_empty
.type uart_is_empty, @function

.global uart_is_full
.type uart_is_full, @function


#-------------------------------------------------------------
# UART registers address
#-------------------------------------------------------------

.equ UART_STATUS, 0x100008
.equ UART_CLKDIV, 0x10000C
.equ UART_TX,     0x100010
.equ UART_RX,     0x100014


#-------------------------------------------------------------
# Push a char into UART TX FIFO
#
# Arguments:
#   - a0: a 8 bits char
#
# Returns:
#   - Nothing
#-------------------------------------------------------------
uart_putchar:
    li t0, UART_TX
    sw a0, 0(t0)
    ret


#-------------------------------------------------------------
# Get a char from UART RX FIFO
#
# Arguments:
#   - Nothing
#
# Returns:
#   - a 8 bits char
#-------------------------------------------------------------
uart_getchar:
    li t0, UART_RX
    lw a0, 0(t0)
    ret


#-------------------------------------------------------------
# Read UART status register to know if RX FIFO is empty
#
# Arguments:
#   - Nothing
#
# Returns:
#   - 1 if RX FIFO is empty, 0 if full or partially filled
#-------------------------------------------------------------
uart_is_empty:
    li t0, UART_STATUS
    # Read status register
    lw t1, 0(t0)
    # Extract empty bit
    srli t1, t1, 11
    andi a0, t1, 0x1
    ret


#-------------------------------------------------------------
# Read UART status register to know if TX FIFO is full
#
# Arguments:
#   - Nothing
#
# Returns:
#   - 1 if TX FIFO is full, 0 if empty or partially filled
#-------------------------------------------------------------
uart_is_full:
    li t0, UART_STATUS
    # Read status register
    lw t1, 0(t0)
    # Extract full bit
    srli t1, t1, 10
    andi a0, t1, 0x1
    ret
