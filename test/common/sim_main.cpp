// distributed under the mit license
// https://opensource.org/licenses/mit-license.php

#include "build/Vfriscv_testbench.h"
// For std::unique_ptr
#include <memory>
// Include common routines
#include <verilated.h>

// Legacy function required only so linking works on Cygwin and MSVC++
double sc_time_stamp() { return 0; }

int main(int argc, char** argv, char** env) {

    int ret = 0;

    // Prevent unused variable warnings
    if (false && argc && argv && env) {}

    // Construct a VerilatedContext to hold simulation time, etc.
    // Multiple modules (made later below with Vtop) may share the same
    // context to share time, or modules may have different contexts if
    // they should be independent from each other.
    // Using unique_ptr is similar to
    // "VerilatedContext* contextp = new VerilatedContext" then deleting at end.
    const std::unique_ptr<VerilatedContext> contextp{new VerilatedContext};
    // Set debug level, 0 is off, 9 is highest presently used
    // May be overridden by commandArgs argument parsing
    contextp->debug(0);
    // Randomization reset policy
    // May be overridden by commandArgs argument parsing
    contextp->randReset(1);
    // Verilator must compute traced signals
    contextp->traceEverOn(true);
    // Pass arguments so Verilated code can see them, e.g. $value$plusargs
    // This needs to be called before you create any model
    contextp->commandArgs(argc, argv);
    // Construct the Verilated model, from Vtop.h generated from Verilating "top.v".
    // Using unique_ptr is similar to "Vtop* top = new Vtop" then deleting at end.
    // "TOP" will be the hierarchical name of the module.
    const std::unique_ptr<Vfriscv_testbench> top{new Vfriscv_testbench{contextp.get(), "friscv_testbench"}};


    top->aclk = 0;
    top->aresetn = 0;
    top->srst = 0;

    // Simulate until $finish
    while (!contextp->gotFinish()) {

        contextp->timeInc(1);  // 1 timeprecision period passes...
        // Historical note, before Verilator 4.200 a sc_time_stamp()
        // function was required instead of using timeInc.  Once timeInc()
        // is called (with non-zero), the Verilated libraries assume the
        // new API, and sc_time_stamp() will no longer work.

        // Toggle a fast (time/2 period) clock
        top->aclk = !top->aclk;

        // Toggle control signals on an edge that doesn't correspond
        // to where the controls are sampled; in this example we do
        // this only on a negedge of clk, because we know
        // reset is not sampled there.
        if (!top->aclk) {
            if (contextp->time() > 1 && contextp->time() < 10) {
                top->aresetn = !1;
            } else {
                top->aresetn = !0;
            }
        }

        // Evaluate model
        // (If you have multiple models being simulated in the same
        // timestep then instead of eval(), call eval_step() on each, then
        // eval_end_step() on each. See the manual.)
        top->eval();

    }

    if (top->error_status_reg) {
        ret = 1;
    }

    // if (top->pc < 0x10174) {
        // ret = 1;
    // }

    // Final model cleanup
    top->final();

    if (!ret) VL_PRINTF("INFO: Verilator executed successfully\n");

    return ret;
}
