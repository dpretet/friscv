// distributed under the mit license
// https://opensource.org/licenses/mit-license.php

#include <stdio.h>

#define MAX_VALUE 100

int cnt;

void increment();

int main() {

    extern int cnt;

    cnt = MAX_VALUE/2;

    for (int i=0; i<MAX_VALUE/2;i++)
        increment();

    if (cnt!=MAX_VALUE)
        asm("addi t6,t6,1");

    asm("ebreak");
}

void increment() {

    extern int cnt;
    cnt = cnt + 1;
}
