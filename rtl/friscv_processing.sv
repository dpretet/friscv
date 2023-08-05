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
        parameter NB_UNIT           = 2,
        parameter MAX_UNIT          = 4,
        // Insert a pipeline on instruction bus coming from the controller
        parameter INST_BUS_PIPELINE = 0,
        // Internal FIFO depth, buffering the instruction to execute (UNUSED)
        parameter INST_QUEUE_DEPTH  = 0,
        // Number of outstanding requests used by the LOAD/STORE unit
        parameter DATA_OSTDREQ_NUM  = 8,
        // Select the ordering scheme:
        //   - 0: ongoing reads block write request, ongoing writes block read request
        //   - 1: concurrent r/w requests can be issued if don't target same cache blocks
        parameter AXI_ORDERING = 0,
        // Block width defining only the data payload, in bits, must an
        // integer multiple of XLEN (power of two)
        parameter DCACHE_BLOCK_W = XLEN*4,
        // IO regions for direct read/write access
        parameter IO_MAP_NB = 1,
        // IO address ranges, organized by memory region as END-ADDR_START-ADDR:
        // > 0xEND-MEM2_START-MEM2_END-MEM1_START-MEM1_END-MEM0_START-MEM0
        // IO mapping can be contiguous or sparse, no restriction on the number,
        // the size or the range if it fits into the XLEN addressable space
        parameter [XLEN*2*IO_MAP_NB-1:0] IO_MAP = 64'h001000FF_00100000
    )(
        // clock & reset
        input  wire                         aclk,
        input  wire                         aresetn,
        input  wire                         srst,
        // ALU instruction bus
        input  wire                         proc_valid,
        output logic                        proc_ready,
        input  wire  [`INST_BUS_W     -1:0] proc_instbus,
        output logic [4               -1:0] proc_fenceinfo,
        output logic                        proc_busy,
        output logic [2               -1:0] proc_exceptions,
        // ISA registers interface
        output logic [NB_UNIT*5       -1:0] proc_rs1_addr,
        input  wire  [NB_UNIT*XLEN    -1:0] proc_rs1_val,
        output logic [NB_UNIT*5       -1:0] proc_rs2_addr,
        input  wire  [NB_UNIT*XLEN    -1:0] proc_rs2_val,
        output logic [NB_UNIT         -1:0] proc_rd_wr,
        output logic [NB_UNIT*5       -1:0] proc_rd_addr,
        output logic [NB_UNIT*XLEN    -1:0] proc_rd_val,
        output logic [NB_UNIT*XLEN/8  -1:0] proc_rd_strb,
        // data memory interface
        output logic                        awvalid,
        input  wire                         awready,
        output logic [AXI_ADDR_W      -1:0] awaddr,
        output logic [3               -1:0] awprot,
        output logic [4               -1:0] awcache,
        output logic [AXI_ID_W        -1:0] awid,
        output logic                        wvalid,
        input  wire                         wready,
        output logic [AXI_DATA_W      -1:0] wdata,
        output logic [AXI_DATA_W/8    -1:0] wstrb,
        input  wire                         bvalid,
        output logic                        bready,
        input  wire  [AXI_ID_W        -1:0] bid,
        input  wire  [2               -1:0] bresp,
        output logic                        arvalid,
        input  wire                         arready,
        output logic [AXI_ADDR_W      -1:0] araddr,
        output logic [3               -1:0] arprot,
        output logic [4               -1:0] arcache,
        output logic [AXI_ID_W        -1:0] arid,
        input  wire                         rvalid,
        output logic                        rready,
        input  wire  [AXI_ID_W        -1:0] rid,
        input  wire  [2               -1:0] rresp,
        input  wire  [AXI_DATA_W      -1:0] rdata
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

    logic                        alu_valid;
    logic                        alu_ready;
    logic                        i_inst;
    logic                        memfy_hzd_free;
    logic                        m_hzd_free;
    logic                        hzd_free;

    logic                        m_valid;
    logic                        m_ready;
    logic                        m_inst;
    logic [NB_INT_REG      -1:0] m_regs_sts;
    logic                        div_pending;

    logic                        memfy_valid;
    logic                        memfy_ready;
    logic                        memfy_pending_read;
    logic                        memfy_pending_write;
    logic [NB_INT_REG      -1:0] memfy_regs_sts;
    logic                        ls_inst;

    logic                        proc_valid_p;
    logic                        proc_ready_p;
    logic [`INST_BUS_W     -1:0] proc_instbus_p;
    logic                        proc_busy_r;

    logic [2               -1:0] memfy_exceptions;


    // Assignment of M extension on integer registers' interface
    localparam M_IX = 2;

    // Number of integer registers really used based on RV32E arch
    localparam NB_INT_REG = (RV32E) ? 16 : 32;


    ///////////////////////////////////////////////////////////////////////////
    //
    // Instruction bus pipeline
    //
    ///////////////////////////////////////////////////////////////////////////

    generate
    // Insert a pipline stage to ease timing closure and placement
    if (INST_BUS_PIPELINE) begin: INPUT_PIPELINE_ON

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

        always @ (posedge aclk or negedge aresetn) begin
            if (!aresetn) begin
                proc_busy_r <= 1'b0;
            end else if (srst) begin
                proc_busy_r <= 1'b0;
            end else begin
                if (proc_valid || memfy_pending_read || div_pending) begin
                    proc_busy_r <= 1'b1;
                end else if (!proc_valid_p && proc_ready_p) begin
                    proc_busy_r <= 1'b0;
                end
            end
        end

        assign proc_busy = proc_busy_r | memfy_pending_read | div_pending;

    end else begin: INPUT_PIPELINE_OFF

        assign proc_instbus_p = proc_instbus;
        assign proc_valid_p = proc_valid;
        assign proc_ready = proc_ready_p;

        assign proc_busy = !proc_ready || memfy_pending_read;
        assign proc_busy_r = 1'b0;

    end
    endgenerate


    assign opcode = proc_instbus_p[`OPCODE +: `OPCODE_W];
    assign funct7 = proc_instbus_p[`FUNCT7 +: `FUNCT7_W];
    assign rs1    = proc_instbus_p[`RS1    +: `RS1_W   ];
    assign rs2    = proc_instbus_p[`RS2    +: `RS2_W   ];
    assign rd     = proc_instbus_p[`RD     +: `RD_W    ];


    // Hazard free flags: ensure the memfy and m extension are not 
    // processing instruction which the rd outputs are not sources for
    // the next instruction. If not, an outstanding instruction can 
    // be issued and processed in parallel. 
    // Checks also RD is not the same between instructions to ensure execution
    // order is kept in-order. For instance:
    // sw x10, 0(x0)
    // lw x10, 0
    // li x10, 1
    // lw is here useless, a kind of NOP while li will overwrite it but the
    // read outstqnding request will certainly arrived far after the li
    // instruction and corrupt the expected value of the user.
    assign memfy_hzd_free = memfy_regs_sts[rs1] & memfy_regs_sts[rs2] & memfy_regs_sts[rd];
    assign m_hzd_free = m_regs_sts[rs1] & m_regs_sts[rs2] & m_regs_sts[rd];
    assign hzd_free = m_hzd_free & memfy_hzd_free;


    ///////////////////////////////////////////////////////////////////////////
    //
    // Computation activation
    //
    ///////////////////////////////////////////////////////////////////////////

    assign i_inst = ((opcode==`R_ARITH & (funct7==7'b0000000 | funct7==7'b0100000)) |
                      opcode==`I_ARITH);

    assign ls_inst = opcode==`LOAD | opcode==`STORE;

    assign m_inst = opcode==`MULDIV & funct7==7'b0000001;

    /*
        Previous version without hazard detection
        https://github.com/dpretet/friscv/blob/2aaefe815510b415dfe0ec10175f137d00a4ceec/rtl/friscv_processing.sv

    assign alu_valid = proc_valid_p & memfy_ready & m_ready & i_inst & !memfy_pending_read;
    assign memfy_valid = proc_valid_p & alu_ready & m_ready & ls_inst;
    assign m_valid = proc_valid_p & alu_ready & memfy_ready & m_inst & !memfy_pending_read;

    assign proc_ready_p = alu_ready & memfy_ready & m_ready;
    */
    
    always_comb begin

        case ({ls_inst,m_inst,i_inst})

            default: begin
                alu_valid = 1'b0;
                m_valid = 1'b0;
                memfy_valid = 1'b0;
                proc_ready_p = 1'b1;
            end

            // Instruction to process with ALU
            3'b001 : begin
                alu_valid = proc_valid_p & hzd_free;
                m_valid = 1'b0;
                memfy_valid = 1'b0;
                proc_ready_p = alu_ready & hzd_free;
            end

            // Instruction to process with Mult/Div extension
            3'b010 : begin
                alu_valid = 1'b0;
                m_valid = proc_valid_p & hzd_free;
                memfy_valid = 1'b0;
                proc_ready_p = m_ready & hzd_free;
            end

            // Instruction to load/store memory controller
            // We don't check hazard with previous memfy instruction, the 
            // module serves them in-order and dCache sends back in-order
            // too. Only m extension is checked
            3'b100 : begin
                alu_valid = 1'b0;
                m_valid = 1'b0;
                memfy_valid = proc_valid_p & hzd_free;
                proc_ready_p = memfy_ready & hzd_free;
            end

        endcase

    end

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
        .alu_instbus   (proc_instbus_p),
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
        .XLEN              (XLEN),
        .NB_INT_REG        (NB_INT_REG),
        .MAX_OR            (DATA_OSTDREQ_NUM),
        .AXI_ADDR_W        (AXI_ADDR_W),
        .AXI_ID_W          (AXI_ID_W),
        .AXI_DATA_W        (AXI_DATA_W),
        .AXI_ID_MASK       (AXI_ID_MASK),
        .AXI_ORDERING      (AXI_ORDERING),
        .DCACHE_BLOCK_W    (DCACHE_BLOCK_W),
        .IO_MAP_NB         (IO_MAP_NB),
        .IO_MAP            (IO_MAP)
    )
    memfy
    (
        .aclk                (aclk),
        .aresetn             (aresetn),
        .srst                (srst),
        .memfy_valid         (memfy_valid),
        .memfy_ready         (memfy_ready),
        .memfy_pending_read  (memfy_pending_read),
        .memfy_pending_write (memfy_pending_write),
        .memfy_regs_sts      (memfy_regs_sts),
        .memfy_fenceinfo     (proc_fenceinfo),
        .memfy_instbus       (proc_instbus_p),
        .memfy_exceptions    (memfy_exceptions),
        .memfy_rs1_addr      (proc_rs1_addr[1*5+:5]),
        .memfy_rs1_val       (proc_rs1_val[1*XLEN+:XLEN]),
        .memfy_rs2_addr      (proc_rs2_addr[1*5+:5]),
        .memfy_rs2_val       (proc_rs2_val[1*XLEN+:XLEN]),
        .memfy_rd_wr         (proc_rd_wr[1]),
        .memfy_rd_addr       (proc_rd_addr[1*5+:5]),
        .memfy_rd_val        (proc_rd_val[1*XLEN+:XLEN]),
        .memfy_rd_strb       (proc_rd_strb[1*XLEN/8+:XLEN/8]),
        .awvalid             (awvalid),
        .awready             (awready),
        .awaddr              (awaddr),
        .awprot              (awprot),
        .awcache             (awcache),
        .awid                (awid),
        .wvalid              (wvalid),
        .wready              (wready),
        .wdata               (wdata),
        .wstrb               (wstrb),
        .bvalid              (bvalid),
        .bready              (bready),
        .bid                 (bid),
        .bresp               (bresp),
        .arvalid             (arvalid),
        .arready             (arready),
        .araddr              (araddr),
        .arprot              (arprot),
        .arcache             (arcache),
        .arid                (arid),
        .rvalid              (rvalid),
        .rready              (rready),
        .rid                 (rid),
        .rresp               (rresp),
        .rdata               (rdata)
    );

    generate

    if (M_EXTENSION) begin: M_EXTENSION_SUPPORT

    friscv_m_ext
    #(
        .XLEN (XLEN)
    )
    m_ext
    (
        .aclk           (aclk),
        .aresetn        (aresetn),
        .srst           (srst),
        .m_valid        (m_valid),
        .m_ready        (m_ready),
        .m_instbus      (proc_instbus_p),
        .m_regs_sts     (m_regs_sts),
        .div_pending    (div_pending),
        .m_rs1_addr     (proc_rs1_addr[M_IX*5+:5]),
        .m_rs1_val      (proc_rs1_val[M_IX*XLEN+:XLEN]),
        .m_rs2_addr     (proc_rs2_addr[M_IX*5+:5]),
        .m_rs2_val      (proc_rs2_val[M_IX*XLEN+:XLEN]),
        .m_rd_wr        (proc_rd_wr[M_IX]),
        .m_rd_addr      (proc_rd_addr[M_IX*5+:5]),
        .m_rd_val       (proc_rd_val[M_IX*XLEN+:XLEN]),
        .m_rd_strb      (proc_rd_strb[M_IX*XLEN/8+:XLEN/8])
    );

    end else begin: NO_M_EXTENSION

        assign m_ready = 1'b1;
        assign m_regs_sts = '1;

    end
    endgenerate


    ///////////////////////////////////////////////////////////////////////////
    //
    // Exceptions mapping
    //
    ///////////////////////////////////////////////////////////////////////////

    assign proc_exceptions[0+:2] = memfy_exceptions;

endmodule

`resetall
