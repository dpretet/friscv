// distributed under the mit license
// https://opensource.org/licenses/mit-license.php

#include <stdint.h>
#include "tty.h"
#include "clint.h"
#include "system.h"
#include "irq.h"

int count = 0;
int mtimecmp = 0;
int mtime = 0;
int mie;

void handle_interrupt(int mcause) {
    
    irq_off();

    // MSIP
    if (mcause == 0x80000003) {
        print_s("Software interrupt\n");
        msip_irq_off();
    
    // MTIP
    } else if (mcause == 0x80000007) {
        print_s("Timer interrupt\n");
        mtip_irq_off();

    // MEIP
    } else if (mcause == 0x8000000B) {
        print_s("External interrupt\n");
        meip_irq_off();

    } else {
        print_s("Unknown interrupt");
        shutdown();
    }
}

void handle_exception(int mcause) {

    if (mcause == 0x0) {
        print_s("Instruction address misaligned");
        shutdown();
    } else if (mcause == 0x1) {
        print_s("Instruction access fault");
        shutdown();
    } else if (mcause == 0x2) {
        print_s("Illegal instruction");
        shutdown();
    } else if (mcause == 0x8) {
        print_s("ECALL (U-mode)");
    } else if (mcause == 0x9) {
        print_s("ECALL (S-mode)");
    } else if (mcause == 0xB) {
        print_s("ECALL (M-mode)");
    } else if (mcause == 0x3) {
        print_s("EBREAK");
    } else if (mcause == 0x6) {
        print_s("Store misalign");
        shutdown();
    } else if (mcause == 0x4) {
        print_s("Load misalign");
        shutdown();
    } else {
        print_s("Unknown exception");
        shutdown();
    }
    
    irq_off();
}

void handle_trap() {

    int mcause, mepc;

    asm volatile("csrr %0, mcause" : "=r"(mcause));
    asm volatile("csrr %0, mepc" : "=r"(mepc));

    print_s("Handling trap: MCAUSE=");
    print_i(mcause);
    print_s("\n");

    if (mcause >> 31) {
        print_s("Handling interrupt\n");
        handle_interrupt(mcause);
    } else {
        print_s("Handling exception\n");
        handle_exception(mcause);
        asm volatile("csrr t0, mepc");
        asm volatile("addi t0, t0, 0x4");
        asm volatile("csrw mepc, t0");
    }    

}
