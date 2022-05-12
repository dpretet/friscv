# distributed under the mit license
# https://opensource.org/licenses/mit-license.php

#-------------------------------------------------------------
# Export functions' symbols for C call
#-------------------------------------------------------------

.global clint_set_msip
.type clint_set_msip, @function

.global clint_get_msip
.type clint_get_msip, @function

.global clint_set_mtime_lsb
.type clint_set_mtime_lsb, @function

.global clint_get_mtime_lsb
.type clint_get_mtime_lsb, @function

.global clint_set_mtime_msb
.type clint_set_mtime_msb, @function

.global clint_get_mtime_msb
.type clint_get_mtime_msb, @function

.global clint_set_mtimecmp_lsb
.type clint_set_mtimecmp_lsb, @function

.global clint_get_mtimecmp_lsb
.type clint_get_mtimecmp_lsb, @function

.global clint_set_mtimecmp_msb
.type clint_set_mtimecmp_msb, @function

.global clint_get_mtimecmp_msb
.type clint_get_mtimecmp_msb, @function


#-------------------------------------------------------------
# Clint registers address
#-------------------------------------------------------------

.equ MSIP,          0x100018
.equ MTIME_LSB,     0x10001C
.equ MTIME_MSB,     0x100020
.equ MTIMECMP_LSB,  0x100024
.equ MTIMECMP_MSB,  0x100028


#-------------------------------------------------------------
# Read MSIP interrupt register
#
# Arguments:
#   - Nothing
#
# Returns:
#   - a 32 bits value
#-------------------------------------------------------------
clint_get_msip:
    li t0, MSIP
    lw a0, 0(t0)
    ret


#-------------------------------------------------------------
# Assert MSIP interrupt(s)
#
# Arguments:
#   - a0: a 32 bits value
#
# Returns:
#   - Nothing
#-------------------------------------------------------------
clint_set_msip:
    li t0, MSIP
    sw a0, 0(t0)
    ret


#-------------------------------------------------------------
# Read mtime counter (LSB 31:0)
#
# Arguments:
#   - nothing
#
# Returns:
#   - a 32 bits value
#-------------------------------------------------------------
clint_get_mtime_lsb:
    li t0, MTIME_LSB
    lw a0, 0(t0)
    ret


#-------------------------------------------------------------
# Write mtime counter (LSB 31:0)
#
# Arguments:
#   - a0: a 32 bits value
#
# Returns:
#   - nothing
#-------------------------------------------------------------
clint_set_mtime_lsb:
    li t0, MTIME_LSB
    sw a0, 0(t0)
    ret


#-------------------------------------------------------------
# Read mtime counter (MSB 63:32)
#
# Arguments:
#   - nothing
#
# Returns:
#   - a 32 bits value
#-------------------------------------------------------------
clint_get_mtime_msb:
    li t0, MTIME_MSB
    lw a0, 0(t0)
    ret


#-------------------------------------------------------------
# Write mtime counter (MSB 63:32)
#
# Arguments:
#   - a0: a 32 bits value
#
# Returns:
#   - nothing
#-------------------------------------------------------------
clint_set_mtime_msb:
    li t0, MTIME_MSB
    sw a0, 0(t0)
    ret


#-------------------------------------------------------------
# Read mtimecmp register (LSB 31:0)
#
# Arguments:
#   - nothing
#
# Returns:
#   - a 32 bits value
#-------------------------------------------------------------
clint_get_mtimecmp_lsb:
    li t0, MTIMECMP_LSB
    lw a0, 0(t0)
    ret


#-------------------------------------------------------------
# Write mtimecmp register (LSB 31:0)
#
# Arguments:
#   - a0: a 32 bits value
#
# Returns:
#   - nothing
#-------------------------------------------------------------
clint_set_mtimecmp_lsb:
    li t0, MTIMECMP_LSB
    sw a0, 0(t0)
    ret


#-------------------------------------------------------------
# Read mtimecmp register (MSB 63:32)
#
# Arguments:
#   - nothing
#
# Returns:
#   - a 32 bits value
#-------------------------------------------------------------
clint_get_mtimecmp_msb:
    li t0, MTIMECMP_MSB
    lw a0, 0(t0)
    ret


#-------------------------------------------------------------
# Write mtimecmp register (MSB 63:32)
#
# Arguments:
#   - a0: a 32 bits value
#
# Returns:
#   - nothing
#-------------------------------------------------------------
clint_set_mtimecmp_msb:
    li t0, MTIMECMP_MSB
    sw a0, 0(t0)
    ret
