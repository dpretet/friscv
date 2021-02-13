// copyright damien pretet 2021
// distributed under the mit license
// https://opensource.org/licenses/mit-license.php

`timescale 1 ns / 1 ps
`default_nettype none

module friscv_rv64i

    #(
        parameter             ADDRW     = 16,
        parameter [ADDRW-1:0] BOOT_ADDR = {ADDRW{1'b0}},
        parameter             XLEN      = 64
    )(
        // clock/reset interface
        input  wire               aclk,
        input  wire               aresetn,
        input  wire               srst,
        // enable signal to activate the core
        input  wire               enable,
        // instruction memory interface
        output logic              inst_en,
        output logic [ADDRW -1:0] inst_addr,
        input  wire  [XLEN  -1:0] inst_rdata,
        input  wire               inst_ready,
        // data memory interface
        output logic              mem_en,
        output logic              mem_wr,
        output logic [ADDRW -1:0] mem_addr,
        output logic [XLEN  -1:0] mem_wdata,
        output logic [XLEN/8-1:0] mem_strb,
        input  wire  [XLEN  -1:0] mem_rdata,
        input  wire               mem_ready
    );


    logic [5   -1:0] rs1_addr;
    logic [XLEN-1:0] rs1_val;
    logic [5   -1:0] rs2_addr;
    logic [XLEN-1:0] rs2_val;
    logic            rd_wr;
    logic [5   -1:0] rd_addr;
    logic [XLEN-1:0] rd_val;
    logic [XLEN-1:0] x0;
    logic [XLEN-1:0] x1;
    logic [XLEN-1:0] x2;
    logic [XLEN-1:0] x3;
    logic [XLEN-1:0] x4;
    logic [XLEN-1:0] x5;
    logic [XLEN-1:0] x6;
    logic [XLEN-1:0] x7;
    logic [XLEN-1:0] x8;
    logic [XLEN-1:0] x9;
    logic [XLEN-1:0] x10;
    logic [XLEN-1:0] x11;
    logic [XLEN-1:0] x12;
    logic [XLEN-1:0] x13;
    logic [XLEN-1:0] x14;
    logic [XLEN-1:0] x15;
    logic [XLEN-1:0] x16;
    logic [XLEN-1:0] x17;
    logic [XLEN-1:0] x18;
    logic [XLEN-1:0] x19;
    logic [XLEN-1:0] x20;
    logic [XLEN-1:0] x21;
    logic [XLEN-1:0] x22;
    logic [XLEN-1:0] x23;
    logic [XLEN-1:0] x24;
    logic [XLEN-1:0] x25;
    logic [XLEN-1:0] x26;
    logic [XLEN-1:0] x27;
    logic [XLEN-1:0] x28;
    logic [XLEN-1:0] x29;
    logic [XLEN-1:0] x30;
    logic [XLEN-1:0] x31;


    registers 
    #(
    .XLEN (XLEN)
    )
    registers 
    (
    .aclk     (aclk    ),
    .aresetn  (aresetn ),
    .srst     (srst    ),
    .rs1_addr (rs1_addr),
    .rs1_val  (rs1_val ),
    .rs2_addr (rs2_addr),
    .rs2_val  (rs2_val ),
    .rd_wr    (rd_wr   ),
    .rd_addr  (rd_addr ),
    .rd_val   (rd_val  ),
    .x0       (x0      ),
    .x1       (x1      ),
    .x2       (x2      ),
    .x3       (x3      ),
    .x4       (x4      ),
    .x5       (x5      ),
    .x6       (x6      ),
    .x7       (x7      ),
    .x8       (x8      ),
    .x9       (x9      ),
    .x10      (x10     ),
    .x11      (x11     ),
    .x12      (x12     ),
    .x13      (x13     ),
    .x14      (x14     ),
    .x15      (x15     ),
    .x16      (x16     ),
    .x17      (x17     ),
    .x18      (x18     ),
    .x19      (x19     ),
    .x20      (x20     ),
    .x21      (x21     ),
    .x22      (x22     ),
    .x23      (x23     ),
    .x24      (x24     ),
    .x25      (x25     ),
    .x26      (x26     ),
    .x27      (x27     ),
    .x28      (x28     ),
    .x29      (x29     ),
    .x30      (x30     ),
    .x31      (x31     )
    );

endmodule

`resetall
