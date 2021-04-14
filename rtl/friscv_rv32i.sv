// copyright damien pretet 2021
// distributed under the mit license
// https://opensource.org/licenses/mit-license.php

`timescale 1 ns / 1 ps
`default_nettype none

`define RV32I
`include "friscv_h.sv"

module friscv_rv32i

    #(
        parameter                  INST_ADDRW = 16,
        parameter                  DATA_ADDRW = 16,
        parameter [INST_ADDRW-1:0] BOOT_ADDR  = {INST_ADDRW{1'b0}},
        parameter                  XLEN       = 32
    )(
        // clock/reset interface
        input  logic                  aclk,
        input  logic                  aresetn,
        input  logic                  srst,
        // enable signal to activate the core
        input  logic                  enable,
        // instruction memory interface
        output logic                  inst_en,
        output logic [INST_ADDRW-1:0] inst_addr,
        input  logic [XLEN      -1:0] inst_rdata,
        input  logic                  inst_ready,
        // data memory interface
        output logic                  mem_en,
        output logic                  mem_wr,
        output logic [DATA_ADDRW-1:0] mem_addr,
        output logic [XLEN      -1:0] mem_wdata,
        output logic [XLEN/8    -1:0] mem_strb,
        input  logic [XLEN      -1:0] mem_rdata,
        input  logic                  mem_ready
    );

    logic [5   -1:0] ctrl_rs1_addr;
    logic [XLEN-1:0] ctrl_rs1_val;
    logic [5   -1:0] ctrl_rs2_addr;
    logic [XLEN-1:0] ctrl_rs2_val;
    logic            ctrl_rd_wr;
    logic [5   -1:0] ctrl_rd_addr;
    logic [XLEN-1:0] ctrl_rd_val;

    logic [5   -1:0] alu_rs1_addr;
    logic [XLEN-1:0] alu_rs1_val;
    logic [5   -1:0] alu_rs2_addr;
    logic [XLEN-1:0] alu_rs2_val;
    logic            alu_rd_wr;
    logic [5   -1:0] alu_rd_addr;
    logic [XLEN-1:0] alu_rd_val;

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

    logic                      alu_en;
    logic                      alu_ready;
    logic                      alu_empty;
    logic [`ALU_INSTBUS_W-1:0] alu_instbus;


    friscv_rv32i_control
    #(
    .ADDRW     (INST_ADDRW),
    .BOOT_ADDR (BOOT_ADDR),
    .XLEN      (XLEN)
    )
    control_unit
    (
    .aclk          (aclk         ),
    .aresetn       (aresetn      ),
    .srst          (srst         ),
    .inst_en       (inst_en      ),
    .inst_addr     (inst_addr    ),
    .inst_rdata    (inst_rdata   ),
    .inst_ready    (inst_ready   ),
    .alu_en        (alu_en       ),
    .alu_ready     (alu_ready    ),
    .alu_empty     (alu_empty    ),
    .alu_instbus   (alu_instbus  ),
    .ctrl_rs1_addr (ctrl_rs1_addr),
    .ctrl_rs1_val  (ctrl_rs1_val ),
    .ctrl_rs2_addr (ctrl_rs2_addr),
    .ctrl_rs2_val  (ctrl_rs2_val ),
    .ctrl_rd_wr    (ctrl_rd_wr   ),
    .ctrl_rd_addr  (ctrl_rd_addr ),
    .ctrl_rd_val   (ctrl_rd_val  )
    );


    friscv_rv32i_alu
    #(
    .ADDRW     (DATA_ADDRW),
    .XLEN      (XLEN)
    )
    alu
    (
    .aclk          (aclk        ),
    .aresetn       (aresetn     ),
    .srst          (srst        ),
    .alu_en        (alu_en      ),
    .alu_ready     (alu_ready   ),
    .alu_empty     (alu_empty   ),
    .alu_instbus   (alu_instbus ),
    .alu_rs1_addr  (alu_rs1_addr),
    .alu_rs1_val   (alu_rs1_val ),
    .alu_rs2_addr  (alu_rs2_addr),
    .alu_rs2_val   (alu_rs2_val ),
    .alu_rd_wr     (alu_rd_wr   ),
    .alu_rd_addr   (alu_rd_addr ),
    .alu_rd_val    (alu_rd_val  ),
    .mem_en        (mem_en      ),
    .mem_wr        (mem_wr      ),
    .mem_addr      (mem_addr    ),
    .mem_wdata     (mem_wdata   ),
    .mem_strb      (mem_strb    ),
    .mem_rdata     (mem_rdata   ),
    .mem_ready     (mem_ready   )
    );


    friscv_registers
    #(
    .XLEN (XLEN)
    )
    isa_registers
    (
    .aclk          (aclk         ),
    .aresetn       (aresetn      ),
    .srst          (srst         ),
    .ctrl_rs1_addr (ctrl_rs1_addr),
    .ctrl_rs1_val  (ctrl_rs1_val ),
    .ctrl_rs2_addr (ctrl_rs2_addr),
    .ctrl_rs2_val  (ctrl_rs2_val ),
    .ctrl_rd_wr    (ctrl_rd_wr   ),
    .ctrl_rd_addr  (ctrl_rd_addr ),
    .ctrl_rd_val   (ctrl_rd_val  ),
    .alu_rs1_addr  (alu_rs1_addr ),
    .alu_rs1_val   (alu_rs1_val  ),
    .alu_rs2_addr  (alu_rs2_addr ),
    .alu_rs2_val   (alu_rs2_val  ),
    .alu_rd_wr     (alu_rd_wr    ),
    .alu_rd_addr   (alu_rd_addr  ),
    .alu_rd_val    (alu_rd_val   ),
    .x0            (x0           ),
    .x1            (x1           ),
    .x2            (x2           ),
    .x3            (x3           ),
    .x4            (x4           ),
    .x5            (x5           ),
    .x6            (x6           ),
    .x7            (x7           ),
    .x8            (x8           ),
    .x9            (x9           ),
    .x10           (x10          ),
    .x11           (x11          ),
    .x12           (x12          ),
    .x13           (x13          ),
    .x14           (x14          ),
    .x15           (x15          ),
    .x16           (x16          ),
    .x17           (x17          ),
    .x18           (x18          ),
    .x19           (x19          ),
    .x20           (x20          ),
    .x21           (x21          ),
    .x22           (x22          ),
    .x23           (x23          ),
    .x24           (x24          ),
    .x25           (x25          ),
    .x26           (x26          ),
    .x27           (x27          ),
    .x28           (x28          ),
    .x29           (x29          ),
    .x30           (x30          ),
    .x31           (x31          )
    );

endmodule

`resetall
