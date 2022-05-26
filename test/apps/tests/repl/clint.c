// distributed under the mit license
// https://opensource.org/licenses/mit-license.php

#include <stdint.h>
#include "clint.h"

//------------------------------------------------------------------------------
// Assert MSIP interrupt(s)
//
// Arguments:
//   - a0: a 32 bits value
//
// Returns:
//   - Nothing
//------------------------------------------------------------------------------
void clint_set_msip(int msip) {
    *((volatile int*) MSIP) = msip;
}

//------------------------------------------------------------------------------
// Read MSIP interrupt register
//
// Arguments:
//   - Nothing
//
// Returns:
//   - a 32 bits value
//------------------------------------------------------------------------------
int clint_get_msip() {
    return *((volatile int*) MSIP);
}

//------------------------------------------------------------------------------
// Write mtime counter
//
// Arguments:
//   - a0: a 32 bits value
//   - a1: a 32 bits value
//
// Returns:
//   - Nothing
//------------------------------------------------------------------------------
void clint_set_mtime(int lsb, int msb) {
    *((volatile int*) MTIME_LSB) = lsb;
    *((volatile int*) MTIME_MSB) = msb;
}

//------------------------------------------------------------------------------
// Read mtime counter (LSB 31:0) RV32 only
//
// Arguments:
//   - nothing
//
// Returns:
//   - a 32 bits value
//------------------------------------------------------------------------------
int clint_get_mtime_lsb() {
    return *((volatile int*) MTIME_LSB);
}

//------------------------------------------------------------------------------
// Read mtime counter (MSB 63:32)    RV32 only
//
// Arguments:
//   - nothing
//
// Returns:
//   - a 32 bits value
//------------------------------------------------------------------------------
int clint_get_mtime_msb() {
    return *((volatile int*) MTIME_MSB);
}

//------------------------------------------------------------------------------
// Write mtime counter
//
// Arguments:
//   - a0: a 32 bits value, LSB
//   - a1: a 32 bits value, MSB
//
// Returns:
//   - nothing
//------------------------------------------------------------------------------
void clint_set_mtimecmp(int lsb, int msb) {
    *((volatile int*) MTIMECMP_LSB) = lsb;
    *((volatile int*) MTIMECMP_MSB) = msb;
}

//------------------------------------------------------------------------------
// Read mtimecmp register (LSB 31:0) RV32 only
//
// Arguments:
//   - nothing
//
// Returns:
//   - a 32 bits value
//------------------------------------------------------------------------------
int clint_get_mtimecmp_lsb() {
    return *((volatile int*) MTIMECMP_LSB);
}

//------------------------------------------------------------------------------
// Write mtimecmp register
//
// Arguments:
//   - a0: a 32 bits value, LSB
//   - a1: a 32 bits value, MSB
//
// Returns:
//   - nothing
//------------------------------------------------------------------------------
int clint_get_mtimecmp_msb() {
    return *((volatile int*) MTIMECMP_MSB);
}
