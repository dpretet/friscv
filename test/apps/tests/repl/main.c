// distributed under the mit license
// https://opensource.org/licenses/mit-license.php

#include <stdio.h>
#include <string.h>

#include "uart.h"
#include "system.h"
#include "sleep.h"
#include "irq.h"
#include "clint.h"
#include "tty.h"
#include "echo.h"

// ASCII codes
#define EOT 4
#define SPACE 32
#define TAB 9

// Two defines to setup max args / max arg's size when
// building the command from UART
#define MAX_ARGS 4
#define MAX_ARGS_SIZE 10

int main() {

    // Supported command
    const char * c_echo = "echo";
    const char * c_sleep = "sleep";
    const char * c_shutdown = "shutdown";
    const char * c_exit = "exit";
    const char * c_ebreak = "ebreak";
    const char * c_help = "help";

    int inChar;
    int eot = 0;
    int ix = 0;
    int argc = 0;

    char argv[MAX_ARGS][MAX_ARGS_SIZE];
    char * pargv[MAX_ARGS];

    for (int i=0;i<MAX_ARGS;i++) {
        pargv[i] = &argv[i][0];
    }

    SUCCESS("\n\nWelcome to FRISCV\n");
    uart_putchar(EOT);

    // Event loop of REPL
    // Made of a simple FSM, moving between reception and transmission
    while (1) {

        // Reading the input command line until receiving a EOT (ASCII=4)
        if (!eot) {

            // TODO: Check argc & ix doesn't overflow argv

            if (uart_is_empty() == 0) {

                inChar = uart_getchar();

                if (inChar == EOT) {
                    argv[argc][ix] = '\0';
                    argc += 1;
                    ix = 0;
                    eot = 1;
                } else {

                    if (inChar == SPACE) {
                        argv[argc][ix] = '\0';
                        argc += 1;
                        ix = 0;
                    } else {
                        argv[argc][ix] = inChar;
                        ix += 1;
                    }
                    eot = 0;
                }
            }

        // Once finish to empty the FIFO, execute the command and print a new prompt marker
        } else {

            // echo(argc, pargv);
            // Echo
            if (strncmp(argv[0], c_echo, 4) == 0) {
                echo(argc, pargv);

            // Sleep during N cycles
            } else if (strncmp(argv[0], c_sleep, 5) == 0) {
                sleep(argc, pargv);

            // Shutdown / ebreak / exit
            } else if (strncmp(argv[0], c_shutdown, 8) == 0 ||
                       strncmp(argv[0], c_exit, 4) == 0 ||
                       strncmp(argv[0], c_ebreak, 6) == 0) {
                SUCCESS("Exiting... See you!");
                shutdown();

            // Help menu
            } else if (strncmp(argv[0], c_help, 4) == 0) {
                MSG("FRISCV help:\n");
                MSG("   help: print this menu\n");
                MSG("   echo: print the chars passed\n");
                MSG("   sleep: pause during the time specified\n");
                MSG("   exit: stop the processor (execute EBREAK)\n");
                MSG("   ebreak: same than exit\n");
                MSG("   shutdown: same than exit\n");

            } else {
                ERROR("Unrecognized command\n");
                print_s("\nargc ");
                print_i(argc);
                print_s("\nargv ");
                print_s(argv[0]);
                print_s("\n");
            }
            eot = 0;
            ix = 0;
            argc = 0;
            uart_putchar(EOT);
        }
    }

    // Stop the SOC
    shutdown();
}

