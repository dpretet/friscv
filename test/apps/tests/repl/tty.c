// distributed under the mit license
// https://opensource.org/licenses/mit-license.php

#include "tty.h"
#include "uart.h"


void print_s(const char * str) {
    while (*str != 0) {
        uart_putchar(*(str++));
    }
}


void print_i(int i) {
    uart_putchar(i+'0');
}
