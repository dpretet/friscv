// distributed under the mit license
// https://opensource.org/licenses/mit-license.php

#include <stdint.h>
#include "soc_mapping.h"

#ifndef UART_INCLUDE
#define UART_INCLUDE

#define UART_STATUS (UART_ADDRESS + 0x0)
#define UART_CLKDIV (UART_STATUS  + 0x4)
#define UART_TX     (UART_STATUS  + 0x8)
#define UART_RX     (UART_STATUS  + 0xC)


/*
* Push a char into UART TX FIFO
*/
static inline void uart_putchar(char c) {
    *((volatile int*) UART_TX) = c;
}

/*
* Get a char from UART RX FIFO
*/
static inline char uart_getchar() {
    return *((volatile int*) UART_RX);
}

/*
* Read UART status register to know if RX FIFO is empty
*/
static inline int uart_is_empty() {

    int status;
    status = *((volatile int*) UART_STATUS);
    status = status >> 11;
    status = status & 0x1;
    return status;
}

/*
* Read UART status register to know if TX FIFO is full
*/
static inline int uart_is_full() {

    int status;
    status = *((volatile int*) UART_STATUS);
    status = status >> 10;
    status = status & 0x1;
    return status;
}


#endif // UART_INCLUDE
