#include <stdio.h>

void swap(int * x, int * y);
int get_val(int a);

int main() {

    int x = 1;
    int y = 2;
    int z[10] = {0, 1, 2, 3, 4, 5, 6, 7, 8, 9};
    int *ip;
    char *pmsg = "I'm a string";
    int (*func_ptr)(int) = &get_val;
    int temp;

    ip = &x;

    // Copy x value into y, then compare
    y = *ip;

    if (y != x)
        asm("addi t6,t6,1");

    // Increment x, check the pointer works and y not updated
    ++(*ip);

    if (y == x)
        asm("addi t6,t6,1");

    // Use pointers in functions
    swap(&x, &y);

    if (x != 1 && y != 2)
        asm("addi t6,t6,1");

    // Check pointing to a array 
    ip = &z[0];

    if (*ip != 0)
        asm("addi t6,t6,1");

    if (*(ip+1) != 1)
        asm("addi t6,t6,1");

    if (*(ip+9) != 9)
        asm("addi t6,t6,1");

    // Check pointer to char
    if (*pmsg != 'I')
        asm("addi t6,t6,1");

    if (*(pmsg+4) != 'a')
        asm("addi t6,t6,1");

    // Function to pointer
    temp = (*func_ptr)(10);
    if (temp != 10)
        asm("addi t6,t6,1");

    asm("ebreak");
}

void swap(int * x, int * y) {
    
    int temp;

    temp = *x;
    *x = *y;
    *y = temp;
};

int get_val(int a) {
    return a;
};
