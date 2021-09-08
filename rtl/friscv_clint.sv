// distributed under the mit license
// https://opensource.org/licenses/mit-license.php

`timescale 1 ns / 1 ps
`default_nettype none

`include "svlogger.sv"
`include "friscv_h.sv"


///////////////////////////////////////////////////////////////////////////////
// Clint controller (Core Local Interrupt Controller), implementing next CSRs:
//   - mtime / mtimecmp (machine time registers)
//   - mie / mip (machine interrupt registers)
///////////////////////////////////////////////////////////////////////////////


module friscv_clint

    #(
        // Architecture setup
        parameter XLEN = 32
    )(
        // clock & reset
        input  logic        aclk,
        input  logic        aresetn,
        input  logic        srst,
        // real-time clock, shared across the harts
        input  logic        rtc,
        // software interrupt 
        output logic        sw_irq,
        // timer interrupt 
        output logic        timer_irq
    );

    assign sw_irq = 1'b0;
    assign timer_irq = 1'b0;

endmodule

`resetall

