// distributed under the mit license
// https://opensource.org/licenses/mit-license.php

`timescale 1 ns / 1 ps
`default_nettype none

`include "friscv_h.sv"

module friscv_processing

    #(
        // Architecture selection:
        // 32 or 64 bits support
        parameter XLEN              = 32,
        // Floating-point extension support
        parameter F_EXTENSION       = 0,
        // Multiply/Divide extension support
        parameter M_EXTENSION       = 0,
        // Reduced RV32 arch
        parameter RV32E             = 0,
        // Address bus width defined for both control and AXI4 address signals
        parameter AXI_ADDR_W        = XLEN,
        // AXI ID width, setup by default to 8 and unused
        parameter AXI_ID_W          = 8,
        // AXI4 data width, for instruction and a data bus
        parameter AXI_DATA_W        = XLEN,
        // ID used to identify the dta abus in the infrastructure
        parameter AXI_ID_MASK       = 'h20,
        // Number of extension supported in processing unit
        parameter NB_UNIT           = 2
    )(
        // clock & reset
        input  logic                        aclk,
        input  logic                        aresetn,
        input  logic                        srst,
        // ALU instruction bus
        input  logic                        proc_valid,
        output logic                        proc_ready,
        output logic                        proc_empty,
        output logic [4               -1:0] proc_fenceinfo,
        input  logic [`INST_BUS_W     -1:0] proc_instbus,
        // ISA registers interface
        output logic [NB_UNIT*5       -1:0] proc_rs1_addr,
        input  logic [NB_UNIT*XLEN    -1:0] proc_rs1_val,
        output logic [NB_UNIT*5       -1:0] proc_rs2_addr,
        input  logic [NB_UNIT*XLEN    -1:0] proc_rs2_val,
        output logic [NB_UNIT         -1:0] proc_rd_wr,
        output logic [NB_UNIT*5       -1:0] proc_rd_addr,
        output logic [NB_UNIT*XLEN    -1:0] proc_rd_val,
        output logic [NB_UNIT*XLEN/8  -1:0] proc_rd_strb,
        // data memory interface
        output logic                        awvalid,
        input  logic                        awready,
        output logic [AXI_ADDR_W      -1:0] awaddr,
        output logic [3               -1:0] awprot,
        output logic [AXI_ID_W        -1:0] awid,
        output logic                        wvalid,
        input  logic                        wready,
        output logic [AXI_DATA_W      -1:0] wdata,
        output logic [AXI_DATA_W/8    -1:0] wstrb,
        input  logic                        bvalid,
        output logic                        bready,
        input  logic [AXI_ID_W        -1:0] bid,
        input  logic [2               -1:0] bresp,
        output logic                        arvalid,
        input  logic                        arready,
        output logic [AXI_ADDR_W      -1:0] araddr,
        output logic [3               -1:0] arprot,
        output logic [AXI_ID_W        -1:0] arid,
        input  logic                        rvalid,
        output logic                        rready,
        input  logic [AXI_ID_W        -1:0] rid,
        input  logic [2               -1:0] rresp,
        input  logic [AXI_DATA_W      -1:0] rdata
    );

    logic memfy_valid;
    logic alu_valid;
    logic alu_ready;
    logic alu_empty;
    logic memfy_ready;
    logic memfy_empty;

    assign alu_valid = proc_valid & memfy_ready;
    assign memfy_valid = proc_valid & alu_ready;
    assign proc_ready = alu_ready & memfy_ready;
    assign proc_empty = 1'b0;


    friscv_alu
    #(
        .XLEN (XLEN)
    )
    alu
    (
        .aclk          (aclk),
        .aresetn       (aresetn),
        .srst          (srst),
        .alu_valid     (alu_valid),
        .alu_ready     (alu_ready),
        .alu_instbus   (proc_instbus),
        .alu_rs1_addr  (proc_rs1_addr[0*5+:5]),
        .alu_rs1_val   (proc_rs1_val[0*XLEN+:XLEN]),
        .alu_rs2_addr  (proc_rs2_addr[0*5+:5]),
        .alu_rs2_val   (proc_rs2_val[0*XLEN+:XLEN]),
        .alu_rd_wr     (proc_rd_wr[0]),
        .alu_rd_addr   (proc_rd_addr[0*5+:5]),
        .alu_rd_val    (proc_rd_val[0*XLEN+:XLEN]),
        .alu_rd_strb   (proc_rd_strb[0*XLEN/8+:XLEN/8])
    );


    friscv_memfy
    #(
        .XLEN         (XLEN),
        .AXI_ADDR_W   (AXI_ADDR_W),
        .AXI_ID_W     (AXI_ID_W),
        .AXI_DATA_W   (AXI_DATA_W),
        .AXI_ID_MASK  (AXI_ID_MASK)
    )
    memfy
    (
        .aclk            (aclk),
        .aresetn         (aresetn),
        .srst            (srst),
        .memfy_valid     (memfy_valid),
        .memfy_ready     (memfy_ready),
        .memfy_fenceinfo (proc_fenceinfo),
        .memfy_instbus   (proc_instbus),
        .memfy_rs1_addr  (proc_rs1_addr[1*5+:5]),
        .memfy_rs1_val   (proc_rs1_val[1*XLEN+:XLEN]),
        .memfy_rs2_addr  (proc_rs2_addr[1*5+:5]),
        .memfy_rs2_val   (proc_rs2_val[1*XLEN+:XLEN]),
        .memfy_rd_wr     (proc_rd_wr[1]),
        .memfy_rd_addr   (proc_rd_addr[1*5+:5]),
        .memfy_rd_val    (proc_rd_val[1*XLEN+:XLEN]),
        .memfy_rd_strb   (proc_rd_strb[1*XLEN/8+:XLEN/8]),
        .awvalid         (awvalid),
        .awready         (awready),
        .awaddr          (awaddr),
        .awprot          (awprot),
        .awid            (awid),
        .wvalid          (wvalid),
        .wready          (wready),
        .wdata           (wdata),
        .wstrb           (wstrb),
        .bvalid          (bvalid),
        .bready          (bready),
        .bid             (bid),
        .bresp           (bresp),
        .arvalid         (arvalid),
        .arready         (arready),
        .araddr          (araddr),
        .arprot          (arprot),
        .arid            (arid),
        .rvalid          (rvalid),
        .rready          (rready),
        .rid             (rid),
        .rresp           (rresp),
        .rdata           (rdata)
    );


endmodule

`resetall

