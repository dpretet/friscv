// distributed under the mit license
// https://opensource.org/licenses/mit-license.php

`ifndef MEMFY_H
`define MEMFY_H

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

`endif
