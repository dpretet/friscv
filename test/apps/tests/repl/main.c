// distributed under the mit license
// https://opensource.org/licenses/mit-license.php

#include <stdio.h>

#include "uart.h"
#include "system.h"
#include "clint.h"

int main() {

    // Print welcome message and print the "shell"
    const char prompt[1] = ">";
    const char nl[1] = "\n";
    const char welcome[20] = "\n\nWelcome to FRISCV\n";
    int is_empty;
    int inChar;
    int was_writing = 0;

    for (int i=0;i<20;i=i+1) {
        uart_putchar(welcome[i]);
    }

    uart_putchar(prompt[0]);

    // Event loop of REPL
    // TODO: Put in place a protocol with SOT / EOT flags,
    // possibly needing an error management and retry mechanism
    while (1) {

        is_empty = uart_is_empty();

        // Loop over the FIFO to return back the data
        if (!is_empty) {
            inChar = uart_getchar();
            uart_putchar(inChar);
            was_writing = 1;
        // Once finish to empty the FIFO, post a new prompt
        } else if (was_writing) {
            was_writing = 0;
            uart_putchar(nl[0]);
            uart_putchar(prompt[0]);
            clint_set_msip(1);
            clint_set_msip(0);
            clint_set_mtimecmp_lsb(10);
        }
    }

    // Stop the SOC
    shutdown();
}

