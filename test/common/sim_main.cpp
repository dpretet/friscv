#include "build/Vfriscv_testbench.h"
#include "verilated.h"

int main(int argc, char** argv, char** env) {

    Verilated::commandArgs(argc, argv);
    Vfriscv_testbench* top = new Vfriscv_testbench;
    int timer = 0;

    // Simulate until $finish
    while (!Verilated::gotFinish() && timer<top->timeout && top->status==0) {

        // Evaluate model;
        top->eval();
    }

    // Final model cleanup
    top->final();

    // Destroy model
    delete top;

    // Return good completion status
    return 0;
}
