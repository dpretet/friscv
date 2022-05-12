// distributed under the mit license
// https://opensource.org/licenses/mit-license.php

#ifndef UART_INCLUDE
#define UART_INCLUDE

extern void uart_putchar(char c);
extern char uart_getchar();
extern int uart_is_empty();
extern int uart_is_full();

#endif // UART_INCLUDE

