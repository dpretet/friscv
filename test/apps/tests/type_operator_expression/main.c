#include <stdio.h>

#define MAX_VALUE 100


int main() {

    int cnt = 0xFFFFFFFF;
    unsigned pos_only = 0xFFFFFFFE;
    short int short_cnt = 0x0CC0;
    char digit = 'x';

    ++digit;
    ++cnt;
    short_cnt = 0xFFFF0000 | short_cnt;

    if (cnt!=0)
        asm("addi t6,t6,1");

    if (digit!='y')
        asm("addi t6,t6,1");

    if (short_cnt!=0x0CC0)
        asm("addi t6,t6,1");

    cnt = cnt++;

    if (cnt!=0)
        asm("addi t6,t6,1");

    cnt = ++cnt;

    if (cnt!=1)
        asm("addi t6,t6,1");

    cnt = ~cnt;
    if (cnt!=0xFFFFFFFE)
        asm("addi t6,t6,1");

    digit = digit & cnt;

    if (digit!='x')
        asm("addi t6,t6,1");

    pos_only = pos_only >> 1;

    if (pos_only!=0x7FFFFFFF)
        asm("addi t6,t6,1");

    cnt = cnt >> 1;

    if (cnt!=0xFFFFFFFF)
        asm("addi t6,t6,1");

    cnt = cnt << 1;
    cnt = cnt ^ 0x1;

    if (cnt!=0xFFFFFFFF)
        asm("addi t6,t6,1");

    asm("ebreak");
}
