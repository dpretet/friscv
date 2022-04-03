#include <stdio.h>

int fibonacci(int n);
void inc_error();

int main() {

    int res0 = 0;
    int res1 = 1;
    int res2 = 1;
    int res3 = 2;
    int res4 = 3;
    int res5 = 5;
    int res6 = 8;
    int res7 = 13;
    int temp = 0;

    temp = fibonacci(0);
    if (res0 != temp)
        asm("addi t6,t6,1");

    temp = fibonacci(1);
    if (res1 != temp)
        asm("addi t6,t6,1");

    temp = fibonacci(2);
    if (res2 != temp)
        asm("addi t6,t6,1");

    temp = fibonacci(3);
    if (res3 != temp)
        asm("addi t6,t6,1");

    temp = fibonacci(4);
    if (res4 != temp)
        asm("addi t6,t6,1");

    temp = fibonacci(5);
    if (res5 != temp)
        asm("addi t6,t6,1");

    temp = fibonacci(6);
    if (res6 != temp)
        asm("addi t6,t6,1");

    temp = fibonacci(7);
    if (res7 != temp)
        asm("addi t6,t6,1");

    asm("ebreak");
}

int fibonacci(int n) {

    if (n==0) return 0;
    else if (n==1) return 1;
    else return fibonacci(n-1) + fibonacci(n-2);
}

void inc_error() {
    asm("addi t6,t6,1");
}

