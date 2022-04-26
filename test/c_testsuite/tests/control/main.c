// distributed under the mit license
// https://opensource.org/licenses/mit-license.php

#include <stdio.h>

#define MAX_VALUE 100


int main() {

    int cnt = 0;

    // if/else control

    if (cnt!=0)
        asm("addi t6,t6,1");
    else
        ++cnt;

    if (cnt==0)
        asm("addi t6,t6,1");
    else
        ++cnt;

    // if/else if/else control
    if (cnt==0)
        asm("addi t6,t6,1");
    else if (cnt==1)
        asm("addi t6,t6,1");
    else
        cnt = 2;

    // switch control
    switch (cnt) {
        case 0:
            asm("addi t6,t6,1");
        case 1:
            asm("addi t6,t6,1");
        default:
            cnt = 10;
    }

    // for loop control
    for (int i=0;i<10;++i)
        --cnt;

    if (cnt!=0)
        asm("addi t6,t6,1");

    cnt = 1;
    do {
        cnt = cnt << 1;
    } while (cnt<10);

    if (cnt!=16)
        asm("addi t6,t6,1");

    while (cnt<100) {
        cnt = cnt << 1;
    }

    if (cnt!=128)
        asm("addi t6,t6,1");

    asm("ebreak");
}
