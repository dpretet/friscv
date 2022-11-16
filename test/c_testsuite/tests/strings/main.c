// distributed under the mit license
// https://opensource.org/licenses/mit-license.php

#include <stdio.h>
#include <string.h>

#define NB 6
#define SIZE 6
#define REF "abcdef"

void fill(int argc, char * argv[]);
void fail();

int main() {

    int cmp = 0;
    const char * ref = REF;
    char data[SIZE];
    char data_array[NB][SIZE];
    char* parray[NB];

    for (int i=0;i<NB;i++) {
        parray[0] = &data_array[0][0];
    }

    // Test 1: perform a string copy and check it works
    asm("add x30, x30, 1");
    strcpy(data, ref);
    cmp = strcmp(data, ref);

    if (cmp !=0) {
        fail();
    }

    strcpy(parray[0], "abd");

    // Test 2: Fill an array of string thru a pointer and check it's the same than the reference
    asm("add x30, x30, 1");
    fill(NB, parray);
    for (int i=0;i<NB;i++) {
        cmp = strcmp(parray[i], ref);
        if (cmp !=0) {
            fail();
        }
    }

    asm("ebreak");
}

void fill(int argc, char * argv[]) {
    // fill the array of string with abc...

    for (int i=0;i<argc;i++) {
        for (int j=0;j<SIZE;j++) {
            if (j==0) {
                argv[i][j] = 'a';
            } else {
                argv[i][j] = argv[i][j-1] + 1;
            }
            argv[i][SIZE] = '\0';
        }
    }
}

void fail() {
    asm("add x31, x31, 1");
    asm("ebreak");
}
