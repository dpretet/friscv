// distributed under the mit license
// https://opensource.org/licenses/mit-license.php

#include <stdio.h>
#include <string.h>

#include "uart.h"
#include "system.h"
#include "irq.h"
#include "clint.h"
#include "tty.h"

#define EOT 4

int main() {

    const char * c_sleep = "sleep\0";
    const char * c_echo = "echo\0";
    const char * c_shutdown = "shutdown\0";
    const char * c_exit = "exit\0";
    const char * c_ebreak = "ebreak\0";
    const char * c_help = "help\0";

    char cmdline[128];
    int cmdsize = 0;
    int inChar;
    int eot = 0;
    int i=0;

    SUCCESS("\n\nWelcome to FRISCV\n");
    uart_putchar(EOT);

    // Event loop of REPL
    // Made of a simple FSM, alternating between reception and transmission
    while (1) {

        // Reading the input command line until receiving a EOT (ASCII=4)
        if (!eot) {

            if (uart_is_empty() == 0) {

                inChar = uart_getchar();

                if (inChar==EOT) {
                    eot = 1;
                } else {
                    cmdline[cmdsize] = inChar;
                    cmdsize += 1;
                }
            }

        // Once finish to empty the FIFO, execute the command and print a new prompt
        } else {

            // Echo
            if (strncmp(cmdline, c_echo, 4) == 0) {
                for (i=5; i<cmdsize; i++)
                    uart_putchar(cmdline[i]);

            // Sleep during N cycles
            } else if (strncmp(cmdline, c_sleep, 5) == 0) {
                irq_on();
                clint_set_mtime(0, 0);
                clint_set_mtimecmp(100, 0);
                mtip_irq_on();
                wfi();
                mtip_irq_off();
                INFO("Slept!\n");

            // Shutdown / ebreak / exit
            } else if (strncmp(cmdline, c_shutdown, 8) == 0 ||
                        strncmp(cmdline, c_exit, 4) == 0 ||
                        strncmp(cmdline, c_ebreak, 6) == 0
            ) {
                SUCCESS("Exiting... See you!");
                shutdown();

            // Help menu
            } else if (strncmp(cmdline, c_help, 4) == 0) {
                MSG("FRISCV help:\n");
                MSG("   help: print this menu\n");
                MSG("   echo: print the chars passed\n");
                MSG("   sleep: pause during the time specified\n");
                MSG("   shutdown: stop the processor (EBREAK)\n");

            } else {
                ERROR("Unrecognized command");
            }

            eot = 0;
            cmdsize = 0;
            uart_putchar(EOT);
        }
    }

    // Stop the SOC
    shutdown();
}

