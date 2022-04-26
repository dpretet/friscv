// distributed under the mit license
// https://opensource.org/licenses/mit-license.php

#include <stdio.h>

int main() {

    int array[10] = {40, 10, 40, 10};
    int mean = 0;

    for (int i=0; i < 4; ++i) {
        mean += array[i];
    };

    mean /= 4;

    if (mean != 25)
        asm("addi t6,t6,1");

    asm("ebreak");
}

