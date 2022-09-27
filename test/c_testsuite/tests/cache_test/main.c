// distributed under the mit license
// https://opensource.org/licenses/mit-license.php

#include <stdio.h>
#define N 100
int main() {

    int a[N][N];
    int x[N];
    int y[N];

    for (int i = 0; i < N; i++)  {
        x[i] = 1;
        y[i] = 0;
        for (int j=0; j<N; j++)
            a[i][j] = 1;
    }

    for (int i = 0; i < N; i++) {
        for (int j = 0; j < N; j++) {
            y[i] = y[i] + a[i][j] + x[j];
        }
    }

    for (int i = 0; i < N; i++) {
        if (y[i] != 100)
            asm("addi x31, x31, 1");
    }

    asm("ebreak");
}
