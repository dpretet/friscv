// distributed under the mit license
// https://opensource.org/licenses/mit-license.php

`timescale 1 ns / 1 ps
`default_nettype none

`include "friscv_h.sv"

///////////////////////////////////////////////////////////////////////////////////////////////////
//
// Memory controller handling data transfer for LOAD / STORE instructions and atomic operations.
//
// The module transforms ISA LOAD/STORE instructions in AXI4-lite Read/Write requests.
//
// The module uses a single AXI4 ID, setup with AXI_ID_MASK, to ensure in-order load/store.
// It uses AXI_ID_MASK + 1 for atomic operation access.
//
// The FSM handles outstanding requests in both directions, read and write, and wait for a direction
// received all its completions to serve requests in another direction.
//
// The module provides flags indicating pending read/write requests to sequence instructions
// into the processing module.
//
// This module doesn't handle unaligned transfer, it will serve them anyway but will forward an
// exception to the central controller thru a dedicated bus.
//
///////////////////////////////////////////////////////////////////////////////////////////////////

module friscv_memfy

    #(
        // Architecture selection
        parameter XLEN = 32,
        // Number of integer registers (RV32I = 32, RV32E = 16)
        parameter NB_INT_REG = 32,
        // Address bus width defined for both control and AXI4 address signals
        parameter AXI_ADDR_W = XLEN,
        // AXI ID width, setup by default to 8 and unused
        parameter AXI_ID_W = 8,
        // AXI4 data width, for instruction and a data bus
        parameter AXI_DATA_W = XLEN,
        // ID used to identify the data abus in the fabric
        parameter AXI_ID_MASK = 'h20,
        // Maximum outstanding request supported
        parameter MAX_OR = 8,
        // Add pipeline on Rd write stage
        parameter SYNC_RD_WR = 0,
        // Support hypervisor mode
        parameter HYPERVISOR_MODE = 0,
        // Support supervisor mode
        parameter SUPERVISOR_MODE = 0,
        // Support user mode
        parameter USER_MODE = 0,
        // PMP / PMA supported
        parameter MPU_SUPPORT = 0,
        // Support Atomic Operation Extension
        parameter A_EXTENSION = 0,
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
        input  wire                         memfy_valid,
        output logic                        memfy_ready,
        output logic                        memfy_pending_read,
        output logic                        memfy_pending_write,
        output logic [NB_INT_REG      -1:0] memfy_regs_sts,
        output logic [4               -1:0] memfy_fenceinfo,
        input  wire  [`INST_BUS_W     -1:0] memfy_instbus,
        output logic [`PROC_EXP_W     -1:0] memfy_exceptions,
        // register source 1 query interface
        output logic [5               -1:0] memfy_rs1_addr,
        input  wire  [XLEN            -1:0] memfy_rs1_val,
        // register source 2 query interface
        output logic [5               -1:0] memfy_rs2_addr,
        input  wire  [XLEN            -1:0] memfy_rs2_val,
        // register destination write interface
        output logic                        memfy_rd_wr,
        output logic [5               -1:0] memfy_rd_addr,
        output logic [XLEN            -1:0] memfy_rd_val,
        output logic [XLEN/8          -1:0] memfy_rd_strb,
        // PMP / PMA Checks
        output logic [AXI_ADDR_W      -1:0] mpu_addr,
        input  wire  [4               -1:0] mpu_allow,
        // data memory interface
        output logic                        awvalid,
        input  wire                         awready,
        output logic [AXI_ADDR_W      -1:0] awaddr,
        output logic [3               -1:0] awprot,
        output logic [4               -1:0] awcache,
        output logic [AXI_ID_W        -1:0] awid,
        output logic                        awlock,
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
        output logic                        arlock,
        input  wire                         rvalid,
        output logic                        rready,
        input  wire  [AXI_ID_W        -1:0] rid,
        input  wire  [2               -1:0] rresp,
        input  wire  [AXI_DATA_W      -1:0] rdata
    );

    // All functions necessary for access alignment
    `include "friscv_memfy_h.sv"

    ///////////////////////////////////////////////////////////////////////////
    //
    // Parameters and variables declaration
    //
    ///////////////////////////////////////////////////////////////////////////

    localparam MAX_OR_W = $clog2(MAX_OR) + 1;

    // instruction bus
    logic signed [XLEN        -1:0] addr;
    logic        [`OPCODE_W   -1:0] opcode;
    logic        [`OPCODE_W   -1:0] opcode_r;
    logic        [`FUNCT3_W   -1:0] funct3;
    logic        [`FUNCT3_W   -1:0] funct3_r;
    logic        [`FUNCT5_W   -1:0] funct5;
    logic        [`FUNCT5_W   -1:0] funct5_r;
    logic        [`RS1_W      -1:0] rs1;
    logic        [`RS2_W      -1:0] rs2;
    logic        [`RD_W       -1:0] rd;
    logic        [`IMM12_W    -1:0] imm12;
    logic        [`RD_W       -1:0] rd_r;
    logic        [`INST_W     -1:0] inst;
    logic        [`PC_W       -1:0] pc;
    logic        [`PRIV_W     -1:0] priv;
    logic        [`PRIV_W     -1:0] mpp;
    logic                           mprv;
    logic                           aq;
    logic                           rl;
    logic                           priv_bit;
    logic        [3           -1:0] aprot;

    // read response channel
    logic                           push_rd_or;
    logic                           rd_or_full;
    logic                           rd_or_empty;
    logic        [2           -1:0] offset;

    // IO request management
    logic        [IO_MAP_NB   -1:0] io_map_hit;
    logic                           is_io_req;
    logic        [4           -1:0] acache;
    logic                           alock;

    // Outstanding request counters
    logic        [MAX_OR_W    -1:0] wr_or_cnt;
    logic                           max_wr_or;
    logic        [MAX_OR_W    -1:0] rd_or_cnt;
    logic                           max_rd_or;
    logic                           waiting_rd_cpl;
    logic                           waiting_wr_cpl;

    // registers under use for scheduler
    logic        [MAX_OR_W    -1:0] regs_or[NB_INT_REG-1:0];

    // MPU accesses
    logic                           check_access;
    logic                           active_access;
    logic                           read_allowed;
    logic                           write_allowed;

    // exceptions
    logic                           load_misaligned;
    logic                           store_misaligned;
    logic                           load_access_fault;
    logic                           store_access_fault;

    // Central FSM
    logic                           fsm_ready;
    logic                           stalled_bus;
    logic                           is_amo;
    logic                           is_amo_r;
    logic                           amo_cpl;

    // AMO
    logic        [5           -1:0] amo_rd;
    logic        [XLEN        -1:0] amo_reg;
    logic        [XLEN        -1:0] amo_reg_r;
    logic        [XLEN        -1:0] amo_mem;

    logic                           is_st, is_st_r;
    logic                           is_ld, is_ld_r;

    typedef enum logic[1:0] {
        XFER = 0,
        WAIT = 1,
        SERVE = 2
    } seq_fsm;

    seq_fsm state;

    ///////////////////////////////////////////////////////////////////////////
    //
    // Instruction bus fields
    //
    ///////////////////////////////////////////////////////////////////////////

    assign opcode = memfy_instbus[`OPCODE +: `OPCODE_W];
    assign funct3 = memfy_instbus[`FUNCT3 +: `FUNCT3_W];
    assign funct5 = memfy_instbus[`FUNCT5 +: `FUNCT5_W];
    assign rs1    = memfy_instbus[`RS1    +: `RS1_W   ];
    assign rs2    = memfy_instbus[`RS2    +: `RS2_W   ];
    assign rd     = memfy_instbus[`RD     +: `RD_W    ];
    assign imm12  = memfy_instbus[`IMM12  +: `IMM12_W ];
    assign pc     = memfy_instbus[`PC     +: `PC_W    ];
    assign inst   = memfy_instbus[`INST   +: `INST_W  ];
    assign priv   = memfy_instbus[`PRIV   +: `PRIV_W  ];
    assign mpp    = memfy_instbus[`MPP    +: `PRIV_W  ];
    assign mprv   = memfy_instbus[`MPRV               ];
    assign aq     = memfy_instbus[`AQ                 ];
    assign rl     = memfy_instbus[`RL                 ];


    ///////////////////////////////////////////////////////////////////////////
    // Opcode decoder
    ///////////////////////////////////////////////////////////////////////////
    always_comb begin

        // Regular store
        if (opcode == `STORE)                       is_st = '1;
        // Atomic op, store conditional
        else if (opcode == `AMO && funct5 == `SC_W) is_st = '1;
        else                                        is_st = '0;

        // Regular load
        if (opcode == `LOAD)                                           is_ld = '1;
        // Atomic op, load reserved
        else if (opcode == `AMO && funct5 == `LR_W)                    is_ld = '1;
        // Any other atomic op, read-modify-write
        else if (opcode == `AMO && funct5 != `LR_W && funct5 != `SC_W) is_ld = '1;
        else                                                           is_ld = '0;

    end


    ///////////////////////////////////////////////////////////////////////////
    //
    // Control circuit managing memory accesses. This FSM is separated in
    // three stages:
    //
    // - XFER: acknowledges the instruction bus and drives the AXI bus
    // - WAIT: acknowledged the instruction bus, drove the bus but READY wasn't
    //         asserted so wait for it
    //         Come from from XFER state
    // - SERVE: manages the AXI bus READY handshake and VALID assertions
    //         Come from from XFER or WAIT states
    //
    // This FSM is useful to put in place a FFD stage between the instruction
    // bus and the AXI bus to close the timing.
    //
    ///////////////////////////////////////////////////////////////////////////

    always @ (posedge aclk or negedge aresetn) begin

        if (aresetn == 1'b0) begin
            state <= XFER;
            fsm_ready <= '0;
            awaddr <= '0;
            awcache <= '0;
            awvalid <= '0;
            awprot <= '0;
            arprot <= '0;
            awlock <= '0;
            arlock <= '0;
            wvalid <= '0;
            wdata <= '0;
            wstrb <= '0;
            araddr <= '0;
            arvalid <= '0;
            arcache <= '0;
            opcode_r <= '0;
            funct5_r <= '0;
            amo_cpl <= '0;
            amo_rd <= '0;
            is_amo_r <= '0;
            is_ld_r <= '0;
            is_st_r <= '0;
        end else if (srst == 1'b1) begin
            state <= XFER;
            fsm_ready <= '0;
            awaddr <= '0;
            awcache <= '0;
            awvalid <= '0;
            awprot <= '0;
            arprot <= '0;
            awlock <= '0;
            arlock <= '0;
            wvalid <= '0;
            wdata <= '0;
            wstrb <= '0;
            araddr <= '0;
            arvalid <= '0;
            arcache <= '0;
            opcode_r <= '0;
            funct5_r <= '0;
            amo_cpl <= '0;
            amo_rd <= '0;
            is_amo_r <= '0;
            is_ld_r <= '0;
            is_st_r <= '0;
        end else begin

            case (state)

                // XFER: Manages LOAD or STORE instruction issued to instruction controller
                //
                // The FSM mainly lives in XFER state because the AXI bus most of the time
                // always asserts its READY signal.
                //
                // The state is composed by two sub-states:
                //    - STALL: FSM is stopped because last command issued has
                //             not been acknowledged yet by the slave.
                //    - READY: FSM will send the request if the instruction bus
                //             is loaded
                default: begin

                    // XFER.STALL state:
                    // -----------------
                    // Handles a situation during which the address or data
                    // channel is not ready to accept a transaction.
                    // Arrives here once:
                    // - we were in XFER.READY
                    // - we issued a request (either read or write)
                    // - AXI interface READY was asserted
                    // - but AXI interface is no more ready when AVALID is raised 1 cycle later
                    if ((arvalid && !arready) ||
                        (awvalid && !awready) || (wvalid && !wready))
                    begin

                        // If address handshaked, release the request
                        if (awready) awvalid <= 1'b0;
                        // If data handshaked, stop to issue it
                        if (wready) wvalid <= 1'b0;

                        state <= SERVE;
                        fsm_ready <= 1'b0;

                    // XFER.READY state:
                    // -----------------
                    // Will forward a R/W transaction if the instruction bus is loaded
                    // or will continue to execute an AMO if in the STORE phase
                    end else if (memfy_valid || amo_cpl) begin

                        if (!amo_cpl) begin
                            awaddr <= addr;
                            araddr <= addr;
                            awcache <= acache;
                            arcache <= acache;
                            awprot <= aprot;
                            arprot <= aprot;
                            awlock <= alock;
                            arlock <= alock;
                            opcode_r <= opcode;
                            funct5_r <= funct5;
                            is_amo_r <= is_amo;
                            is_st_r <= is_st;
                            is_ld_r <= is_ld;
                            amo_rd <= rd;
                        end

                        // STORE instruction or the second phase of an AMO
                        if ((is_st || amo_cpl) && write_allowed) begin

                            // If executing an AMO read-modify-write,
                            // erase this flag to restart from scratch next instruction
                            amo_cpl <= '0;

                            if (waiting_rd_cpl || arvalid) begin
                                state <= WAIT;
                                awvalid <= 1'b0;
                                wvalid <= 1'b0;
                                fsm_ready <= 1'b0;

                            end else if (!awready || !wready) begin
                                state <= SERVE;
                                awvalid <= 1'b1;
                                wvalid <= 1'b1;
                                fsm_ready <= 1'b0;

                            end else begin
                                awvalid <= 1'b1;
                                wvalid <= 1'b1;
                            end

                            // TODO: check of AMO manipulates only Word or Double-Word
                            if (amo_cpl) begin
                                wdata <= amo_mem;
                                wstrb <= '1;
                            end else begin
                                wdata <= get_axi_data(memfy_rs2_val, addr[1:0]);
                                wstrb <= get_axi_strb(funct3, addr[1:0]);
                            end

                            arvalid <= 1'b0;

                        // LOAD
                        end else if (is_ld && read_allowed) begin

                            if (!is_amo)
                                amo_cpl <= '0;
                            else if (funct5 == `LR_W || funct5 == `SC_W)
                                amo_cpl <= '0;
                            else
                                amo_cpl <= '1;

                            if (waiting_wr_cpl || awvalid) begin
                                state <= WAIT;
                                arvalid <= 1'b0;
                                fsm_ready <= 1'b0;
                            end else begin
                                arvalid <= 1'b1;
                                fsm_ready <= 1'b1;
                            end

                            awvalid <= 1'b0;
                            wvalid <= 1'b0;
                            wstrb <= '0;

                        // LOAD / STORE misaligned or not allowed
                        end else begin
                            fsm_ready <= 1'b1;
                            awvalid <= 1'b0;
                            wvalid <= 1'b0;
                            wstrb <= {XLEN/8{1'b0}};
                            arvalid <= 1'b0;
                        end

                    // Wait for an instruction
                    end else begin
                        fsm_ready <= 1'b1;
                        awvalid <= 1'b0;
                        wvalid <= 1'b0;
                        wstrb <= {XLEN/8{1'b0}};
                        arvalid <= 1'b0;
                    end
                end

                // SERVE: LOAD or STORE finalization over the AXI bus. We arrived here
                //        because the AXI bus wan't completly ready when we handshaked
                //        with the instruction bus
                SERVE: begin

                    // Any load
                    if (is_ld_r) begin
                        // Stop the request once accepted
                        if (arready) arvalid <= 1'b0;
                        state <= XFER;
                        fsm_ready <= 1'b1;
                    // Any store
                    end else begin

                        // Stop the request once accepted
                        if (awready) awvalid <= 1'b0;
                        if (wready) wvalid <= 1'b0;

                        // Wait until addr and data have been acknowledged
                        if (awready && wready  ||   // addr & data channel acked on same cycle
                            !awvalid && wready ||   // addr has been acked before data
                            awready && !wvalid      // addr is acked and data has been acked before
                        ) begin
                            fsm_ready <= 1'b1;
                            state <= XFER;
                        end
                    end

                end

                // WAIT: Wait for all write completion have been received before moving to LOAD
                WAIT: begin

                    if (is_ld_r && !waiting_wr_cpl) begin
                        state <= SERVE;
                        arvalid <= 1'b1;
                    end else if ((is_st_r || amo_cpl) && !waiting_rd_cpl) begin
                        state <= SERVE;
                        awvalid <= 1'b1;
                        wvalid <= 1'b1;
                    end
                end

            endcase
        end
    end

    // Block any further requests if XFER is XFER.STALL, last request issued
    // has not been yet acknowledged
    assign stalled_bus = (state==XFER) & ((arvalid & !arready) | (awvalid & !awready) | (wvalid & !wready));

    // Continue to accept if XFER.READY and didn't reach yet maximum of
    // outstanding requests available
    assign memfy_ready = fsm_ready & !rd_or_full & !stalled_bus;


    ///////////////////////////////////////////////////////////////////////////
    //
    // Store outstanding read request info for data alignment of the completion
    //
    ///////////////////////////////////////////////////////////////////////////

    assign push_rd_or = memfy_valid & memfy_ready & is_ld & !load_misaligned;

    friscv_scfifo
    #(
        .PASS_THRU  (0),
        .ADDR_WIDTH ($clog2(MAX_OR)),
        .DATA_WIDTH (10)
    )
    rd_or_fifo
    (
        .aclk     (aclk),
        .aresetn  (aresetn),
        .srst     (srst),
        .flush    (1'b0),
        .data_in  ({rd, funct3, addr[1:0]}),
        .push     (push_rd_or),
        .full     (rd_or_full),
        .afull    (),
        .data_out ({rd_r, funct3_r, offset}),
        .pull     (rvalid & rready),
        .empty    (rd_or_empty),
        .aempty   ()
    );

    always @ (posedge aclk) begin
        `ifdef FRISCV_SIM
        if (aresetn && rvalid && rready && rd_or_empty)
            $error("ERROR: (@ %0t) - %s: Receive a read completion but doesn't expect it", $realtime, "Memfy");
        `endif
    end

    ////////////////////////////////////////////////////////////////////////////
    //
    // Atomic Operation Support
    //
    ////////////////////////////////////////////////////////////////////////////

    generate if (A_EXTENSION) begin: A_SUPPORT

        friscv_amo_op amo_op_inst (
            .aclk       (aclk),
            .aresetn    (aresetn),
            .srst       (srst),
            .opcode     (funct5_r),
            .op1        (rdata),
            .op2        (memfy_rs2_val),
            .rd         (amo_reg),
            .mem        (amo_mem)
        );

        assign is_amo = (opcode == `AMO) ? '1 : '0;

        // Store AMO register value for later use if write receives
        // EXOKAY to update the processor register
        always @ (posedge aclk or negedge aresetn) begin
            if (!aresetn) amo_reg_r <= '0;
            else if (srst) amo_reg_r <= '0;
            else if (rvalid & rready) amo_reg_r <= amo_reg;
        end

    end else begin : NO_A_SUPPORT
        assign amo_reg = '0;
        assign amo_reg_r = '0;
        assign amo_mem = '0;
        assign is_amo = '0;
    end
    endgenerate



    ////////////////////////////////////////////////////////////////////////
    //
    // Track which integer registers is used by an outstanding request
    // for instruction scheduling
    //
    ////////////////////////////////////////////////////////////////////////

    always @ (posedge aclk or negedge aresetn) begin
        if (!aresetn) begin
            regs_or[0] <= '0;
        end else if (srst) begin
            regs_or[0] <= '0;
        end else begin
            regs_or[0] <= '0;
        end
    end

    for (genvar i=1;i<NB_INT_REG;i++) begin: REGISTERS_OR_TRACKING
        always @ (posedge aclk or negedge aresetn) begin
            if (!aresetn) begin
                regs_or[i] <= '0;
            end else if (srst) begin
                regs_or[i] <= '0;
            end else begin
                if ((memfy_valid && memfy_ready && is_ld && !max_rd_or && rd == i[4:0] && mpu_allow[`ALW_R] && !load_misaligned) &&
                   !(rvalid & rready && rd_r==i[4:0]))
               begin
                    regs_or[i] <= regs_or[i] + 1;

                end else if (!(memfy_valid && memfy_ready && is_ld && !max_rd_or && rd == i[4:0]) &&
                              (rvalid & rready && rd_r==i[4:0]))
                begin
                    regs_or[i] <= regs_or[i] - 1;
                end
            end
        end
    end

    for (genvar i=0;i<NB_INT_REG;i++) begin: REGISTERS_USAGE
        assign memfy_regs_sts[i] = regs_or[i] == '0;
    end


    ////////////////////////////////////////////////////////////////////////
    //
    // Track the current read/write outstanding requests waiting completions
    //
    ////////////////////////////////////////////////////////////////////////

    always @ (posedge aclk or negedge aresetn) begin

        if (!aresetn) begin
            wr_or_cnt <= {MAX_OR_W{1'b0}};
            rd_or_cnt <= {MAX_OR_W{1'b0}};

        end else if (srst) begin
            wr_or_cnt <= {MAX_OR_W{1'b0}};
            rd_or_cnt <= {MAX_OR_W{1'b0}};

        end else begin

            // Write xfers tracker
            if (memfy_valid && memfy_ready && is_st && !bvalid && !max_wr_or && write_allowed) begin
                wr_or_cnt <= wr_or_cnt + 1'b1;
            end else if (!(memfy_valid && memfy_ready && is_st) && bvalid && bready && wr_or_cnt!={MAX_OR_W{1'b0}}) begin
                wr_or_cnt <= wr_or_cnt - 1'b1;
            end

            // Read xfers tracker
            if (memfy_valid && memfy_ready && is_ld && !memfy_rd_wr && !max_rd_or && read_allowed) begin
                rd_or_cnt <= rd_or_cnt + 1'b1;
            end else if (!(memfy_valid && memfy_ready && is_ld) && memfy_rd_wr && rd_or_cnt!={MAX_OR_W{1'b0}}) begin
                rd_or_cnt <= rd_or_cnt - 1'b1;
            end

            `ifdef TRACE_MEMFY
            //synthesis translate_off
            //synopsys translate_off
            if ((memfy_valid && memfy_ready && is_st && !bvalid && max_wr_or) begin
                $display("ERROR: (@%0t) %s: Reached maximum write OR number but continue to issue requests", $realtime, "MEMFY");
            end else if (!(memfy_valid && memfy_ready && is_st) && bvalid && bready && wr_or_cnt=={MAX_OR_W{1'b0}}) begin
                $display("ERROR: (@%0t) %s: Freeing a write OR but counter is already 0", $realtime, "MEMFY");
            end

            if (memfy_valid && memfy_ready && is_ld && !memfy_rd_wr && && max_rd_or) begin
                $display("ERROR: (@%0t) %s: Reached maximum read OR number but continue to issue requests", $realtime, "MEMFY");
            end else if (!(memfy_valid && memfy_ready && is_ld) && memfy_rd_wr && rd_or_cnt=={MAX_OR_W{1'b0}}) begin
                $display("ERROR: (@%0t) %s: Freeing a read OR but counter is already 0", $realtime, "MEMFY");
            end
            //synopsys translate_on
            //synthesis translate_on
            `endif
        end
    end

    assign max_wr_or = (wr_or_cnt==MAX_OR[MAX_OR_W-1:0]) ? 1'b1 : 1'b0;
    assign max_rd_or = (rd_or_cnt==MAX_OR[MAX_OR_W-1:0]) ? 1'b1 : 1'b0;

    assign waiting_wr_cpl = (wr_or_cnt!={MAX_OR_W{1'b0}} && !(wr_or_cnt=={{(MAX_OR_W-1){1'b0}}, 1'b1} & bvalid)) ? 1'b1 : 1'b0;
    assign waiting_rd_cpl = (rd_or_cnt!={MAX_OR_W{1'b0}} && !(rd_or_cnt=={{(MAX_OR_W-1){1'b0}}, 1'b1} & rvalid)) ? 1'b1 : 1'b0;

    // Flags for outside modules
    assign memfy_pending_read = waiting_rd_cpl;
    assign memfy_pending_write = waiting_wr_cpl;


    ////////////////////////////////////////////////////////////////////////
    //
    // Manage the RD write operation
    //
    ////////////////////////////////////////////////////////////////////////

    generate if (SYNC_RD_WR) begin : RD_WR_FFD

    always @ (posedge aclk or negedge aresetn) begin
        if (!aresetn) begin
            memfy_rd_wr <= 1'b0;
            memfy_rd_addr <= 5'b0;
            memfy_rd_strb <= {XLEN/8{1'b0}};
            memfy_rd_val <= {XLEN{1'b0}};
        end else if (srst) begin
            memfy_rd_wr <= 1'b0;
            memfy_rd_addr <= 5'b0;
            memfy_rd_strb <= {XLEN/8{1'b0}};
            memfy_rd_val <= {XLEN{1'b0}};
        end else begin
            // Write into RD once the write channel handshakes with exclusive ack
            if (amo_cpl) begin
                memfy_rd_wr <= bvalid & bready & (bresp == `EXOKAY);
                memfy_rd_addr <= amo_rd;
                memfy_rd_strb <= '1;
                memfy_rd_val <= amo_reg_r;
            // Write into RD once the read data channel handshakes
            end else begin
                memfy_rd_wr <= rvalid & rready;
                memfy_rd_addr <= rd_r;
                memfy_rd_strb <= get_rd_strb(funct3_r, offset);
                memfy_rd_val <= get_rd_val(funct3_r, rdata, offset);
            end
        end
    end

    end else begin : RD_WR_COMB

        always @ (*) begin
            // Write into RD once the write channel handshakes with exclusive ack
            if (amo_cpl) begin
                memfy_rd_wr = bvalid & bready & (bresp == `EXOKAY);
                memfy_rd_addr = amo_rd;
                memfy_rd_strb = '1;
                memfy_rd_val = amo_reg_r;
            // Write into RD once the read data channel handshakes
            end else begin
                memfy_rd_wr = rvalid & rready;
                memfy_rd_addr = rd_r;
                memfy_rd_strb = get_rd_strb(funct3_r, offset);
                memfy_rd_val = get_rd_val(funct3_r, rdata, offset);
            end
        end

    end
    endgenerate

    assign memfy_rs1_addr = rs1;
    assign memfy_rs2_addr = rs2;


    /////////////////////////////////////////////////////////////////////////
    //
    // Address to read/write and fence information
    //
    ////////////////////////////////////////////////////////////////////////

    // The address to access during a LOAD or a STORE
    assign addr = $signed({{(XLEN-12){imm12[11]}}, imm12}) + $signed(memfy_rs1_val);

    // Unused: information forwarded to control unit for FENCE execution:
    // bit 0: memory write
    // bit 1: memory read
    // bit 2: device output
    // bit 3: device input
    assign memfy_fenceinfo = 4'b0;


    ///////////////////////////////////////////////////////////////////////////////
    //
    // Device/IO vs normal memory detection to ensure the access will not be cached
    //
    ///////////////////////////////////////////////////////////////////////////////
    generate

    if (IO_MAP_NB > 0) begin : IO_MAP_DEC

        for (genvar i=0;i<IO_MAP_NB;i=i+1) begin : GEN_IO_HIT
            assign io_map_hit[i] = (addr>=IO_MAP[i*2*XLEN+:XLEN] && addr<=IO_MAP[i*2*XLEN+XLEN+:XLEN]);
        end

        assign is_io_req = |io_map_hit;

    end else begin : NO_IO_MAP

        assign is_io_req = 1'b0;

    end
    endgenerate

    /*

    ACACHE[0]: 0 = non-bufferable 1 = bufferable
    ACACHE[1]: 0 = non-modifiable 1 = modifiable
    ACACHE[2]: 1 = read allocate
    ACACHE[3]: 1 = write allocate

    if ACACHE[1] = 0, ACACHE[3:2] must be 2'b00

    ------------------------------------------------------------------------------------------------
         ACACHE      |              AWCACHE                  |              ARCACHE
    [3] [2] [1] [0]  |                                       |
    ------------------------------------------------------------------------------------------------
     0   0   0   0   | Device Non-cacheable Non-bufferable   | Device Non-cacheable Non-bufferable
     0   0   0   1   | Device Non-cacheable Bufferable       | Device Non-cacheable Bufferable
    ------------------------------------------------------------------------------------------------
     0   0   1   0   | Normal Non-cacheable Non-bufferable   | Normal Non-cacheable Non-bufferable
     0   0   1   1   | Normal Non-cacheable Bufferable       | Normal Non-cacheable Bufferable
    ------------------------------------------------------------------------------------------------
     0   1   1   0   | Write-Through No-Allocate             | Write-Through Read-Allocate
                     | Write-Through Read-Allocate           |
    ------------------------------------------------------------------------------------------------
     0   1   1   1   | Write-Back No-Allocate                | Write-Back Read-Allocate
                     | Write-Back Read-Allocate              |
    ------------------------------------------------------------------------------------------------
     1   0   1   0   | Write-Through Write-Allocate          | Write-Through No-Allocate
                     |                                       | Write-Through Write-Allocate
    ------------------------------------------------------------------------------------------------
     1   0   1   1   | Write-Back Write-Allocate             | Write-Back No-Allocate
                     | Write-Back Read and Write-Allocate    | Write-Back Write-Allocate
    ------------------------------------------------------------------------------------------------
     1   1   1   0   | Write-Through Write-Allocate          | Write-Through Read-Allocate
                     | Write-Through Read and Write-Allocate | Write-Through Read and Write-Allocate
    ------------------------------------------------------------------------------------------------
     1   1   1   1   | Write-Back Write-Allocate             | Write-Back Read-Allocate
                     | Write-Back Read and Write-Allocate    | Write-Back Read and Write-Allocate
    ------------------------------------------------------------------------------------------------

    */

    generate if (A_EXTENSION) begin: A_SUPPORT_ACACHE
        assign acache = {2'b00, (is_io_req | is_amo), 1'b1};
    end else begin: NO_A_SUPPORT_ACACHE
        assign acache = {2'b00, is_io_req, 1'b1};
    end
    endgenerate


    //////////////////////////////////////////////////////////////////////////
    // ALOCK, driven high if an atomic op needs to be exectuted
    //////////////////////////////////////////////////////////////////////////

    generate if (A_EXTENSION) begin: A_SUPPORT_ALOCK
        assign alock = is_amo_r;
    end else begin: NO_ALOCK
        assign alock = '0;
    end
    endgenerate

    //////////////////////////////////////////////////////////////////////////
    // IDs on used for regular accesses, another for atomic ops
    // No out-of-order supported here, atomic ops are blocking the FSM
    // until completly executed
    //////////////////////////////////////////////////////////////////////////

    generate if (A_EXTENSION) begin: A_SUPPORT_AID
        assign awid = (is_amo) ? (AXI_ID_MASK | 'b1) : AXI_ID_MASK;
        assign arid = (is_amo) ? (AXI_ID_MASK | 'b1) : AXI_ID_MASK;
    end else begin : CONST_AID
        assign awid = AXI_ID_MASK;
        assign arid = AXI_ID_MASK;
    end
    endgenerate

    //////////////////////////////////////////////////////////////////////////
    // Privilege mode, only applicable if user mode is activated
    //////////////////////////////////////////////////////////////////////////

    generate if (USER_MODE) begin: UMODE_SUPPORT_APROT
        // Access permissions
        // [0] Unprivileged or privileged
        // [1] Secure or Non-secure
        // [2] Instruction or data
        assign priv_bit = (priv == `MMODE);
        assign aprot = {2'b00, priv_bit};
    end else begin: NO_APROT
        assign priv_bit = '0;
        assign aprot = '0;
    end
    endgenerate

    //////////////////////////////////////////////////////////////////////////
    // Completion are always accepted, no back-pressure on memory / cache
    //////////////////////////////////////////////////////////////////////////

    assign bready = 1'b1;
    assign rready = 1'b1;


    ////////////////////////////////////////////////////////////////////////////
    //
    // MPU management
    //
    ////////////////////////////////////////////////////////////////////////////


    generate if (USER_MODE) begin: UMODE_SUPPORT

        // Check access fault if u-mode or m-mode setup with u-mode rights
        assign check_access = (priv==`UMODE) || (priv==`MMODE && mpp==`UMODE && mprv) ||
                                                (priv==`MMODE && mpu_allow[`ALW_L]);

    end else begin: NO_UMODE_SUPPORT
        assign check_access = 1'b1;
    end
    endgenerate

    assign mpu_addr = addr;

    assign write_allowed = mpu_allow[`ALW_W] & !store_misaligned & check_access;

    assign read_allowed = mpu_allow[`ALW_R] & !load_misaligned & check_access;


    //////////////////////////////////////////////////////////////////////////
    //
    // Exception flags, driven back to control unit
    //
    //////////////////////////////////////////////////////////////////////////

    assign active_access = memfy_valid & memfy_ready;

    // LOAD is not XLEN-boundary aligned
    assign load_misaligned = (is_ld && (funct3==`LH || funct3==`LHU) &&
                                (addr[1:0]==2'h3 || addr[1:0]==2'h1))   ? active_access :
                             (is_ld && funct3==`LW  && addr[1:0]!=2'b0) ? active_access :
                                                                          1'b0 ;

    // STORE is not XLEN-boundary aligned
    assign store_misaligned = (is_st && funct3==`SH &&
                                (addr[1:0]==2'h3 || addr[1:0]==2'h1))   ? active_access :
                              (is_st && funct3==`SW && addr[1:0]!=2'b0) ? active_access :
                                                                          1'b0 ;

    // Load access outside an allowed region
    assign load_access_fault = (is_ld) & !mpu_allow[`ALW_R] & check_access & active_access;

    // Store access outside an allowed region
    assign store_access_fault = (is_st) & !mpu_allow[`ALW_W] & check_access & active_access;


    // Shared bus routing back to control unit

    assign memfy_exceptions[`LAF] = load_access_fault;

    assign memfy_exceptions[`SAF] = store_access_fault;

    assign memfy_exceptions[`LDMA] = load_misaligned;

    assign memfy_exceptions[`STMA] = store_misaligned;

    assign memfy_exceptions[`EXP_PC +: `EXP_PC_W] = pc;

    assign memfy_exceptions[`EXP_INST +: `EXP_INST_W] = inst;

    assign memfy_exceptions[`EXP_ADDR +: `EXP_ADDR_W] = addr;

endmodule

`resetall
