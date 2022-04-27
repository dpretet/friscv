// distributed under the mit license
// https://opensource.org/licenses/mit-license.php

#include <stdio.h>
#include <stdlib.h>

#define ARRAYW 10
int * i_heap;

void dyn_alloc() ;
void dyn_free() ;

int main() {

    dyn_alloc();
    for (int i=0;i<ARRAYW;++i)
        *(i_heap+i) = i;
    dyn_free();
    asm("ebreak");
}

void dyn_alloc() {
    i_heap = (int*)malloc(ARRAYW * sizeof(int));
};
 
void dyn_free() {
    free(i_heap);
};
