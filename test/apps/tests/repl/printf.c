#include "uart.h"
#include <stdarg.h>


int toint(char str[]);

void todecstr(int num, char * str);

void tohexstr(int num, char * str);

#define next_char(msg) \
    ++msg;\
    if (*msg==0)\
        break;

//-------------------------------------------------------------------------------------------------
// Custom implementation of printf. Supports:
//  - %d: signed or unsigned 32 bits integer, only non-zero digit
//  - %x: signed or unsigned 32 bits integer, raw hexadecimal
//  - %c: character
//  - %s: string
//  - \n: new line (0xD)
//  - \t: horizontal tabulation (0x9)
//-------------------------------------------------------------------------------------------------
int _print(char * msg, ...) {

    // All the arguments passed to the functions
    va_list params;
    va_start(params, msg);
    // Temporary variables, used when extracting the args
    char char_to_print;
    char * str_ptr;
    int int_to_print;
    char int_as_str[11];
    int i;

    do {
        i = 0;
        //--------------------------------------------------------
        // Manage variables to print, support int, char and char *
        //--------------------------------------------------------
        if ((*msg)=='%') {

            next_char(msg);

            // Integer support in base 10
            if (*msg=='d') {
                int_to_print = va_arg(params, int);
                todecstr(int_to_print, int_as_str);
                if (int_as_str[10] == '-')
                    uart_putchar('-');
                while (int_as_str[i]!='\0') {
                    uart_putchar(int_as_str[i]);
                    ++i;
                }

            // Integer support in base 16
            } else if (*msg=='x') {
                int_to_print = va_arg(params, int);
                tohexstr(int_to_print, int_as_str);
                while (int_as_str[i]!='\0') {
                    uart_putchar(int_as_str[i]);
                    ++i;
                }

            // Char support
            } else if (*msg=='c') {
                char_to_print = va_arg(params, int);
                uart_putchar(char_to_print);

            // String support
            } else if (*msg=='s') {
                str_ptr = va_arg(params, char *);
                while (*str_ptr) {
                    uart_putchar(*str_ptr);
                    ++str_ptr;
                }
            // Handles the case a simple % char is expected
            } else {
                uart_putchar('%');
                _print("%c", *msg);
            }

        //-----------------------------------
        // Incoming escaped char to print (\)
        //-----------------------------------
        } else if ((*msg)==0x5C) {

            next_char(msg);

            // Insert tab
            if (*msg=='t') {
                uart_putchar(0x09);
            // Insert new line
            } else if (*msg=='n') {
                uart_putchar(0xD);
            // Others are raw printed, preceeded by a backslash
            } else {
                uart_putchar(0x5C);
                uart_putchar(*msg);
            }

        //-------------
        // Regular char
        //-------------
        } else {
            uart_putchar(*msg);
        }

        next_char(msg);

    } while (*msg);
    return 0;
}

//----------------------------------------------------------
// Convert an signed integer to string. Suport only 32 bits
// Arguments:
//  - in: a 32 bits signed integer
//  - out: an array of 9 chars, 1 for sign, 8 for the digits
//----------------------------------------------------------
void tohexstr(int num, char * str) {

    int temp = num;
    int mask;

    str[8] = '\0';

    // Get the ASCII digits
    for (int i=7;i>-1;i--) {
        mask = temp & 0xF;
        temp >>= 4;
        switch (mask) {
            case 0xF: str[i] = 'F'; break;
            case 0xE: str[i] = 'E'; break;
            case 0xD: str[i] = 'D'; break;
            case 0xC: str[i] = 'C'; break;
            case 0xB: str[i] = 'B'; break;
            case 0xA: str[i] = 'A'; break;
            case 0x9: str[i] = '9'; break;
            case 0x8: str[i] = '8'; break;
            case 0x7: str[i] = '7'; break;
            case 0x6: str[i] = '6'; break;
            case 0x5: str[i] = '5'; break;
            case 0x4: str[i] = '4'; break;
            case 0x3: str[i] = '3'; break;
            case 0x2: str[i] = '2'; break;
            case 0x1: str[i] = '1'; break;
            default:  str[i] = '0'; break;
        }
    }
}

void todecstr(int num, char * str)
{
    int i = 0;
    int rem = 0;
    int len = 0;
    int n = 0;
    int pnum = 0;

    // Convert in positive integer and save the sign
    if (num<0) {
        str[10] = '-';
        n = ~num + 1;
    } else {
        str[10] = '+';
        n = num;
    }
    pnum = n;

    // Search the number of relevant digits
    while (n != 0) {
        ++len;
        n /= 10;
    }

    // Save the current digit as char and move to the next ones
    for (i = 0; i < len; i++) {
        rem = pnum % 10;
        pnum = pnum / 10;
        str[len - (i + 1)] = rem + '0';
    }
    if (len>0) {
        str[len] = '\0';
    } else {
        str[0] = '0';
        str[1] = '\0';
    }
}
