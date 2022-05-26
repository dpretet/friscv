// distributed under the mit license
// https://opensource.org/licenses/mit-license.php

#include <stdio.h>
#include <string.h>

#include "uart.h"
#include "system.h"
#include "irq.h"
#include "clint.h"
#include "tty.h"



int main() {

    // Print welcome message and print the "shell"
    const char * sleep = "sleep\0";
    const char * echo = "echo\0";
    const char * prompt = ">";
    const char * nl = "\n";
    const char * welcome = "\n\nWelcome to FRISCV\n";
    char cmdline[128];
    int cmdsize = 0;
    int inChar;
    int eot = 0;
    int i=0;

    print_s(welcome);
    uart_putchar(*prompt);

    // irq_on();
    // msip_irq_on();
    // mtip_irq_on();

    // Event loop of REPL
    // Made of a simple FSM, alternating between reception and transmission
    while (1) {

        // Reading the input command line
        if (!eot) {

            if (uart_is_empty() == 0) {

                inChar = uart_getchar();

                // EOT
                if (inChar==4) {
                    eot = 1;
                } else {
                    cmdline[cmdsize] = inChar;
                    cmdsize += 1;
                }
            }

        // Once finish to empty the FIFO, post a new prompt
        } else {

            // Echo
            if (strncmp(cmdline, echo, 4) >= 0) {
                for (int i=5; i<cmdsize; i++)
                    uart_putchar(cmdline[i]);
            // Sleep
            } else if (strncmp(cmdline, sleep, 5) >= 0) {
                for (i=0; i<cmdsize; i++)
                    uart_putchar(cmdline[i]);
            }
            eot = 0;
            cmdsize = 0;
            uart_putchar(*nl);
            uart_putchar(*prompt);

            // Interrupt tests
            // clint_set_msip(1);
            // clint_set_msip(0);
            // clint_set_mtimecmp(10, 0);
        }
    }

    // Stop the SOC
    shutdown();
}

