// distributed under the mit license
// https://opensource.org/licenses/mit-license.php

#include <stdio.h>

#include "uart.h"
extern void shutdown();


int main() {

    // Print welcome message and print the "shell"
    char prompt[1] = ">";
    char nl[1] = "\n";
    char welcome[20] = "\n\nWelcome to FRISCV\n";
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
        }
    }

    // Stop the SOC
    shutdown();
}

