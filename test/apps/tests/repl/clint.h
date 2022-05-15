// distributed under the mit license
// https://opensource.org/licenses/mit-license.php

#ifndef CLINT_INCLUDE
#define CLINT_INCLUDE

extern void clint_set_msip(int assert);
extern int clint_get_msip();
extern void clint_set_mtime_lsb(int lsb);
extern int clint_get_mtime_lsb();
extern void clint_set_mtime_msb(int msb);
extern int clint_get_mtime_msb();
extern void clint_set_mtimecmp_lsb(int lsb);
extern int clint_get_mtimecmp_lsb();
extern void clint_set_mtimecmp_msb(int msb);
extern int clint_get_mtimecmp_msb();

#endif // CLINT_INCLUDE

