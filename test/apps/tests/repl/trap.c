// distributed under the mit license
// https://opensource.org/licenses/mit-license.php

#include <stdint.h>
#include "tty.h"
#include "printf.h"
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
        _print("Software interrupt\n");
        msip_irq_off();
    
    // MTIP
    } else if (mcause == 0x80000007) {
        _print("Timer interrupt\n");
        mtip_irq_off();

    // MEIP
    } else if (mcause == 0x8000000B) {
        _print("External interrupt\n");
        meip_irq_off();

    } else {
        _print("Unknown interrupt");
        shutdown();
    }
}

void handle_exception(int mcause) {

    if (mcause == 0x0) {
        _print("Instruction address misaligned");
        shutdown();
    } else if (mcause == 0x1) {
        _print("Instruction access fault");
        shutdown();
    } else if (mcause == 0x2) {
        _print("Illegal instruction");
        shutdown();
    } else if (mcause == 0x8) {
        _print("ECALL (U-mode)");
    } else if (mcause == 0x9) {
        _print("ECALL (S-mode)");
    } else if (mcause == 0xB) {
        _print("ECALL (M-mode)");
    } else if (mcause == 0x3) {
        _print("EBREAK");
    } else if (mcause == 0x6) {
        _print("Store misalign");
        shutdown();
    } else if (mcause == 0x4) {
        _print("Load misalign");
        shutdown();
    } else {
        _print("Unknown exception");
        shutdown();
    }
    
    irq_off();
}

void handle_trap() {

    int mcause, mepc;

    asm volatile("csrr %0, mcause" : "=r"(mcause));
    asm volatile("csrr %0, mepc" : "=r"(mepc));

    _print("Handling trap: MCAUSE=%x\n", mcause);

    if (mcause >> 31) {
        _print("Handling interrupt\n");
        handle_interrupt(mcause);
    } else {
        _print("Handling exception\n");
        handle_exception(mcause);
        asm volatile("csrr t0, mepc");
        asm volatile("addi t0, t0, 0x4");
        asm volatile("csrw mepc, t0");
    }    

}
