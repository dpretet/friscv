// distributed under the mit license
// https://opensource.org/licenses/mit-license.php

#include <stdint.h>
#include "soc_mapping.h"

#ifndef CLINT_INCLUDE
#define CLINT_INCLUDE

#define MSIP           (CLINT_ADDRESS + 0x0)
#define MTIME_LSB      (MSIP          + 0x4)
#define MTIME_MSB      (MTIME_LSB     + 0x4)
#define MTIMECMP_LSB   (MTIME_MSB     + 0x4)
#define MTIMECMP_MSB   (MTIMECMP_LSB  + 0x4)

void clint_set_msip(int msip);

int clint_get_msip();

void clint_set_mtime(int lsb, int msb);

int clint_get_mtime_lsb();
int clint_get_mtime_msb();

void clint_set_mtimecmp(int lsb, int msb);

int clint_get_mtimecmp_lsb();
int clint_get_mtimecmp_msb();

#endif // CLINT_INCLUDE
