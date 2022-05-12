// distributed under the mit license
// https://opensource.org/licenses/mit-license.php

`timescale 1 ns / 1 ps
`default_nettype none

///////////////////////////////////////////////////////////////////////////////
// A simple AXI4-lite RAM model, simulation only. Dual port which can be with
// different widths.
//
// Limitations:
// - assume only a power of two ratio between ports' data width
///////////////////////////////////////////////////////////////////////////////

module axi4l_ram

    #(
        parameter INIT  = "init.v",
        // Address bus width defined for both control and AXI4 address signals
        parameter AXI_ADDR_W = 8,
        // AXI ID width, setup by default to 8 and unused
        parameter AXI_ID_W = 8,
        // AXI4 data width, independant of control unit width
        parameter AXI1_DATA_W = 8,
        parameter AXI2_DATA_W = 8,
        // Number of outstanding requests supported
        parameter OSTDREQ_NUM = 4
    )(
        // Global signals
        input  logic                      aclk,
        input  logic                      aresetn,
        input  logic                      srst,
        // AXI4-lite write channels interface
        input  logic                      p1_awvalid,
        output logic                      p1_awready,
        input  logic [AXI_ADDR_W    -1:0] p1_awaddr,
        input  logic [3             -1:0] p1_awprot,
        input  logic [AXI_ID_W      -1:0] p1_awid,
        input  logic                      p1_wvalid,
        output logic                      p1_wready,
        input  logic [AXI1_DATA_W   -1:0] p1_wdata,
        input  logic [AXI1_DATA_W/8 -1:0] p1_wstrb,
        output logic [AXI_ID_W      -1:0] p1_bid,
        output logic [2             -1:0] p1_bresp,
        output logic                      p1_bvalid,
        input  logic                      p1_bready,
        // AXI4-lite read channels interface
        input  logic                      p1_arvalid,
        output logic                      p1_arready,
        input  logic [AXI_ADDR_W    -1:0] p1_araddr,
        input  logic [3             -1:0] p1_arprot,
        input  logic [AXI_ID_W      -1:0] p1_arid,
        output logic                      p1_rvalid,
        input  logic                      p1_rready,
        output logic [AXI_ID_W      -1:0] p1_rid,
        output logic [2             -1:0] p1_rresp,
        output logic [AXI1_DATA_W   -1:0] p1_rdata,
        // AXI4-lite write channels interface
        input  logic                      p2_awvalid,
        output logic                      p2_awready,
        input  logic [AXI_ADDR_W    -1:0] p2_awaddr,
        input  logic [3             -1:0] p2_awprot,
        input  logic [AXI_ID_W      -1:0] p2_awid,
        input  logic                      p2_wvalid,
        output logic                      p2_wready,
        input  logic [AXI2_DATA_W   -1:0] p2_wdata,
        input  logic [AXI2_DATA_W/8 -1:0] p2_wstrb,
        output logic [AXI_ID_W      -1:0] p2_bid,
        output logic [2             -1:0] p2_bresp,
        output logic                      p2_bvalid,
        input  logic                      p2_bready,
        // AXI4-lite read channels interface
        input  logic                      p2_arvalid,
        output logic                      p2_arready,
        input  logic [AXI_ADDR_W    -1:0] p2_araddr,
        input  logic [3             -1:0] p2_arprot,
        input  logic [AXI_ID_W      -1:0] p2_arid,
        output logic                      p2_rvalid,
        input  logic                      p2_rready,
        output logic [AXI_ID_W      -1:0] p2_rid,
        output logic [2             -1:0] p2_rresp,
        output logic [AXI2_DATA_W   -1:0] p2_rdata
    );

    ///////////////////////////////////////////////////////////////////////////
    // Parameters and signals declarations
    ///////////////////////////////////////////////////////////////////////////

    parameter AXI_DATA_W = (AXI1_DATA_W>AXI2_DATA_W) ? AXI1_DATA_W : AXI2_DATA_W;
    parameter ADDR_LSB_W = $clog2(AXI_DATA_W/8);
    parameter ADDRW = AXI_ADDR_W-ADDR_LSB_W;

    logic [AXI_DATA_W-1:0] mem [2**ADDRW-1:0];
    integer f;

    initial $readmemh(INIT, mem, 0, 2**ADDRW-1);

    `ifndef NO_RAM_LOG
    initial f = $fopen("axi4lite_ram.txt","w");
    `endif

    integer                   p1_random;
    integer                   p1_rcounter;

    logic [8            -1:0] p1_wr_position;
    logic [8            -1:0] p1_rd_position;
    logic [AXI_ADDR_W   -1:0] p1_araddr_s;
    logic [AXI_ID_W     -1:0] p1_awid_s;
    logic [AXI_ID_W     -1:0] p1_arid_s;

    logic                     p1_raddr_full;
    logic                     p1_raddr_pull;
    logic                     p1_raddr_empty;

    integer                   p2_random;
    integer                   p2_rcounter;

    logic [8            -1:0] p2_wr_position;
    logic [8            -1:0] p2_rd_position;
    logic [AXI_ADDR_W   -1:0] p2_araddr_s;
    logic [AXI_ID_W  -1:0   ] p2_awid_s;
    logic [AXI_ID_W     -1:0] p2_arid_s;

    logic                     p2_raddr_full;
    logic                     p2_raddr_pull;
    logic                     p2_raddr_empty;

    logic                     p1_awaddr_full;
    logic                     p1_awaddr_empty;
    logic                     p1_wdata_full;
    logic                     p1_wdata_empty;
    logic                     p1_wpull;
    logic [AXI_ADDR_W-1:0   ] p1_awaddr_s;
    logic [AXI1_DATA_W-1:0  ] p1_wdata_s;
    logic [AXI1_DATA_W/8-1:0] p1_wstrb_s;
    logic                     p2_awaddr_full;
    logic                     p2_awaddr_empty;
    logic                     p2_wdata_full;
    logic                     p2_wdata_empty;
    logic                     p2_wpull;
    logic [AXI_ADDR_W-1:0   ] p2_awaddr_s;
    logic [AXI2_DATA_W-1:0  ] p2_wdata_s;
    logic [AXI2_DATA_W/8-1:0] p2_wstrb_s;

    logic [32            -1:0] p1_awready_lfsr;
    logic [32            -1:0] p2_awready_lfsr;
    logic [32            -1:0] p1_aw_lfsr;
    logic [32            -1:0] p2_aw_lfsr;
    logic [32            -1:0] p1_arready_lfsr;
    logic [32            -1:0] p2_arready_lfsr;
    logic [32            -1:0] p1_ar_lfsr;
    logic [32            -1:0] p2_ar_lfsr;

    logic [32            -1:0] p1_r_lfsr;
    logic [32            -1:0] p1_rvalid_lfsr;
    logic [32            -1:0] p2_r_lfsr;
    logic [32            -1:0] p2_rvalid_lfsr;

    ///////////////////////////////////////////////////////////////////////////
    // Read address channels, store info to perform the read accesses
    ///////////////////////////////////////////////////////////////////////////

    friscv_scfifo
    #(
        .ADDR_WIDTH ($clog2(OSTDREQ_NUM)),
        .DATA_WIDTH (AXI_ID_W+AXI_ADDR_W)
    )
    p1_archannel_fifo
    (
        .aclk     (aclk),
        .aresetn  (aresetn),
        .srst     (srst),
        .flush    (1'b0),
        .data_in  ({p1_arid, p1_araddr}),
        .push     (p1_arvalid & p1_arready),
        .full     (p1_raddr_full),
        .data_out ({p1_arid_s, p1_araddr_s}),
        .pull     (p1_raddr_pull),
        .empty    (p1_raddr_empty)
    );

    always @ (posedge aclk or negedge aresetn) begin

        if (~aresetn) begin
            p1_arready_lfsr <= 32'b0;
        end else if (srst) begin
            p1_arready_lfsr <= 32'b0;
        end else begin
            // At startup init with LFSR default value
            if (p1_arready_lfsr==32'b0) begin
                p1_arready_lfsr <= p1_ar_lfsr;
            // Use to randomly assert arready
            end else if (~p1_arready) begin
                p1_arready_lfsr <= p1_arready_lfsr >> 1;
            end else if (p1_arvalid) begin
                p1_arready_lfsr <= p1_ar_lfsr;
            end
        end
    end

    assign p1_arready = p1_arready_lfsr[0] & ~p1_raddr_full;

    lfsr32
    #(
        .KEY ('hCCCCCCCC)
    )
    p1_arch_lfsr
    (
        .aclk    (aclk),
        .aresetn (aresetn),
        .srst    (srst),
        .en      (p1_arvalid & p1_arready),
        .lfsr    (p1_ar_lfsr)
    );


    friscv_scfifo
    #(
        .ADDR_WIDTH ($clog2(OSTDREQ_NUM)),
        .DATA_WIDTH (AXI_ID_W+AXI_ADDR_W)
    )
    p2_archannel_fifo
    (
        .aclk     (aclk),
        .aresetn  (aresetn),
        .srst     (srst),
        .flush    (1'b0),
        .data_in  ({p2_arid, p2_araddr}),
        .push     (p2_arvalid & p2_arready),
        .full     (p2_raddr_full),
        .data_out ({p2_arid_s, p2_araddr_s}),
        .pull     (p2_raddr_pull),
        .empty    (p2_raddr_empty)
    );

    always @ (posedge aclk or negedge aresetn) begin

        if (~aresetn) begin
            p2_arready_lfsr <= 32'b0;
        end else if (srst) begin
            p2_arready_lfsr <= 32'b0;
        end else begin
            // At startup init with LFSR default value
            if (p2_arready_lfsr==32'b0) begin
                p2_arready_lfsr <= p2_ar_lfsr;
            // Use to randomly assert arready
            end else if (~p2_arready) begin
                p2_arready_lfsr <= p2_arready_lfsr >> 1;
            end else if (p2_arvalid) begin
                p2_arready_lfsr <= p2_ar_lfsr;
            end
        end
    end

    assign p2_arready = p2_arready_lfsr[0] & ~p2_raddr_full;

    lfsr32
    #(
        .KEY ('h1C6CDCC5)
    )
    p2_arch_lfsr
    (
        .aclk    (aclk),
        .aresetn (aresetn),
        .srst    (srst),
        .en      (p2_arvalid & p2_arready),
        .lfsr    (p2_ar_lfsr)
    );



    ///////////////////////////////////////////////////////////////////////////
    // Read data channels, complete the read requets
    ///////////////////////////////////////////////////////////////////////////

    assign p1_raddr_pull = p1_rvalid & p1_rready;
    assign p2_raddr_pull = p2_rvalid & p2_rready;

    always @ (posedge aclk or negedge aresetn) begin

        if (~aresetn) begin
            p1_rvalid_lfsr <= 32'b0;
        end else if (srst) begin
            p1_rvalid_lfsr <= 32'b0;
        end else begin
            // At startup init with LFSR default value
            if (p1_rvalid_lfsr==32'b0) begin
                p1_rvalid_lfsr <= p1_r_lfsr;
            // Use to randomly assert bvalid/wready
            end else if (~p1_rvalid) begin
                p1_rvalid_lfsr <= p1_rvalid_lfsr >> 1;
            end else if (p1_rready) begin
                p1_rvalid_lfsr <= p1_r_lfsr;
                `ifndef NO_RAM_LOG
                $fwrite(f, "(@ %0t) Port 1 - Read  Addr=%x Data=%x\n", $realtime, p1_araddr_s, p1_rdata);
                `endif
            end
        end
    end

    lfsr32
    #(
    .KEY (32'h986A23CC)
    )
    p1_rch_lfsr
    (
    .aclk    (aclk),
    .aresetn (aresetn),
    .srst    (srst),
    .en      (p1_rvalid & p1_rready),
    .lfsr    (p1_r_lfsr)
    );

    assign p1_rvalid = p1_rvalid_lfsr[0] & ~p1_raddr_empty;

    // Get the position in the RAM line in bits:
    //  - p1_araddr_s[0+:ADDR_LSB_W] : get the start address in byte
    //  - /4 : convert it in instruction index (if 4 instructions per line, can be 0-1-2-3)
    //         divide by 4 because XLEN = 32 bits = 4 bytes
    //  - *32 : convert the instruction index in bits
    assign p1_rd_position = (p1_araddr_s[0+:ADDR_LSB_W]/4)*32;

    generate if (AXI1_DATA_W<AXI_DATA_W) begin: P1_RD_DOWSIZE
        assign p1_rdata = mem[p1_araddr_s[ADDR_LSB_W+:ADDRW]][p1_rd_position+:AXI1_DATA_W];
    end else begin: P1_RD_NO_CONVERSION
        assign p1_rdata = mem[p1_araddr_s[ADDR_LSB_W+:ADDRW]][0+:AXI1_DATA_W];
    end
    endgenerate

    assign p1_rid = p1_arid_s;
    assign p1_rresp = 2'b0;

    always @ (posedge aclk or negedge aresetn) begin

        if (~aresetn) begin
            p2_rvalid_lfsr <= 32'b0;
        end else if (srst) begin
            p2_rvalid_lfsr <= 32'b0;
        end else begin
            // At startup init with LFSR default value
            if (p2_rvalid_lfsr==32'b0) begin
                p2_rvalid_lfsr <= p2_r_lfsr;
            // Use to randomly assert bvalid/wready
            end else if (~p2_rvalid) begin
                p2_rvalid_lfsr <= p2_rvalid_lfsr >> 1;
            end else if (p2_rready) begin
                p2_rvalid_lfsr <= p2_r_lfsr;
                `ifndef NO_RAM_LOG
                $fwrite(f, "(@ %0t) Port 2 - Read  Addr=%x Data=%x\n", $realtime, p1_araddr_s, p1_rdata);
                `endif
            end
        end
    end

    lfsr32
    #(
    .KEY (32'h4567CCA0)
    )
    p2_rch_lfsr
    (
    .aclk    (aclk),
    .aresetn (aresetn),
    .srst    (srst),
    .en      (p2_rvalid & p2_rready),
    .lfsr    (p2_r_lfsr)
    );

    assign p2_rvalid = p2_rvalid_lfsr[0] & ~p2_raddr_empty;
    // always @ (posedge aclk or negedge aresetn) begin
//
        // if (~aresetn) begin
            // p2_rvalid <= 1'b0;
        // end else if (srst) begin
            // p2_rvalid <= 1'b0;
        // end else begin
            // p2_rvalid <= p2_rvalid_lfsr[0] & ~p2_raddr_empty;
        // end
    // end

    // Get the position in the RAM line in bits:
    //  - p2_araddr_s[0+:ADDR_LSB_W] : get the start address in byte
    //  - /4 : convert it in instruction index (if 4 instructions per line, can be 0-1-2-3)
    //         divide by 4 because XLEN = 32 bits = 4 bytes
    //  - *32 : convert the instruction index in bits
    assign p2_rd_position = (p2_araddr_s[0+:ADDR_LSB_W]/4)*32;

    generate if (AXI2_DATA_W<AXI_DATA_W) begin: P2_RD_DOWSIZE
        assign p2_rdata = mem[p2_araddr_s[ADDR_LSB_W+:ADDRW]][p2_rd_position+:AXI2_DATA_W];
    end else begin: P2_RD_NO_CONVERSION
        assign p2_rdata = mem[p2_araddr_s[ADDR_LSB_W+:ADDRW]][0+:AXI2_DATA_W];
    end
    endgenerate

    assign p2_rid = p2_arid_s;
    assign p2_rresp = 2'b0;


    ///////////////////////////////////////////////////////////////////////////
    // Write address channels, store info to perform the write accesses
    ///////////////////////////////////////////////////////////////////////////

    friscv_scfifo
    #(
        .ADDR_WIDTH ($clog2(OSTDREQ_NUM)),
        .DATA_WIDTH (AXI_ADDR_W+AXI_ID_W)
    )
    p1_awchannel_fifo
    (
        .aclk     (aclk),
        .aresetn  (aresetn),
        .srst     (srst),
        .flush    (1'b0),
        .data_in  ({p1_awid, p1_awaddr}),
        .push     (p1_awvalid & p1_awready),
        .full     (p1_awaddr_full),
        .data_out ({p1_awid_s, p1_awaddr_s}),
        .pull     (p1_wpull),
        .empty    (p1_awaddr_empty)
    );

    always @ (posedge aclk or negedge aresetn) begin

        if (~aresetn) begin
            p1_awready_lfsr <= 32'b0;
        end else if (srst) begin
            p1_awready_lfsr <= 32'b0;
        end else begin
            // At startup init with LFSR default value
            if (p1_awready_lfsr==32'b0) begin
                p1_awready_lfsr <= p1_aw_lfsr;
            // Use to randomly assert awready/wready
            end else if (~p1_awready) begin
                p1_awready_lfsr <= p1_awready_lfsr >> 1;
            end else if (p1_awvalid) begin
                p1_awready_lfsr <= p1_aw_lfsr;
            end
        end
    end

    lfsr32
    #(
        .KEY (32'h8711CBAA)
    )
    p1_awch_lfsr
    (
        .aclk    (aclk),
        .aresetn (aresetn),
        .srst    (srst),
        .en      (p1_awvalid & p1_awready),
        .lfsr    (p1_aw_lfsr)
    );

    assign p1_awready = p1_awready_lfsr[0] & ~p1_wdata_full & ~p1_awaddr_full;

    friscv_scfifo
    #(
        .ADDR_WIDTH ($clog2(OSTDREQ_NUM)),
        .DATA_WIDTH (AXI_ADDR_W+AXI_ID_W)
    )
    p2_awchannel_fifo
    (
        .aclk     (aclk),
        .aresetn  (aresetn),
        .srst     (srst),
        .flush    (1'b0),
        .data_in  ({p2_awid, p2_awaddr}),
        .push     (p2_awvalid & p2_awready),
        .full     (p2_awaddr_full),
        .data_out ({p2_awid_s, p2_awaddr_s}),
        .pull     (p2_wpull),
        .empty    (p2_awaddr_empty)
    );

    always @ (posedge aclk or negedge aresetn) begin

        if (~aresetn) begin
            p2_awready_lfsr <= 32'b0;
        end else if (srst) begin
            p2_awready_lfsr <= 32'b0;
        end else begin
            // At startup init with LFSR default value
            if (p2_awready_lfsr==32'b0) begin
                p2_awready_lfsr <= p2_aw_lfsr;
            // Use to randomly assert awready/wready
            end else if (~p2_awready) begin
                p2_awready_lfsr <= p2_awready_lfsr >> 1;
            end else if (p2_awvalid) begin
                p2_awready_lfsr <= p2_aw_lfsr;
            end
        end
    end

    lfsr32
    #(
        .KEY (32'h12349876)
    )
    p2_awch_lfsr
    (
        .aclk    (aclk),
        .aresetn (aresetn),
        .srst    (srst),
        .en      (p2_awvalid & p2_awready),
        .lfsr    (p2_aw_lfsr)
    );

    assign p2_awready = p2_awready_lfsr[0] & ~p2_wdata_full & ~p2_awaddr_full;


    friscv_scfifo
    #(
        .ADDR_WIDTH ($clog2(OSTDREQ_NUM)),
        .DATA_WIDTH (AXI1_DATA_W+AXI1_DATA_W/8)
    )
    p1_wdata_fifo
    (
        .aclk     (aclk),
        .aresetn  (aresetn),
        .srst     (srst),
        .flush    (1'b0),
        .data_in  ({p1_wstrb,p1_wdata}),
        .push     (p1_wvalid & p1_wready),
        .full     (p1_wdata_full),
        .data_out ({p1_wstrb_s,p1_wdata_s}),
        .pull     (p1_wpull),
        .empty    (p1_wdata_empty)
    );

    assign p1_wready = p1_awready;


    friscv_scfifo
    #(
        .ADDR_WIDTH ($clog2(OSTDREQ_NUM)),
        .DATA_WIDTH (AXI2_DATA_W+AXI2_DATA_W/8)
    )
    p2_wdata_fifo
    (
        .aclk     (aclk),
        .aresetn  (aresetn),
        .srst     (srst),
        .flush    (1'b0),
        .data_in  ({p2_wstrb,p2_wdata}),
        .push     (p2_wvalid & p2_wready),
        .full     (p2_wdata_full),
        .data_out ({p2_wstrb_s,p2_wdata_s}),
        .pull     (p2_wpull),
        .empty    (p2_wdata_empty)
    );

    assign p2_wready = p2_awready;


    ///////////////////////////////////////////////////////////////////////////
    // Write data chennels, perform write operations
    ///////////////////////////////////////////////////////////////////////////

    // Get the position in the RAM line in bits:
    //  - p1_awaddr_s[0+:ADDR_LSB_W] : get the start address in byte
    //  - /4 : convert it in instruction index (if 4 instructions per line, can be 0-1-2-3)
    //         divide by 4 because XLEN = 32 bits = 4 bytes
    //  - *32 : convert the instruction index in bits
    assign p1_wr_position = (p1_awaddr_s[0+:ADDR_LSB_W]/4)*32;

    always @ (posedge aclk or negedge aresetn) begin

        if (~aresetn) begin
            p1_wpull <= 1'b0;
            p1_bvalid <= 1'b0;
            p1_bid <= {AXI_ID_W{1'b0}};
        end else if (srst) begin
            p1_wpull <= 1'b0;
            p1_bvalid <= 1'b0;
            p1_bid <= {AXI_ID_W{1'b0}};
        end else begin

            if (p1_bvalid) begin

                p1_wpull <= 1'b0;
                if (p1_bready) p1_bvalid <= 1'b0;

            end else if (~p1_awaddr_empty && ~p1_wdata_empty) begin

                p1_wpull <= 1'b1;
                p1_bvalid <= 1'b1;
                p1_bid <= p1_awid_s;

                `ifndef NO_RAM_LOG
                $fwrite(f, "(@ %0t) Port 1 - Write Addr=%x Data=%x\n", $realtime, p1_awaddr_s, p1_wdata_s);
                `endif

                if (AXI1_DATA_W<AXI_DATA_W) begin
                    for (int i=0;i<AXI1_DATA_W/8;i++) begin
                        if (p1_wstrb_s[i]) begin
                            mem[p1_awaddr_s[ADDR_LSB_W+:ADDRW]][(p1_wr_position+i*8)+:8] <= p1_wdata_s[8*i+:8];
                        end
                    end
                end else begin
                    for (int i=0;i<AXI_DATA_W/8;i++) begin
                        if (p1_wstrb_s[i]) begin
                            mem[p1_awaddr_s[ADDR_LSB_W+:ADDRW]][8*i+:8] <= p1_wdata_s[8*i+:8];
                        end
                    end
                end
            end else begin
                p1_wpull <= 1'b0;
                p1_bvalid <= 1'b0;
            end
        end
    end

    // Get the position in the RAM line in bits:
    //  - p2_awaddr_s[0+:ADDR_LSB_W] : get the start address in byte
    //  - /4 : convert it in instruction index (if 4 instructions per line, can be 0-1-2-3)
    //         divide by 4 because XLEN = 32 bits = 4 bytes
    //  - *32 : convert the instruction index in bits
    assign p2_wr_position = (p2_awaddr_s[0+:ADDR_LSB_W]/4)*32;

    always @ (posedge aclk or negedge aresetn) begin

        if (~aresetn) begin
            p2_wpull <= 1'b0;
            p2_bvalid <= 1'b0;
            p2_bid <= {AXI_ID_W{1'b0}};
        end else if (srst) begin
            p2_wpull <= 1'b0;
            p2_bvalid <= 1'b0;
            p2_bid <= {AXI_ID_W{1'b0}};
        end else begin

            if (p2_bvalid) begin

                p2_wpull <= 1'b0;
                if (p2_bready) p2_bvalid <= 1'b0;

            end else if (~p2_awaddr_empty && ~p2_wdata_empty) begin

                p2_wpull <= 1'b1;
                p2_bvalid <= 1'b1;
                p2_bid <= p2_awid_s;

                `ifndef NO_RAM_LOG
                $fwrite(f, "(@ %0t) Port 2 - Write Addr=%x Data=%x\n", $realtime, p1_awaddr_s, p1_wdata_s);
                `endif

                if (AXI2_DATA_W<AXI_DATA_W) begin
                    for (int i=0;i<AXI2_DATA_W/8;i++) begin
                        if (p2_wstrb_s[i]) begin
                            mem[p2_awaddr_s[ADDR_LSB_W+:ADDRW]][(p2_wr_position+i*8)+:8] <= p2_wdata_s[8*i+:8];
                        end
                    end
                end else begin
                    for (int i=0;i<AXI_DATA_W/8;i++) begin
                        if (p2_wstrb_s[i]) begin
                            mem[p2_awaddr_s[ADDR_LSB_W+:ADDRW]][8*i+:8] <= p2_wdata_s[8*i+:8];
                        end
                    end
                end
            end else begin
                p2_wpull <= 1'b0;
                p2_bvalid <= 1'b0;
            end
        end
    end


    ///////////////////////////////////////////////////////////////////////////
    // Write reponse chennels, complete the write requests
    ///////////////////////////////////////////////////////////////////////////

    assign p1_bresp = 2'b0;
    assign p2_bresp = 2'b0;

endmodule

`resetall
