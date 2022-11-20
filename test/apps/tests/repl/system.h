// distributed under the mit license
// https://opensource.org/licenses/mit-license.php

#ifndef SYSTEM_INCLUDE
#define SYSTEM_INCLUDE

static inline void shutdown() {
    asm volatile("ebreak");
}

static inline void ebreak() {
    asm volatile("ebreak");
}

static inline void wfi() {
    asm volatile("wfi");
}

#endif // SYSTEM_INCLUDE

