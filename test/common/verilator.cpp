#include "Vffd.h"
#include "verilated.h"
int main(int argc, char** argv, char** env) {
    Verilated::commandArgs(argc, argv);
    Vffd* top = new Vffd;
    while (!Verilated::gotFinish()) { top->eval(); }
    delete top;
    exit(0);
}
