// distributed under the mit license
// https://opensource.org/licenses/mit-license.php

`timescale 1 ns / 1 ps
`default_nettype none

`include "friscv_h.sv"

module friscv_processing

    #(
        // Architecture selection
        parameter XLEN              = 32,
        // Address bus width defined for both control and AXI4 address signals
        parameter AXI_ADDR_W        = XLEN,
        // AXI ID width, setup by default to 8 and unused
        parameter AXI_ID_W          = 8,
        // AXI4 data width, for instruction and a data bus
        parameter AXI_DATA_W        = XLEN,
        // ID used to identify the dta abus in the infrastructure
        parameter AXI_ID_MASK       = 'h20
    )(
        // clock & reset
        input  logic                        aclk,
        input  logic                        aresetn,
        input  logic                        srst,
        // ALU instruction bus
        input  logic                        proc_en,
        output logic                        proc_ready,
        output logic                        proc_empty,
        output logic [4               -1:0] proc_fenceinfo,
        input  logic [`INST_BUS_W     -1:0] proc_instbus,
        // register source 1 query interface
        output logic [5               -1:0] alu_rs1_addr,
        input  logic [XLEN            -1:0] alu_rs1_val,
        // register source 2 for query interface
        output logic [5               -1:0] alu_rs2_addr,
        input  logic [XLEN            -1:0] alu_rs2_val,
        // register estination for query interface
        output logic                        alu_rd_wr,
        output logic [5               -1:0] alu_rd_addr,
        output logic [XLEN            -1:0] alu_rd_val,
        output logic [XLEN/8          -1:0] alu_rd_strb,
        // register source 1 query interface
        output logic [5               -1:0] memfy_rs1_addr,
        input  logic [XLEN            -1:0] memfy_rs1_val,
        // register source 2 for query interface
        output logic [5               -1:0] memfy_rs2_addr,
        input  logic [XLEN            -1:0] memfy_rs2_val,
        // register estination for query interface
        output logic                        memfy_rd_wr,
        output logic [5               -1:0] memfy_rd_addr,
        output logic [XLEN            -1:0] memfy_rd_val,
        output logic [XLEN/8          -1:0] memfy_rd_strb,
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

    logic memfy_en;
    logic alu_en;
    logic alu_ready;
    logic alu_empty;
    logic memfy_ready;
    logic memfy_empty;

    assign alu_en = proc_en & memfy_ready;

    friscv_alu
    #(
        .XLEN (XLEN)
    )
    alu
    (
        .aclk          (aclk),
        .aresetn       (aresetn),
        .srst          (srst),
        .alu_en        (alu_en),
        .alu_ready     (alu_ready),
        .alu_empty     (alu_empty),
        .alu_instbus   (proc_instbus),
        .alu_rs1_addr  (alu_rs1_addr),
        .alu_rs1_val   (alu_rs1_val),
        .alu_rs2_addr  (alu_rs2_addr),
        .alu_rs2_val   (alu_rs2_val),
        .alu_rd_wr     (alu_rd_wr),
        .alu_rd_addr   (alu_rd_addr),
        .alu_rd_val    (alu_rd_val),
        .alu_rd_strb   (alu_rd_strb)
    );

    assign memfy_en = proc_en & alu_ready;

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
        .memfy_en        (memfy_en),
        .memfy_ready     (memfy_ready),
        .memfy_empty     (memfy_empty),
        .memfy_fenceinfo (proc_fenceinfo),
        .memfy_instbus   (proc_instbus),
        .memfy_rs1_addr  (memfy_rs1_addr),
        .memfy_rs1_val   (memfy_rs1_val),
        .memfy_rs2_addr  (memfy_rs2_addr),
        .memfy_rs2_val   (memfy_rs2_val),
        .memfy_rd_wr     (memfy_rd_wr),
        .memfy_rd_addr   (memfy_rd_addr),
        .memfy_rd_val    (memfy_rd_val),
        .memfy_rd_strb   (memfy_rd_strb),
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


    assign proc_ready = alu_ready & memfy_ready;
    assign proc_empty = alu_empty & memfy_empty;


endmodule

`resetall

