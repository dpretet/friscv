// distributed under the mit license
// https://opensource.org/licenses/mit-license.php

`timescale 1 ns / 1 ps
`default_nettype none

`include "friscv_h.sv"

///////////////////////////////////////////////////////////////////////////////////////////////////
//
// Memory controller handling data transfer for LOAD / STORE instructions.
//
// The module transforms ISA LOAD/STORE instructions in AXI4-lite Read/Write requests. The module
// handles outstanding requests as the AMBA protocol permits it and apply AMBA ordering rules being
// for a master using a single ID. Follow AMBA specification about ordering model:
//
// '''
//   - Transactions to any single peripheral device, must arrive at the peripheral in the order in
//     which they are issued, regardless of the addresses of the transactions.
//   - Memory transactions that use the same, or overlapping, addresses must arrive at the memory in
//     the order in which they are issued.
//   - Read and write address channels are independent and in this specification, are defined to be
//     in different directions. If an ordering relationship is required between two transactions with
//     the same ID that are in different directions, then a master must wait to receive a response
//     to the first transaction before issuing the second transaction.
//
// '''
//
// The module uses a single AXI4-lite ID, setup with AXI_ID_MASK. The FSM handles outstanding
// requests in both directions, read and write, and wait for a direction received all its
// completions to serve requests in another direction. The module provides flags indicating
// pending read/write requests to sequence instructions into the processing module.
//
// This module doesn't handle unaligned transfer, it will serve them anyway but will forward an
// exception to the central controller thru a dedicated bus.
//
///////////////////////////////////////////////////////////////////////////////////////////////////

module friscv_memfy

    #(
        // Architecture selection
        parameter XLEN           = 32,
        // Number of integer registers (RV32I = 32, RV32E = 16)
        parameter NB_INT_REG     = 32,
        // Address bus width defined for both control and AXI4 address signals
        parameter AXI_ADDR_W     = XLEN,
        // AXI ID width, setup by default to 8 and unused
        parameter AXI_ID_W       = 8,
        // AXI4 data width, for instruction and a data bus
        parameter AXI_DATA_W     = XLEN,
        // ID used to identify the dta abus in the infrastructure
        parameter AXI_ID_MASK    = 'h20,
        // Select the ordering scheme:
        //   - 0: ongoing reads block write request, ongoing writes block read request
        //   - 1: concurrent r/w requests can be issued if don't target same cache blocks
        parameter AXI_ORDERING = 0,
        // Block width defining only the data payload, in bits, must an
        // integer multiple of XLEN (power of two)
        parameter DCACHE_BLOCK_W = XLEN*4,
        // Maximum outstanding request supported
        parameter MAX_OR = 8,
        // Add pipeline on Rd write stage
        parameter SYNC_RD_WR = 1,
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
        output logic [2               -1:0] memfy_exceptions,
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

    // All AXI and RD write functions
    `include "friscv_memfy_h.sv"

    localparam MAX_OR_W = $clog2(MAX_OR) + 1;

    logic signed [XLEN        -1:0] addr;
    logic        [XLEN        -1:0] addr_to_check;
    logic        [`OPCODE_W   -1:0] opcode;
    logic        [`FUNCT3_W   -1:0] funct3;
    logic        [`RS1_W      -1:0] rs1;
    logic        [`RS2_W      -1:0] rs2;
    logic        [`RD_W       -1:0] rd;
    logic        [`IMM12_W    -1:0] imm12;
    logic        [`OPCODE_W   -1:0] opcode_r;
    logic        [`FUNCT3_W   -1:0] funct3_r;
    logic        [`RD_W       -1:0] rd_r;

    logic                           load_misaligned;
    logic                           store_misaligned;

    logic                           memfy_ready_fsm;
    logic                           stall_bus;

    logic                           push_rd_or;
    logic                           rd_or_full;
    logic                           rd_or_empty;
    logic        [2           -1:0] offset;

    logic        [IO_MAP_NB   -1:0] io_map_hit;
    logic                           is_io_req;
    logic        [4           -1:0] acache;

    logic        [MAX_OR_W    -1:0] regs_or[NB_INT_REG-1:0];

    logic                           used_in_rdch;
    logic                           used_in_wch;
    logic                           max_wr_or;
    logic                           max_rd_or;

    typedef enum logic[1:0] {
        IDLE = 0,
        WAIT = 1,
        SERVE = 2
    } seq_fsm;

    seq_fsm state;

    // Tracer setup
    `ifdef TRACE_MEMFY
    integer f;
    string fname;
    initial begin
        $sformat(fname, "trace_%s.txt", "memfy");
        f = $fopen(fname, "w");
    end
    `endif

    ///////////////////////////////////////////////////////////////////////////
    //
    // Instruction bus fields
    //
    ///////////////////////////////////////////////////////////////////////////

    assign opcode = memfy_instbus[`OPCODE +: `OPCODE_W];
    assign funct3 = memfy_instbus[`FUNCT3 +: `FUNCT3_W];
    assign rs1    = memfy_instbus[`RS1    +: `RS1_W   ];
    assign rs2    = memfy_instbus[`RS2    +: `RS2_W   ];
    assign rd     = memfy_instbus[`RD     +: `RD_W    ];
    assign imm12  = memfy_instbus[`IMM12  +: `IMM12_W ];


    ///////////////////////////////////////////////////////////////////////////
    //
    // Control circuit managing memory and register accesses
    //
    ///////////////////////////////////////////////////////////////////////////

    always @ (posedge aclk or negedge aresetn) begin

        if (aresetn == 1'b0) begin
            awaddr <= {AXI_ADDR_W{1'b0}};
            awcache <= 4'b0;
            awvalid <= 1'b0;
            wvalid <= 1'b0;
            wdata <= {XLEN{1'b0}};
            wstrb <= {XLEN/8{1'b0}};
            araddr <= {AXI_ADDR_W{1'b0}};
            arvalid <= 1'b0;
            arcache <= 4'b0;
            opcode_r <= 7'b0;
            state <= IDLE;
            memfy_ready_fsm <= 1'b0;
        end else if (srst == 1'b1) begin
            awaddr <= {AXI_ADDR_W{1'b0}};
            awvalid <= 1'b0;
            wvalid <= 1'b0;
            wdata <= {XLEN{1'b0}};
            wstrb <= {XLEN/8{1'b0}};
            araddr <= {AXI_ADDR_W{1'b0}};
            arvalid <= 1'b0;
            arcache <= 4'b0;
            opcode_r <= 7'b0;
            state <= IDLE;
            memfy_ready_fsm <= 1'b0;
        end else begin

            case (state)

                // IDLE: Manages LOAD or STORE instruction issue to instruction controller
                // The state is composed by two sub-states:
                //    - STALL: FSM is stopped because last command issued has
                //             not been acknowledged by the slave.
                //    - READY: FSM will send the request if the instruction bus
                //             is loaded
                default: begin

                    // IDLE.STALL state:
                    // -----------------
                    // Handles a situation during which the address or data
                    // channel is not ready to accept a transaction.
                    // For write, we stop handshaking a channel which acknowledged
                    // For read, only the address channel could have fail, we
                    // do nothing. FSM is not ready anymore and we move to SERVE
                    if ((arvalid && !arready) ||
                        (awvalid && !awready) || (wvalid && !wready))
                    begin

                        // If address handshaked, release the request
                        if (awready) awvalid <= 1'b0;
                        // If data handshaked, stop to issue it
                        if (wready) wvalid <= 1'b0;

                        state <= SERVE;
                        memfy_ready_fsm <= 1'b0;

                    // IDLE.READY state:
                    // -----------------
                    // Will forward a R/W transaction if the instruction is loaded
                    end else if (memfy_valid) begin

                        awaddr <= addr;
                        araddr <= addr;
                        awcache <= acache;
                        arcache <= acache;

                        opcode_r <= opcode;

                        // STORE
                        if (opcode==`STORE) begin

                            if (used_in_rdch || arvalid) begin
                                state <= WAIT;
                                awvalid <= 1'b0;
                                wvalid <= 1'b0;
                                memfy_ready_fsm <= 1'b0;

                            end else if (!awready || !wready) begin
                                state <= SERVE;
                                awvalid <= 1'b1;
                                wvalid <= 1'b1;
                                memfy_ready_fsm <= 1'b0;

                            end else begin
                                awvalid <= 1'b1;
                                wvalid <= 1'b1;
                            end

                            wdata <= get_axi_data(memfy_rs2_val, addr[1:0]);
                            wstrb <= get_axi_strb(funct3, addr[1:0]);

                            arvalid <= 1'b0;

                        // LOAD
                        end else begin
                            if (used_in_wch || awvalid) begin
                                state <= WAIT;
                                arvalid <= 1'b0;
                                memfy_ready_fsm <= 1'b0;
                            end else begin
                                arvalid <= 1'b1;
                                memfy_ready_fsm <= 1'b1;
                            end
                            awvalid <= 1'b0;
                            wvalid <= 1'b0;
                            wstrb <= {XLEN/8{1'b0}};
                        end

                    // Wait for an instruction
                    end else begin
                        memfy_ready_fsm <= 1'b1;
                        awvalid <= 1'b0;
                        wvalid <= 1'b0;
                        wstrb <= {XLEN/8{1'b0}};
                        arvalid <= 1'b0;
                        arvalid <= 1'b0;
                    end
                end

                // SERVE: LOAD or STORE instructions execution when a AREADY was down
                SERVE: begin

                    //LOAD
                    if (opcode_r==`LOAD) begin
                        // Stop the request once accepted
                        if (arready) arvalid <= 1'b0;
                        state <= IDLE;
                        memfy_ready_fsm <= 1'b1;
                    // STORE
                    end else begin

                        // Stop the request once accepted
                        if (awready) awvalid <= 1'b0;
                        if (wready) wvalid <= 1'b0;

                        // Wait until addr and data have been acknowledged
                        if (awready && wready  ||   // addr & data channel acked on same cycle
                            ~awvalid && wready ||   // addr has been acked before data
                            awready && ~wvalid      // addr is acked and data has been acked before
                        ) begin
                            memfy_ready_fsm <= 1'b1;
                            state <= IDLE;
                        end
                    end

                end

                // WAIT: Wait for all completions have been received before moving to LOAD
                WAIT: begin

                    if (opcode_r==`LOAD && !used_in_wch) begin
                        state <= SERVE;
                        arvalid <= 1'b1;
                    end else if (opcode_r==`STORE && !used_in_rdch) begin
                        state <= SERVE;
                        awvalid <= 1'b1;
                        wvalid <= 1'b1;
                    end
                end

            endcase
        end
    end

    // Block any further requests if IDLE is IDLE.STALL, last request issued
    // has not been yet acknowledged
    assign stall_bus = (state==IDLE) & ((arvalid & !arready) | (awvalid & !awready) | (wvalid & !wready));

    // Continue to accept if IDLE.READY and didn't reach yet maximum of
    // outstanding requests available
    assign memfy_ready = memfy_ready_fsm & !rd_or_full & !stall_bus;


    ////////////////////////////////////////////////////////////////////////
    //
    // Track which integer registers is used by an outstanding request
    // Used in processing to schedule the operations across the ALU / Memfy
    // and all extensions
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

    for (genvar i=1;i<NB_INT_REG;i++) begin
        always @ (posedge aclk or negedge aresetn) begin
            if (!aresetn) begin
                regs_or[i] <= '0;
            end else if (srst) begin
                regs_or[i] <= '0;
            end else begin
                if ((memfy_valid && memfy_ready && opcode==`LOAD && !max_rd_or && rd == i[4:0]) &&
                   !(rvalid & rready && rd_r==i[4:0]))
                begin
                    regs_or[i] <= regs_or[i] + 1;

                end else if (!(memfy_valid && memfy_ready && opcode==`LOAD && !max_rd_or && rd == i[4:0]) &&
                              (rvalid & rready && rd_r==i[4:0]))
                begin
                    regs_or[i] <= regs_or[i] - 1;
                end
            end
        end
    end

    for (genvar i=0;i<NB_INT_REG;i++) begin
        assign memfy_regs_sts[i] = regs_or[i] == '0;
    end

    ////////////////////////////////////////////////////////////////////////
    //
    // Ordering rules checker. Count oustanding requests to be sure we
    // don't use too much bandwidth.
    // If AXI_ORDERING = 0, the read channel block further write request
    // until complete completion, and vice versa.
    // If AXI_ORDERING = 1, read and write can be issued concurrently as
    // long they don't targe the same memory address.
    //
    ////////////////////////////////////////////////////////////////////////

    // Use AXI address if FSM is waiting for a schedule. Use awaddr but is equal to araddr
    assign addr_to_check = (memfy_ready_fsm) ? addr : awaddr;

    friscv_memfy_ordering
    #(
        .AXI_ORDERING   (AXI_ORDERING),
        .MAX_OR         (MAX_OR),
        .AXI_ADDR_W     (AXI_ADDR_W),
        .MEM_BLOCK_W    (XLEN)
    )
    ordering
    (
        .aclk         (aclk),
        .aresetn      (aresetn),
        .srst         (srst),
        .memfy_valid  (memfy_valid),
        .memfy_ready  (memfy_ready),
        .memfy_opcode (opcode),
        .memfy_addr   (addr_to_check),
        .memfy_rd_wr  (memfy_rd_wr),
        .bvalid       (bvalid),
        .bready       (bready),
        .rvalid       (rvalid),
        .rready       (rready),
        .wr_coll      (used_in_wch),
        .rd_coll      (used_in_rdch),
        .max_wr_or    (max_wr_or),
        .max_rd_or    (max_rd_or),
        .pending_wr   (memfy_pending_write),
        .pending_rd   (memfy_pending_read)
    );


    ////////////////////////////////////////////////////////////////////////
    // Manage the RD write operation once read channel handshakes
    ////////////////////////////////////////////////////////////////////////

    // Store outstanding read request info for data alignment of the completion

    assign push_rd_or = memfy_valid & memfy_ready & (opcode==`LOAD);

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

        `ifdef TRACE_MEMFY
        if (aresetn && arvalid && arready)
            $fwrite(f, "(@ %0t) Read address %x\n", $realtime, araddr);
        if (aresetn && awvalid && awready)
            $fwrite(f, "(@ %0t) Write address %x\n", $realtime, awaddr);
        if (aresetn && wvalid && wready)
            $fwrite(f, "(@ %0t) Write data %x / %0x\n", $realtime, wdata, wstrb);
        `endif

    end

    generate if (SYNC_RD_WR) begin

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
            memfy_rd_wr <= rvalid & rready;
            memfy_rd_addr <= rd_r;
            memfy_rd_strb <= get_rd_strb(funct3_r, offset);
            memfy_rd_val <= get_rd_val(funct3_r, rdata, offset);
        end
    end

    end else begin

        assign memfy_rd_wr = rvalid & rready;
        assign memfy_rd_addr = rd_r;
        assign memfy_rd_strb = get_rd_strb(funct3_r, offset);
        assign memfy_rd_val = get_rd_val(funct3_r, rdata, offset);

    end
    endgenerate

    assign memfy_rs1_addr = rs1;
    assign memfy_rs2_addr = rs2;


    /////////////////////////////////////////////////////////////////////////
    // Address to read/write and fence information
    ////////////////////////////////////////////////////////////////////////

    // The address to access during a LOAD or a STORE
    assign addr = $signed({{(XLEN-12){imm12[11]}}, imm12}) + $signed(memfy_rs1_val);

    // Unused: information forwarded to control unit for FENCE execution:
    // bit 0: memory write
    // bit 1: memory read
    // bit 2: device output
    // bit 3: device input
    assign memfy_fenceinfo = 4'b0;


    ////////////////////////////////////////////////////////////////////////////
    // device/IO vs normal memory detection to ensure IO maps will not be cached
    ////////////////////////////////////////////////////////////////////////////
    generate

    if (IO_MAP_NB > 0) begin

        for (genvar i=0;i<IO_MAP_NB;i=i+1) begin
            assign io_map_hit[i] = (addr>=IO_MAP[i*2*XLEN+:XLEN] && addr<=IO_MAP[i*2*XLEN+XLEN+:XLEN]);
        end

        assign is_io_req = |io_map_hit;

    end else begin

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

    assign acache = {2'b00, is_io_req, 1'b1};

    //////////////////////////////////////////////////////////////////////////
    // Constant AXI4-lite signals
    //////////////////////////////////////////////////////////////////////////

    // Always use the same IDs to ensure in-order execution / completion
    assign awid = AXI_ID_MASK;
    assign arid = AXI_ID_MASK;

    // Access permissions
    // [0] Unprivileged or privileged
    // [1] Secure or Non-secure
    // [2] Instruction or data
    assign awprot = 3'b000;
    assign arprot = 3'b000;

    // Completion are always accepted
    assign bready = 1'b1;
    assign rready = 1'b1;


    //////////////////////////////////////////////////////////////////////////
    // Exception flags, driven back to control unit
    //////////////////////////////////////////////////////////////////////////

    assign load_misaligned = (opcode==`LOAD && (funct3==`LH || funct3==`LHU) &&
                                (addr[1:0]==2'h3 || addr[1:0]==2'h1))           ? memfy_valid & memfy_ready :
                             (opcode==`LOAD && funct3==`LW && addr[1:0]!=2'b0)  ? memfy_valid & memfy_ready :
                                                                                  1'b0 ;

    assign store_misaligned = (opcode==`STORE && funct3==`SH &&
                                (addr[1:0]==2'h3 || addr[1:0]==2'h1))            ? memfy_valid & memfy_ready :
                              (opcode==`STORE && funct3==`SW && addr[1:0]!=2'b0) ? memfy_valid & memfy_ready :
                                                                                   1'b0 ;
    always @ (posedge aclk or negedge aresetn) begin
        if (!aresetn) begin
            memfy_exceptions[`LD_MA] <= '0;
        end else begin
            memfy_exceptions[`LD_MA] <= load_misaligned;
            memfy_exceptions[`ST_MA] <= store_misaligned;
        end
    end

endmodule

`resetall
