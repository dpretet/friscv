#include <stdio.h>

struct point {
    int x;
    int y;
};

struct point create_pnt(int x, int y);

int main() {

    struct point pt;
    struct point temp_pt;

    pt.x = 5;
    pt.y = 23;

    if (pt.x != 5)
        asm("addi t6,t6,1");

    if (pt.y != 23)
        asm("addi t6,t6,1");

    temp_pt = create_pnt(4, 1);

    if (temp_pt.x != 4)
        asm("addi t6,t6,1");

    if (temp_pt.y != 1)
        asm("addi t6,t6,1");

    asm("ebreak");
}

struct point create_pnt(int x, int y) {

    struct point temp;

    temp.x = x;
    temp.y = y;

    return temp;
};
