#include "uart.h"
#include <stdarg.h>

int _print(char * msg, ...);

int toint(char str[]);

void todecstr(int num, char str[]);

void tohexstr(int num, char * str);

#define next_char(msg) \
    ++msg;\
    if (*msg==0)\
        break;

/*
int test_printf(int argc, char *argv[]) {

    _print("////////////////////////////////////////////////\n");
    _print("print tests\n");
    _print("////////////////////////////////////////////////\n");
    _print("positive integer: %d\n", 7);
    _print("negative integer: %d\n", -5);
    _print("multi digit integer: %d\n", 47);
    _print("multi digit integer: %d\n", -234);
    _print("multi digit integer: %d\n", 234);
    _print("multi digit integer: %d\n", 9876);
    _print("multi digit integer: %d\n", 2147483647);
    _print("hexa integer: %x\n", 0xFDC0ACBD);
    _print("char: %c\n", 'X');
    _print("int: %d char: %c\n", 9, 'Y');
    _print("\n");
    _print("string: %s\n", "I am a string");
    _print("\n");
    _print("String: %s\nString: %s\n", "first", "second");
    _print("\n");
    _print("Bullets:\n");
    _print("\t- abc\n");
    _print("\t- def\n");
    _print("%f\n", 'z');
    _print("\\ % \n");
    return 0;
}
*/

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
                // Grab from argument and convert as char *
                int_to_print = va_arg(params, int);
                todecstr(int_to_print, int_as_str);
                // Print it
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
            } else if (*msg==' ') {
                uart_putchar('%');

            // All othe formatting is unsupported
            } else {
                _print("Format not supported: %c\n", *msg);
                return 1;
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
    int int_c = '0';
    int int_l = 'A';

    str[8] = '\0';

    // Get the ASCII digits
    for (int i=7;i>-1;i--) {
        mask = temp & 0xF;
        temp >>= 4;
        switch (mask) {
            // case 0xF: str[i] = 'F'; break;
            // case 0xE: str[i] = 'E'; break;
            // case 0xD: str[i] = 'D'; break;
            // case 0xC: str[i] = 'C'; break;
            // case 0xB: str[i] = 'B'; break;
            // case 0xA: str[i] = 'A'; break;
            // case 0x9: str[i] = '9'; break;
            // case 0x8: str[i] = '8'; break;
            // case 0x7: str[i] = '7'; break;
            // case 0x6: str[i] = '6'; break;
            // case 0x5: str[i] = '5'; break;
            // case 0x4: str[i] = '4'; break;
            // case 0x3: str[i] = '3'; break;
            // case 0x2: str[i] = '2'; break;
            // case 0x1: str[i] = '1'; break;
            // default:  str[i] = '0'; break;
            case 0xF: str[i] = int_l + 5; break;
            case 0xE: str[i] = int_l + 4; break;
            case 0xD: str[i] = int_l + 3; break;
            case 0xC: str[i] = int_l + 2; break;
            case 0xB: str[i] = int_l + 1; break;
            case 0xA: str[i] = int_l + 0; break;
            case 0x9: str[i] = int_c + 9; break;
            case 0x8: str[i] = int_c + 8; break;
            case 0x7: str[i] = int_c + 7; break;
            case 0x6: str[i] = int_c + 6; break;
            case 0x5: str[i] = int_c + 5; break;
            case 0x4: str[i] = int_c + 4; break;
            case 0x3: str[i] = int_c + 3; break;
            case 0x2: str[i] = int_c + 2; break;
            case 0x1: str[i] = int_c + 1; break;
            default:  str[i] = int_c; break;
        }
    }
}

void todecstr(int num, char str[])
{
    int i, rem, len = 0, n, pnum;

    // Convert in positive integer and save the sign
    if (num<0) {
        str[10] = '-';
        n = ~num + 1;
    } else {
        str[10] = '+';
        n = num;
    }
    pnum = n;

    // Search the number of relevant digits, != 0
    while (n != 0) {
        len++;
        n /= 10;
    }

    // Save the current digit as char and move to the next ones
    for (i = 0; i < len; i++) {
        rem = pnum % 10;
        pnum = pnum / 10;
        str[len - (i + 1)] = rem + '0';
    }
    str[len] = '\0';
}
