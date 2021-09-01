// distributed under the mit license
// https://opensource.org/licenses/mit-license.php

`timescale 1 ns / 1 ps
`default_nettype none

`include "friscv_h.sv"

///////////////////////////////////////////////////////////////////////////////
// Memory controller dedicated to data transfer for LOAD / STORE instructions.
// This module doesn't handle unaligned transfer, which are detected by the
// central controller raising an exception in these situations. the memory
// accesses are handled by an AXI4-lite interface.
//
// TODO: handle 4 KB boundary crossing
//
///////////////////////////////////////////////////////////////////////////////

module friscv_memfy

    #(
        // Architecture selection
        parameter XLEN              = 32,
        // Address bus width defined for both control and AXI4 address signals
        parameter AXI_ADDR_W        = XLEN,
        // AXI ID width, setup by default to 8 and unused
        parameter AXI_ID_W          = 8,
        // AXI4 data width, for instruction and a data bus
        parameter AXI_DATA_W        = XLEN
    )(
        // clock & reset
        input  logic                        aclk,
        input  logic                        aresetn,
        input  logic                        srst,
        // ALU instruction bus
        input  logic                        memfy_en,
        output logic                        memfy_ready,
        output logic                        memfy_empty,
        output logic [4               -1:0] memfy_fenceinfo,
        input  logic [`INST_BUS_W     -1:0] memfy_instbus,
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


    ///////////////////////////////////////////////////////////////////////////
    //
    // Functions declaration
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
    function automatic logic [XLEN-1:0] get_aligned_mem_data(

        input logic [XLEN  -1:0] data,
        input logic [2     -1:0] offset
    );
        if (offset==2'b00) get_aligned_mem_data = data;
        if (offset==2'b01) get_aligned_mem_data = {data[XLEN- 8-1:0], data[XLEN-1-:8]};
        if (offset==2'b10) get_aligned_mem_data = {data[XLEN-16-1:0], data[XLEN-1-:16]};
        if (offset==2'b11) get_aligned_mem_data = {data[XLEN-24-1:0], data[XLEN-1-:24]};

    endfunction

    ///////////////////////////////////////////////////////////////////////////
    // Align the read memory value to write in RD. Right shift the data.
    // Args:
    //      - data: the word to align
    //      - offset: the shift to apply, ADDR's LSBs
    // Returns:
    //      - data aligned ready to store
    ///////////////////////////////////////////////////////////////////////////
    function automatic logic [XLEN-1:0] get_aligned_rd_data(

        input logic [XLEN  -1:0] data,
        input logic [2     -1:0] offset
    );
        if (offset==2'b00) get_aligned_rd_data = data;
        if (offset==2'b01) get_aligned_rd_data = {data[XLEN-24-1:0], data[XLEN-1:8]};
        if (offset==2'b10) get_aligned_rd_data = {data[XLEN-16-1:0], data[XLEN-1:16]};
        if (offset==2'b11) get_aligned_rd_data = {data[XLEN- 8-1:0], data[XLEN-1:24]};

    endfunction

    ///////////////////////////////////////////////////////////////////////////
    // Align the write strobes to write in memory
    // Args:
    //      - strb: the strobes to align
    //      - offset: the shift to apply, ADDR's LSBs
    //      - phase: first (0) or second (1) phase of the request
    // Returns:
    //      - strobes aligned ready to store
    ///////////////////////////////////////////////////////////////////////////
    function automatic logic [XLEN/8-1:0] aligned_strb(

        input logic [XLEN/8-1:0] strb,
        input logic [2     -1:0] offset,
        input logic              phase
    );
        // Return STRB for first request phase
        if (~phase) begin
            if (offset==2'b00) aligned_strb = strb;
            if (offset==2'b01) aligned_strb = {strb[XLEN/8-2:0], 1'b0};
            if (offset==2'b10) aligned_strb = {strb[XLEN/8-3:0], 2'b0};
            if (offset==2'b11) aligned_strb = {strb[XLEN/8-4:0], 3'b0};
        // Return STRB for the second phase
        end else begin
            if (offset==2'b00) aligned_strb = strb;
            if (offset==2'b01) aligned_strb = {3'b0, strb[XLEN/8-1]};
            if (offset==2'b10) aligned_strb = {2'b0, strb[XLEN/8-1-:2]};
            if (offset==2'b11) aligned_strb = {1'b0, strb[XLEN/8-1-:3]};
        end

    endfunction

    ///////////////////////////////////////////////////////////////////////////
    // Create the strobe vector to aply during a STORE instruction
    // Args:
    //      - funct3: opcode's funct3 identifier
    //      - offset: the shift to apply, ADDR's LSBs
    //      - phase: first (0) or second (1) phase of the STORE request
    // Returns:
    //      - the ready to use strobes
    ///////////////////////////////////////////////////////////////////////////
    function automatic logic [XLEN/8-1:0] get_mem_strb(

        input logic [2:0] funct3,
        input logic [1:0] offset,
        input logic       phase
    );
        if (funct3==`SB) get_mem_strb = aligned_strb({{(XLEN/8-1){1'b0}},1'b1}, offset, phase);
        if (funct3==`SH) get_mem_strb = aligned_strb({{(XLEN/8-2){1'b0}},2'b11}, offset, phase);
        if (funct3==`SW) get_mem_strb = aligned_strb({(XLEN/8){1'b1}}, offset, phase);

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

        input logic [3   -1:0] funct3,
        input logic [XLEN-1:0] rdata,
        input logic [2   -1:0] offset
    );
        logic [XLEN-1:0] data_aligned;

        data_aligned = get_aligned_rd_data(rdata, offset);

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

        input logic [3   -1:0] funct3,
        input logic [2   -1:0] offset,
        input logic            phase
    );
        if (funct3==`LB || funct3==`LBU) begin
            get_rd_strb = {(XLEN/8){1'b1}};
        end
        if (funct3==`LH || funct3==`LHU)  begin
            if (offset==2'h3) begin
                if (~phase) begin
                    get_rd_strb = {{(XLEN/8-1){1'b0}},1'b1};
                end else begin
                    get_rd_strb = {{(XLEN/8-1){1'b1}},1'b0};
                end
            end else begin
                get_rd_strb = {(XLEN/8){1'b1}};
            end
        end
        if (funct3==`LW) begin
            if (offset==2'h0) begin
                get_rd_strb = {(XLEN/8){1'b1}};
            end else if (offset==2'h1) begin
                if (~phase) begin
                    get_rd_strb = {{(XLEN/8-3){1'b0}},3'b111};
                end else begin
                    get_rd_strb = {1'b1, {(XLEN/8-1){1'b0}}};
                end
            end else if (offset==2'h2) begin
                if (~phase) begin
                    get_rd_strb = {{(XLEN/8-2){1'b0}},2'b11};
                end else begin
                    get_rd_strb = {2'b11, {(XLEN/8-2){1'b0}}};
                end
            end else if (offset==2'h3) begin
                if (~phase) begin
                    get_rd_strb = {{(XLEN/8-1){1'b0}},1'b1};
                end else begin
                    get_rd_strb = {3'b111, {(XLEN/8-3){1'b0}}};
                end
            end
        end

    endfunction


    ///////////////////////////////////////////////////////////////////////////
    //
    // Parameters and variables declaration
    //
    ///////////////////////////////////////////////////////////////////////////

    // instructions fields
    logic [`OPCODE_W   -1:0] opcode;
    logic [`FUNCT3_W   -1:0] funct3;
    logic [`RS1_W      -1:0] rs1;
    logic [`RS2_W      -1:0] rs2;
    logic [`RD_W       -1:0] rd;
    logic [`IMM12_W    -1:0] imm12;

    logic                    mem_access;
    logic signed [XLEN -1:0] addr;

    logic [`OPCODE_W   -1:0] opcode_r;
    logic [`FUNCT3_W   -1:0] funct3_r;
    logic [`RD_W       -1:0] rd_r;
    logic [XLEN/8      -1:0] mem_strb_w;
    logic                    cross_boundary;
    logic [XLEN/8      -1:0] next_strb;
    logic                    two_phases;
    logic [2           -1:0] offset;


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
            memfy_ready <= 1'b0;
            opcode_r <= 7'b0;
            funct3_r <= 3'b0;
            awaddr <= {AXI_ADDR_W{1'b0}};
            araddr <= {AXI_ADDR_W{1'b0}};
            wdata <= {XLEN{1'b0}};
            wstrb <= {XLEN/8{1'b0}};
            awvalid <= 1'b0;
            wvalid <= 1'b0;
            arvalid <= 1'b0;
            arvalid <= 1'b0;
            rready <= 1'b0;
            next_strb <= {XLEN/8{1'b0}};
            rd_r <= 5'b0;
            two_phases <= 1'b0;
            offset <= 2'b0;
        end else if (srst == 1'b1) begin
            memfy_ready <= 1'b0;
            opcode_r <= 7'b0;
            funct3_r <= 3'b0;
            awaddr <= {AXI_ADDR_W{1'b0}};
            araddr <= {AXI_ADDR_W{1'b0}};
            wdata <= {XLEN{1'b0}};
            wstrb <= {XLEN/8{1'b0}};
            awvalid <= 1'b0;
            wvalid <= 1'b0;
            arvalid <= 1'b0;
            arvalid <= 1'b0;
            rready <= 1'b0;
            next_strb <= {XLEN/8{1'b0}};
            rd_r <= 5'b0;
            two_phases <= 1'b0;
            offset <= 2'b0;
        end else begin

            // LOAD or STORE completion: memory accesses span over multiple
            if (memfy_ready==1'b0) begin
                // LOAD
                if (opcode_r==`LOAD) begin
                    // Stop the request once accepted
                    if (arready) arvalid <= 1'b0;
                    if (rvalid) rready <= 1'b0;
                    if (rvalid && arready || rvalid && ~arvalid) begin
                        memfy_ready <= 1'b1;
                    end
                // STORE
                end else begin
                    // Stop the request once accepted
                    if (awready) awvalid <= 1'b0;
                    if (wready) wvalid <= 1'b0;
                    // Wait until the data has been received
                    if (awready && wready || ~awvalid && wready || awready && ~wvalid) begin
                        memfy_ready <= 1'b1;
                    end
                end

            // LOAD or STORE instruction acknowledgment to instruction controller
            end else if (memfy_en && mem_access) begin

                // Control flow
                memfy_ready <= 1'b0;
                opcode_r <= opcode;
                funct3_r <= funct3;
                rd_r <= rd;

                // request will be executed in two phases because unaligned
                // and targets two memory addresses
                if (cross_boundary) two_phases <= 1'b1;
                else two_phases <= 1'b0;

                // Memory setup
                awaddr <= addr;
                araddr <= addr;
                offset <= addr[1:0];

                // STORE
                if (opcode==`STORE) begin
                    awvalid <= 1'b1;
                    wvalid <= 1'b1;
                    wdata <= get_aligned_mem_data(memfy_rs2_val, addr[1:0]);
                    wstrb <= get_mem_strb(funct3, addr[1:0], 0);
                    next_strb <= get_mem_strb(funct3, addr[1:0], 1);
                // LOAD
                end else begin
                    arvalid <= 1'b1;
                    rready <= 1'b1;
                end

            // Wait for an instruction
            end else begin
                memfy_ready <= 1'b1;
                awvalid <= 1'b0;
                arvalid <= 1'b0;
                arvalid <= 1'b0;
                rready <= 1'b0;
            end
        end

    end

    // Write into RD once the read data channel handshakes
    assign memfy_rd_wr = (~memfy_ready && (opcode_r==`LOAD) &&
                            rvalid && rready 
                         ) ? 1'b1 : 1'b0;
    assign memfy_rd_addr = rd_r;
    assign memfy_rd_val = get_rd_val(funct3_r, rdata, offset);
    assign memfy_rd_strb = get_rd_strb(funct3_r, offset, ~two_phases);

    assign memfy_rs1_addr = rs1;
    assign memfy_rs2_addr = rs2;

    // Indicates a memory access needs to be performed
    assign mem_access = (opcode == `LOAD)  ? 1'b1 :
                        (opcode == `STORE) ? 1'b1 :
                                             1'b0 ;

    // The address to access during a LOAD or a STORE
    assign addr = $signed({{(XLEN-12){imm12[11]}}, imm12}) + $signed(memfy_rs1_val);

    assign cross_boundary = (funct3==`SH  && addr[1:0]==2'h3) ? 1'b1 :
                            (funct3==`SW  && addr[1:0]!=2'b0) ? 1'b1 :
                            (funct3==`LH  && addr[1:0]==2'h3) ? 1'b1 :
                            (funct3==`LHU && addr[1:0]==2'h3) ? 1'b1 :
                            (funct3==`LW  && addr[1:0]!=2'b0) ? 1'b1 :
                                                                1'b0 ;

    // Unused: may be used later to indicate a buffer is
    // empty or not, needed for outstanding request support
    assign memfy_empty = 1'b1;

    // Unused: information forwarded to control unit for FENCE executions:
    // bit 0: memory write
    // bit 1: memory read
    // bit 2: device output
    // bit 3: device input
    assign memfy_fenceinfo = 4'b0;

    //////////////////////////////////////////////////////////////////////////
    // Unsupported AXI4-lite signals
    //////////////////////////////////////////////////////////////////////////

    assign awid = {AXI_ID_W{1'b0}};
    assign awprot = 3'b0;
    assign bready = 1'b1;

    assign arid = {AXI_ID_W{1'b0}};
    assign arprot = 3'b0;

endmodule

`resetall
