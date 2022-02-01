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
        // Express mode track the register usage and avoid wait state in control unit
        parameter EXPRESS_MODE      = 0,
        // Number of extension supported in processing unit
        parameter NB_UNIT           = 2,
        // Insert a pipeline on instruction bus coming from the controller
        parameter INST_BUS_PIPELINE = 0,
        // Internal FIFO depth, buffering the instruction to execute
        parameter INST_QUEUE_DEPTH  = 0
    )(
        // clock & reset
        input  logic                        aclk,
        input  logic                        aresetn,
        input  logic                        srst,
        // ALU instruction bus
        input  logic                        proc_valid,
        output logic                        proc_ready,
        input  logic [`INST_BUS_W     -1:0] proc_instbus,
        output logic [32              -1:0] proc_rsvd_regs,
        output logic [4               -1:0] proc_fenceinfo,
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

    ///////////////////////////////////////////////////////////////////////////
    //
    // Parameters and variables declaration
    //
    ///////////////////////////////////////////////////////////////////////////

    logic [`OPCODE_W       -1:0] opcode;
    logic [`FUNCT7_W       -1:0] funct7;
    logic [`RS1_W          -1:0] rs1;
    logic [`RS2_W          -1:0] rs2;
    logic [`RD_W           -1:0] rd;
    logic [`RD_W           -1:0] rd_pre;
    logic                        memfy_valid;
    logic                        alu_valid;
    logic                        m_valid;
    logic                        m_ready;
    logic                        alu_ready;
    logic                        memfy_ready;
    logic                        i_inst;
    logic                        ls_inst;
    logic                        m_inst;
    // Bus on pipline output
    logic                        proc_valid_p;
    logic                        proc_ready_p;
    logic [`INST_BUS_W     -1:0] proc_instbus_p;
    // Bus on FIFO output (optional)
    logic                        proc_valid_q;
    logic                        proc_ready_q;
    logic [`INST_BUS_W     -1:0] proc_instbus_q;
    logic [32              -1:0] proc_rsvd_regs_cnt[$clog2(INST_QUEUE_DEPTH)-1:0];

    // Assignment of M extension on integer registers' interface
    localparam M_IX = 2;

    // Number of integer registers really used based on RV32E arch
    localparam NB_INT_REG = (RV32E) ? 16 : 32;

    // Used to parse all the integer registers
    integer regi;
    // Used to parse all the integer registers' interfaces
    integer itfi;


    ///////////////////////////////////////////////////////////////////////////
    // Indicate to the control unit the integer registers under use
    ///////////////////////////////////////////////////////////////////////////

    generate

    if (EXPRESS_MODE) begin

        assign rd_pre = proc_instbus[`RD+:`RD_W];

        always @ (posedge aclk or negedge aresetn) begin
            if (!aresetn) begin
                for (regi=0;regi<NB_INT_REG;regi=regi+1) begin
                    proc_rsvd_regs_cnt[regi] <= 0;
                end
            end else if (srst) begin
                for (regi=0;regi<NB_INT_REG;regi=regi+1) begin
                    proc_rsvd_regs_cnt[regi] <= 0;
                end
            end else begin
                for (regi=0;regi<NB_INT_REG;regi=regi+1) begin
                    for (itfi=0;itfi<NB_UNIT;itfi=itfi+1) begin
                        // If new instruction will target this instruction, increment
                        if ((proc_valid && rd_pre==regi[4:0]) &&
                            ((proc_rd_wr[itfi] && proc_rd_addr[itfi]!=regi[4:0]) ||
                             &proc_rd_wr==1'b0)
                        ) begin
                            proc_rsvd_regs_cnt[regi] <= proc_rsvd_regs_cnt[regi] + 1;
                        // Else if releasing the register, decrement
                        end else if ((proc_valid && rd_pre!=regi[4:0]) &&
                            ((proc_rd_wr[itfi] && proc_rd_addr[itfi]==regi[4:0]) ||
                             &proc_rd_wr==1'b0)
                        ) begin
                            proc_rsvd_regs_cnt[regi] <= proc_rsvd_regs_cnt[regi] - 1;
                        end
                    end
                end
            end
        end
    end else begin
        assign proc_rsvd_regs = 32'b0;
    end
    endgenerate

    generate
    if (RV32E) begin
        assign proc_rsvd_regs[16+:16] = 16'b0;
    end
    endgenerate


    ///////////////////////////////////////////////////////////////////////////
    //
    // Instruction bus pipeline and extraction
    //
    ///////////////////////////////////////////////////////////////////////////

    generate
    // Insert a pipline stage to ease timing closure and placement
    if (INST_BUS_PIPELINE) begin

        friscv_pipeline
        #(
            .DATA_BUS_W  (`INST_BUS_W),
            .NB_PIPELINE (1)
        )
        inst_bus_pipeline
        (
            .aclk    (aclk),
            .aresetn (aresetn),
            .srst    (srst),
            .i_valid (proc_valid),
            .i_ready (proc_ready),
            .i_data  (proc_instbus),
            .o_valid (proc_valid_p),
            .o_ready (proc_ready_p),
            .o_data  (proc_instbus_p)
        );

    end else begin

        assign proc_instbus_p = proc_instbus;
        assign proc_valid_p = proc_valid;
        assign proc_ready = proc_ready_p;

    end
    endgenerate

    generate
    if (INST_QUEUE_DEPTH>0) begin: USE_QUEUE

        logic queue_full;
        logic queue_empty;

        friscv_scfifo
        #(
            .PASS_THRU  (0),
            .ADDR_WIDTH ($clog2(INST_QUEUE_DEPTH)),
            .DATA_WIDTH (`INST_BUS_W)
        )
        inst_bus_queue
        (
            .aclk     (aclk),
            .aresetn  (aresetn),
            .srst     (srst),
            .flush    (1'b0),
            .data_in  (proc_instbus_p),
            .push     (proc_valid_p),
            .full     (queue_full),
            .data_out (proc_instbus_q),
            .pull     (proc_ready_q),
            .empty    (queue_empty)
        );

        assign proc_ready_p = !queue_full;
        assign proc_valid_q = !queue_empty;

    end else begin: NO_QUEUE

        assign proc_instbus_q = proc_instbus_p;
        assign proc_valid_q = proc_valid_p;
        assign proc_ready_p = proc_ready_q;

    end
    endgenerate

    assign opcode = proc_instbus_p[`OPCODE +: `OPCODE_W];
    assign funct7 = proc_instbus_p[`FUNCT7 +: `FUNCT7_W];
    assign rs1    = proc_instbus_p[`RS1    +: `RS1_W   ];
    assign rs2    = proc_instbus_p[`RS2    +: `RS2_W   ];
    assign rd     = proc_instbus_p[`RD     +: `RD_W    ];


    ///////////////////////////////////////////////////////////////////////////
    //
    // Computation activation
    //
    ///////////////////////////////////////////////////////////////////////////

    assign i_inst = ((opcode==`R_ARITH && (funct7==7'b0000000 || funct7==7'b0100000)) ||
                      opcode==`I_ARITH
                    ) ? 1'b1 : 1'b0;

    assign ls_inst = (opcode==`LOAD || opcode==`STORE) ? 1'b1 : 1'b0;

    assign m_inst = (opcode==`MULDIV && funct7==7'b0000001) ? 1'b1 : 1'b0;

    assign alu_valid = proc_valid_q & memfy_ready & m_ready & i_inst;
    assign memfy_valid = proc_valid_q & alu_ready & m_ready & ls_inst;
    assign m_valid = proc_valid_q & alu_ready & memfy_ready & m_inst;

    assign proc_ready_q = alu_ready & memfy_ready & m_ready;


    ///////////////////////////////////////////////////////////////////////////
    //
    // Instances
    //
    ///////////////////////////////////////////////////////////////////////////

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
        .alu_instbus   (proc_instbus_q),
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
        .memfy_instbus   (proc_instbus_q),
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

    generate

    if (M_EXTENSION) begin: M_EXTENSION_SUPPORT

    friscv_m_ext
    #(
        .XLEN (XLEN)
    )
    m_ext
    (
        .aclk       (aclk),
        .aresetn    (aresetn),
        .srst       (srst),
        .m_valid    (m_valid),
        .m_ready    (m_ready),
        .m_instbus  (proc_instbus_q),
        .m_rs1_addr (proc_rs1_addr[M_IX*5+:5]),
        .m_rs1_val  (proc_rs1_val[M_IX*XLEN+:XLEN]),
        .m_rs2_addr (proc_rs2_addr[M_IX*5+:5]),
        .m_rs2_val  (proc_rs2_val[M_IX*XLEN+:XLEN]),
        .m_rd_wr    (proc_rd_wr[M_IX]),
        .m_rd_addr  (proc_rd_addr[M_IX*5+:5]),
        .m_rd_val   (proc_rd_val[M_IX*XLEN+:XLEN]),
        .m_rd_strb  (proc_rd_strb[M_IX*XLEN/8+:XLEN/8])
    );

    end else begin: NO_M_EXTENSION

        assign m_ready = 1'b1;

    end
    endgenerate

endmodule

`resetall
