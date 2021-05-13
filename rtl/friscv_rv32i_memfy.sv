// copyright damien pretet 2021
// distributed under the mit license
// https://opensource.org/licenses/mit-license.php

`timescale 1 ns / 1 ps
`default_nettype none

`include "friscv_h.sv"

module friscv_rv32i_memfy

    #(
        parameter ADDRW = 16,
        parameter XLEN  = 32
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
        output logic                        mem_en,
        output logic                        mem_wr,
        output logic [ADDRW           -1:0] mem_addr,
        output logic [XLEN            -1:0] mem_wdata,
        output logic [XLEN/8          -1:0] mem_strb,
        input  logic [XLEN            -1:0] mem_rdata,
        input  logic                        mem_ready
    );

    
    ///////////////////////////////////////////////////////////////////////////
    //
    // Functions declarations
    //
    ///////////////////////////////////////////////////////////////////////////
  
    ///////////////////////////////////////////////////////////////////////////
    // Align the read memory value to write in RD. Right shift the data.
    // Args:
    //      - data: the word to align
    //      - offset: the shift to apply, ADDR's LSBs
    // Returns:
    //      - data aligned ready to store
    function automatic logic [XLEN-1:0] get_aligned_mem_data(

        input logic [XLEN  -1:0] data,
        input logic [2     -1:0] offset
    );
        if (offset==2'b00) return data;
        if (offset==2'b01) return {data[XLEN- 8-1:0], data[XLEN-1-:8]};
        if (offset==2'b10) return {data[XLEN-16-1:0], data[XLEN-1-:16]};
        if (offset==2'b11) return {data[XLEN-24-1:0], data[XLEN-1-:24]};

    endfunction

    ///////////////////////////////////////////////////////////////////////////
    // Align the read memory value to write in RD. Right shift the data.
    // Args:
    //      - data: the word to align
    //      - offset: the shift to apply, ADDR's LSBs
    // Returns:
    //      - data aligned ready to store
    function automatic logic [XLEN-1:0] get_aligned_rd_data(

        input logic [XLEN  -1:0] data,
        input logic [2     -1:0] offset
    );
        if (offset==2'b00) return data;
        if (offset==2'b01) return {data[XLEN-24-1:0], data[XLEN-1:8]};
        if (offset==2'b10) return {data[XLEN-16-1:0], data[XLEN-1:16]};
        if (offset==2'b11) return {data[XLEN- 8-1:0], data[XLEN-1:24]};

    endfunction

    ///////////////////////////////////////////////////////////////////////////
    // Align the write strobes to write in memory
    // Args:
    //      - strb: the strobes to align
    //      - offset: the shift to apply, ADDR's LSBs
    //      - phase: first (0) or second (1) phase of the request
    // Returns:
    //      - strobes aligned ready to store
    function automatic logic [XLEN/8-1:0] aligned_strb(

        input logic [XLEN/8-1:0] strb,
        input logic [2     -1:0] offset,
        input logic              phase
    );
        // Return STRB for first request phase
        if (~phase) begin
            if (offset==2'b00) return strb;
            if (offset==2'b01) return {strb[XLEN/8-2:0], 1'b0};
            if (offset==2'b10) return {strb[XLEN/8-3:0], 2'b0};
            if (offset==2'b11) return {strb[XLEN/8-4:0], 3'b0};
        // Return STRB for the second phase
        end else begin
            if (offset==2'b00) return strb;
            if (offset==2'b01) return {3'b0, strb[XLEN/8-1]};
            if (offset==2'b10) return {2'b0, strb[XLEN/8-1-:2]};
            if (offset==2'b11) return {1'b0, strb[XLEN/8-1-:3]};
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
    function automatic logic [XLEN/8-1:0] get_mem_strb(

        input logic [2:0] funct3,
        input logic [1:0] offset,
        input logic       phase
    );
        if (funct3==`SB) return aligned_strb({{(XLEN/8-1){1'b0}},1'b1}, offset, phase);
        if (funct3==`SH) return aligned_strb({{(XLEN/8-2){1'b0}},2'b11}, offset, phase);
        if (funct3==`SW) return aligned_strb({(XLEN/8){1'b1}}, offset, phase);

    endfunction

    ///////////////////////////////////////////////////////////////////////////
    // Create the strobe vector to aply during a RD write 
    // Args:
    //      - funct3: opcode's funct3 identifier
    //      - rdata: the word to align
    //      - offset: the shift to apply, ADDR's LSBs
    // Returns:
    //      - the ready to use strobes
    function automatic logic [XLEN-1:0] get_rd_val(

        input logic [3   -1:0] funct3,
        input logic [XLEN-1:0] rdata,
        input logic [2   -1:0] offset
    );
        logic [XLEN-1:0] data_aligned;

        data_aligned = get_aligned_rd_data(rdata, offset);

        if  (funct3==`LB)  return {{24{data_aligned[7]}}, data_aligned[7:0]};
        if  (funct3==`LBU) return {{24{1'b0}}, data_aligned[7:0]};
        if  (funct3==`LH)  return {{16{data_aligned[15]}}, data_aligned[15:0]};
        if  (funct3==`LHU) return {{16{1'b0}}, data_aligned[15:0]};
        if  (funct3==`LW)  return data_aligned;

    endfunction

    ///////////////////////////////////////////////////////////////////////////
    // Create the strobe vector to aply during a RD write
    // Args:
    //      - funct3: opcode's funct3 identifier
    //      - phase: first (0) or second (1) phase of the STORE request
    // Returns:
    //      - the ready to use strobes
    function automatic logic [XLEN/8-1:0] get_rd_strb(

        input logic [3   -1:0] funct3,
        input logic [2   -1:0] offset,
        input logic            phase
    );
        if (funct3==`LB || funct3==`LBU) begin
            return {{(XLEN/8-1){1'b0}},1'b1};
        end
        if (funct3==`LH || funct3==`LHU)  begin
            if (offset==2'h3) begin
                if (~phase) begin
                    return {{(XLEN/8-1){1'b0}},1'b1};
                end else begin
                    return {{(XLEN/8-2){1'b0}},2'b10};
                end
            end else begin
                return {{(XLEN/8-2){1'b0}},2'b11};
            end
        end
        if (funct3==`LW) begin
            if (offset==2'h0) begin
                return {(XLEN/8){1'b1}};
            end else if (offset==2'h1) begin
                if (~phase) begin
                    return {{(XLEN/8-3){1'b0}},3'b111};
                end else begin
                    return {1'b1, {(XLEN/8-1){1'b0}}};
                end
            end else if (offset==2'h2) begin
                if (~phase) begin
                    return {{(XLEN/8-2){1'b0}},2'b11};
                end else begin
                    return {2'b11, {(XLEN/8-2){1'b0}}};
                end
            end else if (offset==2'h3) begin
                if (~phase) begin
                    return {{(XLEN/8-1){1'b0}},1'b1};
                end else begin
                    return {3'b111, {(XLEN/8-3){1'b0}}};
                end
            end
        end

    endfunction


    ///////////////////////////////////////////////////////////////////////////
    //
    // Parameters and variables declarations
    //
    ///////////////////////////////////////////////////////////////////////////

    // instructions fields
    logic [`OPCODE_W   -1:0] opcode;
    logic [`FUNCT3_W   -1:0] funct3;
    logic [`FUNCT7_W   -1:0] funct7;
    logic [`RS1_W      -1:0] rs1;
    logic [`RS2_W      -1:0] rs2;
    logic [`RD_W       -1:0] rd;
    logic [`ZIMM_W     -1:0] zimm;
    logic [`IMM12_W    -1:0] imm12;
    logic [`IMM20_W    -1:0] imm20;
    logic [`CSR_W      -1:0] csr;
    logic [`SHAMT_W    -1:0] shamt;

    logic                    mem_access;
    logic signed [XLEN -1:0] addr;

    logic [`OPCODE_W   -1:0] opcode_r;
    logic [`FUNCT3_W   -1:0] funct3_r;
    logic [`RD_W       -1:0] rd_r;
    logic [XLEN/8      -1:0] mem_strb_w;
    logic                    is_unaligned;
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
    assign funct7 = memfy_instbus[`FUNCT7 +: `FUNCT7_W];
    assign rs1    = memfy_instbus[`RS1    +: `RS1_W   ];
    assign rs2    = memfy_instbus[`RS2    +: `RS2_W   ];
    assign rd     = memfy_instbus[`RD     +: `RD_W    ];
    assign zimm   = memfy_instbus[`ZIMM   +: `ZIMM_W  ];
    assign imm12  = memfy_instbus[`IMM12  +: `IMM12_W ];
    assign imm20  = memfy_instbus[`IMM20  +: `IMM20_W ];
    assign csr    = memfy_instbus[`CSR    +: `CSR_W   ];
    assign shamt  = memfy_instbus[`SHAMT  +: `SHAMT_W ];


    ///////////////////////////////////////////////////////////////////////////
    //
    // Control circuit managing memory and registers accesses
    //
    ///////////////////////////////////////////////////////////////////////////

    always @ (posedge aclk or negedge aresetn) begin

        if (aresetn == 1'b0) begin
            memfy_ready <= 1'b0;
            opcode_r <= 7'b0;
            funct3_r <= 3'b0;
            mem_en <= 1'b0;
            mem_wr <= 1'b0;
            mem_addr <= {ADDRW{1'b0}};
            mem_wdata <= {XLEN{1'b0}};
            mem_strb <= {XLEN/8{1'b0}};
            next_strb <= {XLEN/8{1'b0}};
            rd_r <= 5'b0;
            two_phases <= 1'b0;
            offset <= 2'b0;
        end else if (srst == 1'b1) begin
            memfy_ready <= 1'b0;
            opcode_r <= 7'b0;
            funct3_r <= 3'b0;
            mem_en <= 1'b0;
            mem_wr <= 1'b0;
            mem_addr <= {ADDRW{1'b0}};
            mem_wdata <= {XLEN{1'b0}};
            mem_strb <= {XLEN/8{1'b0}};
            next_strb <= {XLEN/8{1'b0}};
            rd_r <= 5'b0;
            two_phases <= 1'b0;
            offset <= 2'b0;
        end else begin

            // LOAD or STORE completion: memory accesses span over multiple
            // cycles, thus obliges to pause the pipeline
            // Accepts a new instruction once memory completes the request
            if (mem_en) begin
                if (mem_ready) begin
                    if (opcode_r==`LOAD) begin
                        if (two_phases) begin
                            two_phases <= 1'b0;
                            mem_en <= 1'b1;
                            mem_addr <= mem_addr + 1;
                        end else begin
                            mem_en <= 1'b0;
                            memfy_ready <= 1'b1;
                        end
                    end else begin
                        if (two_phases) begin
                            two_phases <= 1'b0;
                            mem_addr <= mem_addr + 1;
                            mem_strb <= next_strb;
                        end else begin
                            mem_en <= 1'b0;
                            mem_wr <= 1'b0;
                            memfy_ready <= 1'b1;
                        end
                    end
                end

            // LOAD or STORE instruction acknowledgment
            end else if (memfy_en && mem_access) begin

                // Control flow
                memfy_ready <= 1'b0;
                opcode_r <= opcode;
                funct3_r <= funct3;
                // request will be executed in two phases because unaligned
                // and targets two memory addresses
                if (is_unaligned) two_phases <= 1'b1;
                else two_phases <= 1'b0;

                // Memory setup
                mem_en <= 1'b1;
                mem_addr <= {2'b0, addr[ADDRW-1:2]};
                offset <= addr[1:0];
                if (opcode==`STORE) begin
                    mem_wr <= 1'b1;
                    mem_wdata <= get_aligned_mem_data(memfy_rs2_val, addr[1:0]);
                    mem_strb <= get_mem_strb(funct3, addr[1:0], 0);
                    next_strb <= get_mem_strb(funct3, addr[1:0], 1);
                end else begin
                    mem_wr <= 1'b0;
                    mem_wdata <= {XLEN{1'b0}};
                    mem_strb <= {XLEN/8{1'b0}};
                end
               
                // rd registers setup
                rd_r <= rd;

            // Wait for an instruction
            end else begin
                memfy_ready <= 1'b1;
                two_phases <= 1'b0;
                mem_en <= 1'b0;
                mem_wr <= 1'b0;
            end
        end

    end

    assign memfy_rd_wr = (mem_en && mem_ready && (opcode_r==`LOAD)) ? 1'b1 : 1'b0;
    assign memfy_rd_addr = rd_r;
    assign memfy_rd_val = get_rd_val(funct3_r, mem_rdata, offset);
    assign memfy_rd_strb = get_rd_strb(funct3_r, offset, ~two_phases);

    assign memfy_rs1_addr = rs1;
    assign memfy_rs2_addr = rs2;

    // Indicates a memory access needs to be performed
    assign mem_access = (opcode == `LOAD)  ? 1'b1 :
                        (opcode == `STORE) ? 1'b1 :
                                             1'b0 ;

    // The address to access during a LOAD or a STORE
    assign addr = $signed({{(XLEN-12){imm12[11]}}, imm12}) + $signed(memfy_rs1_val);

    assign is_unaligned = (funct3==`SH  && addr[1:0]==2'h3) ? 1'b1 : 
                          (funct3==`SW  && addr[1:0]!=2'b0) ? 1'b1 :
                          (funct3==`LH  && addr[1:0]==2'h3) ? 1'b1 : 
                          (funct3==`LHU && addr[1:0]==2'h3) ? 1'b1 : 
                          (funct3==`LW  && addr[1:0]!=2'b0) ? 1'b1 :
                                                              1'b0 ;

    // Unused: may be used later to indicate a buffer or instructions is 
    // empty or not
    assign memfy_empty = 1'b1;

    // Information forwarded control unit for FENCE executions:
    // bit 0: memory write
    // bit 1: nmemory read
    // bit 2: device output
    // bit 3: device input
    assign memfy_fenceinfo = 4'b0;


endmodule

`resetall
