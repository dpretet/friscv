// distributed under the mit license
// https://opensource.org/licenses/mit-license.php

#include "build/Vfriscv_testbench.h"
// For std::unique_ptr
#include <memory>
// Include common routines
#include <verilated.h>
#include <iostream>
#include <thread>
#include <fstream>

#include <string.h>

using namespace std;
#define MAX_CHAR 80

#define STATUS_ADDR 0
#define RX_FIFO_ADDR 12
#define TX_FIFO_ADDR 8
#define RX_EMPTY_BIT 11
#define TX_FULL_BIT 10

#define TX_TIMER_ON 500

// ASCII code for End Of Transmission
#define EOT 4
// Maximum file line we can handle
#define MAX_FILE_LINE 1024
#define COMMENT 35

// Legacy function required only so linking works on Cygwin and MSVC++
double sc_time_stamp() { return 0; }


bool fileExists(const char* fileName)
{
  std::ifstream test(fileName);
  return (test) ? true : false;
}


int main(int argc, char** argv, char** env) {

    int ret = 0;
    int can_write = 0;
    int rxfifo_empty = 0;
    int txfifo_full = 0;
    std::string cin_str;
    std::string cmd_line;
    std::string file_lines[MAX_FILE_LINE];
    int current_line = 0;
    int num_lines = 0;
    setbuf(stdout, NULL);
    int str_ix = 0;
    int str_size = 0;
    int txtimer = 0;
    int reading_script = 0;

    enum State {IDLE = 0, STATUS = 1, READ = 2, WRITE = 3};
    int uart_fsm = IDLE;

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

    // Testbench IOs initialization
    top->aclk = 0;
    top->aresetn = 0;
    top->srst = 0;
    top->slv_en = 0;
    top->slv_wr = 0;
    top->slv_addr = 0;
    top->slv_wdata = 'a';
    top->slv_strb = 0;

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
            if (contextp->time() > 0 && contextp->time() < 10) {
                top->aresetn = 0;
            } else {
                top->aresetn = 1;
            }
        }

        if (!top->aclk && top->aresetn) {

            txtimer += 1;

            switch (uart_fsm) {

                // IDLE state, switching between read/write
                case IDLE:

                    top->slv_en = 1;
                    top->slv_wr = 0;
                    top->slv_addr = STATUS_ADDR;
                    top->slv_strb = 0;
                    top->slv_wdata = 0;
                    uart_fsm = STATUS;
                    break;


                // Read UART Control/Status register
                case STATUS:

                    if (top->slv_ready) {

                        top->slv_en = 0;
                        top->slv_wr = 0;

                        // Check if RX FIFO has been filled
                        rxfifo_empty = top->slv_rdata;
                        rxfifo_empty = rxfifo_empty >> RX_EMPTY_BIT;
                        rxfifo_empty = rxfifo_empty & 0x1;

                        // Check if TX FIFO is available
                        txfifo_full = top->slv_rdata;
                        txfifo_full = txfifo_full >> TX_FULL_BIT;
                        txfifo_full = txfifo_full & 0x1;

                        if (!rxfifo_empty) {
                            top->slv_addr = RX_FIFO_ADDR;
                            top->slv_strb = 0;
                            top->slv_wdata = 0;
                            uart_fsm = READ;
                            break;

                        } else if (!txfifo_full && reading_script && can_write) {

                            current_line += 1;

                            // Reaching the end of the script
                            if (current_line==num_lines) {
                                uart_fsm = IDLE;
                                reading_script = 0;
                                current_line = 0;
                                num_lines = 0;
                                break;

                            // Moving to next line
                            } else {

                                // A flag used in READ to insert or not a new prompt
                                if (current_line==(num_lines-1))
                                    reading_script = 0;

                                // Load a new line/commmand and prepare it
                                cmd_line = file_lines[current_line];
                                str_size = cmd_line.size();
                                str_ix = 0;

                                // If the line is not empty, continue transmission
                                if (str_size > 0) {
                                    // print the command and load the UART interface
                                    cout << cmd_line << endl;
                                    top->slv_addr = TX_FIFO_ADDR;
                                    top->slv_strb = 15;
                                    top->slv_wdata = cmd_line[0];
                                    uart_fsm = WRITE;
                                    break;
                                // If not filled with a command, move to the next line
                                } else {
                                    uart_fsm = STATUS;
                                    break;
                                }
                            }

                        // Prevent transmission as long the ore didn't send a new prompt (EOT)
                        // txtimer prevent to read CIN too often, which slow the simulation
                        } else if (!txfifo_full && !reading_script && can_write && txtimer==TX_TIMER_ON) {

                            if (std::cin.rdbuf() && std::cin.rdbuf()->in_avail() >= 0) {

                                std::getline(std::cin, cin_str);

                                // cast string to const char * to check the string is a valid path
                                if (fileExists(cin_str.c_str())) {

                                    reading_script = 1;
                                    cout << "Executing " << cin_str << endl;

                                    int i = 0;
                                    std::ifstream file(cin_str.c_str());
                                    if (file.is_open()) {
                                        while (std::getline(file, file_lines[i])) {
                                            i++;
                                        }
                                        file.close();

                                    }
                                    num_lines = i;
                                    cmd_line = file_lines[0];
                                    cout << cmd_line << endl;
                                } else {
                                    cmd_line = cin_str;
                                }

                                str_size = cmd_line.size();
                                str_ix = 0;
                                if (str_size > 0) {
                                    top->slv_addr = TX_FIFO_ADDR;
                                    top->slv_strb = 15;
                                    top->slv_wdata = cmd_line[0];
                                    uart_fsm = WRITE;
                                } else {
                                    uart_fsm = IDLE;
                                }
                                break;
                            } else {
                                uart_fsm = IDLE;
                                break;
                            }

                        } else {
                            uart_fsm = IDLE;
                            break;
                        }
                    }

                // Read UART RX FIFO
                case READ:
                    top->slv_en = 1;
                    if (top->slv_ready) {


                        // Waits for End Of Transmission to send again a command
                        if (top->slv_rdata==EOT) {
                            // If not parsing/passing a script, print a new prompt
                            if (!reading_script)
                                cout << endl << "> ";
                            // else simply insert a new line
                            else
                                cout << endl;
                            can_write = 1;
                        } else {
                            cout << static_cast<char>(top->slv_rdata);
                            can_write = 0;
                        }

                        top->slv_en = 0;
                        top->slv_wr = 0;
                        top->slv_strb = 0;
                        top->slv_wdata = 0;
                        uart_fsm = IDLE;
                        break;
                    }

                // Write UART TX FIFO
                case WRITE:

                    top->slv_en = 1;
                    top->slv_wr = 1;

                    if (top->slv_ready) {

                        top->slv_en = 0;
                        str_ix += 1;
                        top->slv_wdata = cmd_line[str_ix];

                        // Once reach the end of line or a comment, insert "End of Transmission"
                        // We never send neither read <CR>, so EOT is mandatory for the core
                        if (str_ix == str_size || top->slv_wdata==COMMENT)
                            top->slv_wdata = EOT;

                        // Once reach end of line and EOT is transmitted, stop to write
                        if (str_ix > str_size || top->slv_wdata==COMMENT) {
                            top->slv_en = 0;
                            top->slv_wr = 0;
                            top->slv_strb = 0;
                            uart_fsm = IDLE;
                            can_write = 0;
                            break;
                        } else {
                            break;
                        }
                    }
            }
        }

        // Evaluate model
        // (If you have multiple models being simulated in the same
        // timestep then instead of eval(), call eval_step() on each, then
        // eval_end_step() on each. See the manual.)
        top->eval();

        if (txtimer>TX_TIMER_ON) txtimer = 0;
    }

    if (top->error_status_reg) {
        ret = 1;
    }

    // if (top->pc < 0x10174) {
        // ret = 1;
    // }

    // Final model cleanup
    top->final();

    if (!ret)
        VL_PRINTF("INFO: Verilator executed successfully\n");
    else
        VL_PRINTF("ERROR: Verilator failed\n");

    return ret;
}
