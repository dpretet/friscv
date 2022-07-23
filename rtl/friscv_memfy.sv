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
// completions to serve requets in another direction. The module provides flags infdicating
// pending read/write requests to sequence instructions into the processing modules.
//
// This module doesn't handle unaligned transfer, it will serve them anyway but will forward an
// exception to the central controller thru a dedicated bus.
//
///////////////////////////////////////////////////////////////////////////////////////////////////

module friscv_memfy

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
        input  wire                         aclk,
        input  wire                         aresetn,
        input  wire                         srst,
        // ALU instruction bus
        input  wire                         memfy_valid,
        output logic                        memfy_ready,
        output logic                        memfy_pending_read,
        output logic [4               -1:0] memfy_fenceinfo,
        input  wire  [`INST_BUS_W     -1:0] memfy_instbus,
        output logic [2               -1:0] memfy_exceptions,
        // register source 1 query interface
        output logic [5               -1:0] memfy_rs1_addr,
        input  wire  [XLEN            -1:0] memfy_rs1_val,
        // register source 2 for query interface
        output logic [5               -1:0] memfy_rs2_addr,
        input  wire  [XLEN            -1:0] memfy_rs2_val,
        // register estination for query interface
        output logic                        memfy_rd_wr,
        output logic [5               -1:0] memfy_rd_addr,
        output logic [XLEN            -1:0] memfy_rd_val,
        output logic [XLEN/8          -1:0] memfy_rd_strb,
        // data memory interface
        output logic                        awvalid,
        input  wire                         awready,
        output logic [AXI_ADDR_W      -1:0] awaddr,
        output logic [3               -1:0] awprot,
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
        output logic [AXI_ID_W        -1:0] arid,
        input  wire                         rvalid,
        output logic                        rready,
        input  wire  [AXI_ID_W        -1:0] rid,
        input  wire  [2               -1:0] rresp,
        input  wire  [AXI_DATA_W      -1:0] rdata
    );


    ///////////////////////////////////////////////////////////////////////////
    //
    // AXI Alignment Functions
    //
    ///////////////////////////////////////////////////////////////////////////


    ///////////////////////////////////////////////////////////////////////////
    // Align the read memory value to write in RD. Right shift the data.
    // Args:
    //      - data: the word to align
    //      - offset: the shift to apply, ADDR's LSBs
    // Returns:
    //      - data aligned ready to store
    ///////////////////////////////////////////////////////////////////////////
    function automatic logic [XLEN-1:0] get_axi_data(

        input logic  [XLEN  -1:0] data,
        input logic  [2     -1:0] offset
    );
        if (offset==2'b00) get_axi_data = data;
        if (offset==2'b01) get_axi_data = {data[XLEN- 8-1:0], data[XLEN-1-:8]};
        if (offset==2'b10) get_axi_data = {data[XLEN-16-1:0], data[XLEN-1-:16]};
        if (offset==2'b11) get_axi_data = {data[XLEN-24-1:0], data[XLEN-1-:24]};

    endfunction


    ///////////////////////////////////////////////////////////////////////////
    // Align the write strobes to write in memory
    // Args:
    //      - strb: the strobes to align
    //      - offset: the shift to apply, ADDR's LSBs
    // Returns:
    //      - strobes aligned ready to store
    ///////////////////////////////////////////////////////////////////////////
    function automatic logic [XLEN/8-1:0] aligned_axi_strb(

        input logic  [XLEN/8-1:0] strb,
        input logic  [2     -1:0] offset
    );
        if (offset==2'b00) aligned_axi_strb = strb;
        if (offset==2'b01) aligned_axi_strb = {strb[XLEN/8-2:0], 1'b0};
        if (offset==2'b10) aligned_axi_strb = {strb[XLEN/8-3:0], 2'b0};
        if (offset==2'b11) aligned_axi_strb = {strb[XLEN/8-4:0], 3'b0};

    endfunction

    ///////////////////////////////////////////////////////////////////////////
    // Create the strobe vector to aply during a STORE instruction
    // Args:
    //      - funct3: opcode's funct3 identifier
    //      - offset: the shift to apply, ADDR's LSBs
    // Returns:
    //      - the ready to use strobes
    ///////////////////////////////////////////////////////////////////////////
    function automatic logic [XLEN/8-1:0] get_axi_strb(

        input logic  [2:0] funct3,
        input logic  [1:0] offset
    );
        if (funct3==`SB) get_axi_strb = aligned_axi_strb({{(XLEN/8-1){1'b0}},1'b1}, offset);
        if (funct3==`SH) get_axi_strb = aligned_axi_strb({{(XLEN/8-2){1'b0}},2'b11}, offset);
        if (funct3==`SW) get_axi_strb = aligned_axi_strb({(XLEN/8){1'b1}}, offset);

    endfunction


    ///////////////////////////////////////////////////////////////////////////
    //
    // ISA registers Alignment functions
    //
    ///////////////////////////////////////////////////////////////////////////


    ///////////////////////////////////////////////////////////////////////////
    // Align the read memory value to write in RD. Right shift the data.
    // Args:
    //      - data: the word to align
    //      - offset: the shift to apply, ADDR's LSBs
    // Returns:
    //      - data aligned ready to store
    ///////////////////////////////////////////////////////////////////////////
    function automatic logic [XLEN-1:0] get_aligned_rd_data(

        input logic  [XLEN  -1:0] data,
        input logic  [2     -1:0] offset
    );
        if (offset==2'b00) get_aligned_rd_data = data;
        if (offset==2'b01) get_aligned_rd_data = {data[XLEN-24-1:0], data[XLEN-1:8]};
        if (offset==2'b10) get_aligned_rd_data = {data[XLEN-16-1:0], data[XLEN-1:16]};
        if (offset==2'b11) get_aligned_rd_data = {data[XLEN- 8-1:0], data[XLEN-1:24]};

    endfunction

    ///////////////////////////////////////////////////////////////////////////
    // Create the strobe vector to apply during a RD write
    // Args:
    //      - funct3: opcode's funct3 identifier
    //      - rdata: the word to align
    //      - offset: the shift to apply, ADDR's LSBs
    // Returns:
    //      - the ready to use strobes
    ///////////////////////////////////////////////////////////////////////////
    function automatic logic [XLEN-1:0] get_rd_val(

        input logic  [3   -1:0] funct3,
        input logic  [XLEN-1:0] data,
        input logic  [2   -1:0] offset
    );
        logic [XLEN-1:0] data_aligned;

        data_aligned = get_aligned_rd_data(data, offset);

        if  (funct3==`LB)  get_rd_val = {{24{data_aligned[7]}}, data_aligned[7:0]};
        if  (funct3==`LBU) get_rd_val = {{24{1'b0}}, data_aligned[7:0]};
        if  (funct3==`LH)  get_rd_val = {{16{data_aligned[15]}}, data_aligned[15:0]};
        if  (funct3==`LHU) get_rd_val = {{16{1'b0}}, data_aligned[15:0]};
        if  (funct3==`LW)  get_rd_val = data_aligned;

    endfunction

    ///////////////////////////////////////////////////////////////////////////
    // Create the strobe vector to apply during a RD write
    // Args:
    //      - funct3: opcode's funct3 identifier
    //      - phase: first (0) or second (1) phase of the STORE request
    // Returns:
    //      - the ready to use strobes
    ///////////////////////////////////////////////////////////////////////////
    function automatic logic [XLEN/8-1:0] get_rd_strb(

        input logic  [3   -1:0] funct3,
        input logic  [2   -1:0] offset
    );
        if (funct3==`LB || funct3==`LBU) begin
            get_rd_strb = {(XLEN/8){1'b1}};
        end
        if (funct3==`LH || funct3==`LHU)  begin
            if (offset==2'h3) begin
                get_rd_strb = {{(XLEN/8-1){1'b0}},1'b1};
            end else begin
                get_rd_strb = {(XLEN/8){1'b1}};
            end
        end
        if (funct3==`LW) begin
            if (offset==2'h0) begin
                get_rd_strb = {(XLEN/8){1'b1}};
            end else if (offset==2'h1) begin
                get_rd_strb = {{(XLEN/8-3){1'b0}},3'b111};
            end else if (offset==2'h2) begin
                get_rd_strb = {{(XLEN/8-2){1'b0}},2'b11};
            end else if (offset==2'h3) begin
                get_rd_strb = {{(XLEN/8-1){1'b0}},1'b1};
            end
        end

    endfunction


    ///////////////////////////////////////////////////////////////////////////
    //
    // Parameters and variables declaration
    //
    ///////////////////////////////////////////////////////////////////////////

    localparam MAX_OR = 8;
    localparam MAX_OR_CMP = MAX_OR - 1;
    localparam MAX_OR_W = $clog2(MAX_OR);

    // instructions fields
    logic signed [XLEN        -1:0] addr;
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
    logic        [MAX_OR_W    -1:0] wr_or_cnt;
    logic                           max_wr_or;
    logic        [MAX_OR_W    -1:0] rd_or_cnt;
    logic                           max_rd_or;
    logic                           waiting_wr_cpl;
    logic                           waiting_rd_cpl;
    logic                           memfy_ready_fsm;
    logic                           push_rd_or;
    logic                           rd_or_full;
    logic                           rd_or_empty;
    logic        [2           -1:0] offset;
    logic                           stall_bus;

    typedef enum logic[1:0] {
        IDLE = 0,
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
            awvalid <= 1'b0;
            wvalid <= 1'b0;
            wdata <= {XLEN{1'b0}};
            wstrb <= {XLEN/8{1'b0}};
            araddr <= {AXI_ADDR_W{1'b0}};
            arvalid <= 1'b0;
            arvalid <= 1'b0;
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
            arvalid <= 1'b0;
            opcode_r <= 7'b0;
            state <= IDLE;
            memfy_ready_fsm <= 1'b0;
        end else begin

            case (state)

                // IDLE: LOAD or STORE instruction acknowledgment to instruction controller
                default: begin

                    if ((arvalid && !arready) || 
                        (awvalid && !awready) || (wvalid && !wready))
                    begin

                        // If address handshaked, release the request
                        if (awready) awvalid <= 1'b0;
                        // If data handshaked, stop to issue it
                        if (wready) wvalid <= 1'b0;

                        state <= SERVE;
                        memfy_ready_fsm <= 1'b0;

                    end else if (memfy_valid) begin

                        awaddr <= addr;
                        araddr <= addr;

                        opcode_r <= opcode;

                        // STORE
                        if (opcode==`STORE) begin

                            if (waiting_rd_cpl || arvalid) begin
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
                            if (waiting_wr_cpl || awvalid) begin
                                state <= WAIT;
                                arvalid <= 1'b0;
                            end else begin
                                state <= SERVE;
                                arvalid <= 1'b1;
                            end
                            awvalid <= 1'b0;
                            wvalid <= 1'b0;
                            wstrb <= {XLEN/8{1'b0}};
                            memfy_ready_fsm <= 1'b0;
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

                // SERVE: LOAD or STORE instructions
                SERVE: begin

                    //LOAD
                    if (opcode_r==`LOAD) begin
                        // Stop the request once accepted
                        if (arready) arvalid <= 1'b0;
                        // Wait until addr and data have been acknowledged
                        if (rvalid) begin
                            memfy_ready_fsm <= 1'b1;
                            state <= IDLE;
                        end
                    // STORE
                    end else begin

                        // Stop the request once accepted
                        if (awready) awvalid <= 1'b0;
                        if (wready) wvalid <= 1'b0;

                        // Wait until addr and data have been acknowledged
                        if (awready && wready  ||   // addr & data channel acked on same cycle
                            ~awvalid && wready ||   // addr hass been acked before & data is acked
                            awready && ~wvalid      // addr is acked and data has been acked before
                        ) begin
                            memfy_ready_fsm <= 1'b1;
                            state <= IDLE;
                        end
                    end

                end 

                // WAIT: Wait for all write completion have been received before moving to LOAD
                WAIT: begin

                    if (opcode_r==`LOAD && !waiting_wr_cpl) begin
                        state <= SERVE;
                        arvalid <= 1'b1;
                    end else if (opcode_r==`STORE && !waiting_rd_cpl) begin
                        state <= SERVE;
                        awvalid <= 1'b1;
                        wvalid <= 1'b1;
                    end
                end
            
            endcase
        end
    end

    // Block any further requests if reached a certain number of pending outstanding completions
    assign stall_bus = (state==IDLE) & ((arvalid & !arready) | (awvalid & !awready) | (wvalid & !wready));

    assign memfy_ready = memfy_ready_fsm & !rd_or_full & !stall_bus;
    assign memfy_pending_read = waiting_rd_cpl;

    assign push_rd_or = memfy_valid & memfy_ready & (opcode==`LOAD);

    // Store outstanding read request info for data alignment of the completion
    friscv_scfifo 
    #(
        .PASS_THRU  (0),
        .ADDR_WIDTH (MAX_OR_W),
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


    // Track the current read/write outstanding requests waiting completions
    always @ (posedge aclk or negedge aresetn) begin

        if (!aresetn) begin
            wr_or_cnt <= {MAX_OR_W{1'b0}};
            rd_or_cnt <= {MAX_OR_W{1'b0}};

        end else if (srst) begin
            wr_or_cnt <= {MAX_OR_W{1'b0}};
            rd_or_cnt <= {MAX_OR_W{1'b0}};

        end else begin

            // Write xfers tracker
            if (awvalid && awready && !bvalid && !max_wr_or) begin
                wr_or_cnt <= wr_or_cnt + 1'b1;
            end else if (!(awvalid & awready) && bvalid && bready && wr_or_cnt!={MAX_OR_W{1'b0}}) begin
                wr_or_cnt <= wr_or_cnt - 1'b1;
            end

            // Read xfers tracker
            if (arvalid && arready && !rvalid && !max_rd_or) begin
                rd_or_cnt <= rd_or_cnt + 1'b1;
            end else if (!(arvalid & arready) && rvalid && rready && rd_or_cnt!={MAX_OR_W{1'b0}}) begin
                rd_or_cnt <= rd_or_cnt - 1'b1;
            end

            //synthesis translate_off
            //synopsys translate_off
            if (awvalid && awready && !bvalid && max_wr_or) begin
                $display("ERROR: Memfy: Reached maximum write OR number but continue to issue requets");
            end else if (!awvalid && bvalid && bready && wr_or_cnt=={MAX_OR_W{1'b0}}) begin
                $display("ERROR: Memfy: Freeing a write OR but counter is already 0");
            end

            if (arvalid && arready && !rvalid && max_rd_or) begin
                $display("ERROR: Memfy: Reached maximum write OR number but continue to issue requets");
            end else if (!arvalid && rvalid && rready && rd_or_cnt=={MAX_OR_W{1'b0}}) begin
                $display("ERROR: Memfy: Freeing a write OR but counter is already 0");
            end
            //synopsys translate_on
            //synthesis translate_on
        end
    end

    assign max_wr_or = (wr_or_cnt==MAX_OR_CMP[MAX_OR_W-1:0]) ? 1'b1 : 1'b0;
    assign max_rd_or = (rd_or_cnt==MAX_OR_CMP[MAX_OR_W-1:0]) ? 1'b1 : 1'b0;

    assign waiting_wr_cpl = (wr_or_cnt!={MAX_OR_W{1'b0}}) ? 1'b1 : 1'b0;
    assign waiting_rd_cpl = (rd_or_cnt!={MAX_OR_W{1'b0}}) ? 1'b1 : 1'b0;

    // Manage the RD write operation
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
            // Write into RD once the read data channel handshakes
            memfy_rd_wr <= rvalid && rready && (rd_or_cnt!={MAX_OR_W{1'b0}});
            memfy_rd_addr <= rd_r;
            memfy_rd_strb <= get_rd_strb(funct3_r, offset);
            memfy_rd_val <= get_rd_val(funct3_r, rdata, offset);
        end
    end

    assign memfy_rs1_addr = rs1;
    assign memfy_rs2_addr = rs2;


    // The address to access during a LOAD or a STORE
    assign addr = $signed({{(XLEN-12){imm12[11]}}, imm12}) + $signed(memfy_rs1_val);

    // Unused: information forwarded to control unit for FENCE execution:
    // bit 0: memory write
    // bit 1: memory read
    // bit 2: device output
    // bit 3: device input
    assign memfy_fenceinfo = 4'b0;


    //////////////////////////////////////////////////////////////////////////
    // Unsupported / constant AXI4-lite signals
    //////////////////////////////////////////////////////////////////////////

    assign awid = {AXI_ID_W{1'b0}} | AXI_ID_MASK;
    assign awprot = 3'b0;
    assign bready = 1'b1;
    assign rready = 1'b1;

    assign arid = {AXI_ID_W{1'b0}} | AXI_ID_MASK;
    assign arprot = 3'b0;


    //////////////////////////////////////////////////////////////////////////
    // Exception flags, driven back to control unit
    //////////////////////////////////////////////////////////////////////////

    // LOAD is not XLEN-boundary aligned
    assign load_misaligned = (opcode==`LOAD && (funct3==`LH || funct3==`LHU) &&
                                (addr[1:0]==2'h3 || addr[1:0]==2'h1))           ? 1'b1 :
                             (opcode==`LOAD && funct3==`LW  && addr[1:0]!=2'b0) ? 1'b1 :
                                                                                  1'b0 ;

    // STORE is not XLEN-boundary aligned
    assign store_misaligned = (opcode==`STORE && funct3==`SH &&
                                (addr[1:0]==2'h3 || addr[1:0]==2'h1))            ? 1'b1 :
                              (opcode==`STORE && funct3==`SW && addr[1:0]!=2'b0) ? 1'b1 :
                                                                                   1'b0 ;

    assign memfy_exceptions[`LD_MA] = load_misaligned & memfy_valid & memfy_ready;

    assign memfy_exceptions[`ST_MA] = store_misaligned & memfy_valid & memfy_ready;

endmodule

`resetall
