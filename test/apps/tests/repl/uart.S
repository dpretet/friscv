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
# Push a char into UART TX FIFO
#
# Argument:
#   - a0: a 8 bits char
#
# Returns:
#   - Nothing
#-------------------------------------------------------------
uart_putchar:
    # UART TX FIFO address
    li t0, 0x100010
    # Write to
    sw a0, 0(t0)
    ret


#-------------------------------------------------------------
# Get a char from UART RX FIFO
#
# Arguments:
#   - Nothing
#
# Returns:
#   - a 8 bit char
#-------------------------------------------------------------
uart_getchar:
    # UART RX FIFO address
    li t0, 0x100014
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
    # UART Status register
    li t0, 0x100008
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
    # UART Status register
    li t0, 0x100008
    # Read status register
    lw t1, 0(t0)
    # Extract full bit
    srli t1, t1, 10
    andi a0, t1, 0x1
    ret
