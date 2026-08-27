// distributed under the mit license
// https://opensource.org/licenses/mit-license.php

`timescale 1 ns / 1 ps
`default_nettype none

module axi4_ram_port

    #(

        // Performance or Compliance mode
        //  - compliance: throttle all channels handshakes to ensure proper back-pressure support
        //  - performance: complete ASAP a read or write request
        parameter MODE = "compliance",

        // Seeds used in LSFR, per channel and port
        parameter RD_ADDR_SEED = 32'h0,
        parameter RD_DATA_SEED = 32'h0,
        parameter WR_ADDR_SEED = 32'h0,
        parameter WR_DATA_SEED = 32'h0,
        parameter WR_RESP_SEED = 32'h0,

        // Address bus width defined for both control and AXI4 address signals
        parameter AXI_ADDR_W = 8,
        // AXI ID width, setup by default to 8 and unused
        parameter AXI_ID_W = 8,
        // AXI4 data width, independant of control unit width
        parameter AXI_DATA_W = 8,
        parameter RAM_DATA_W = 16,
        // Number of outstanding requests supported
        parameter OSTDREQ_NUM = 4
    )(
        // Global signals
        input  logic                      aclk,
        input  logic                      aresetn,
        input  logic                      srst,
        // AXI4 write channels interface
        input  logic                      awvalid,
        output logic                      awready,
        input  logic [AXI_ADDR_W    -1:0] awaddr,
        input  logic [3             -1:0] awprot,
        input  wire  [4             -1:0] awcache,
        input  logic [AXI_ID_W      -1:0] awid,
        input  wire  [8             -1:0] awlen,
        input  wire  [3             -1:0] awsize,
        input  wire  [2             -1:0] awburst,
        input  wire  [4             -1:0] awregion,
        input  wire  [4             -1:0] awqos,
        input  logic                      awlock,
        input  logic                      wvalid,
        output logic                      wready,
        input  logic                      wlast,
        input  logic [AXI_DATA_W    -1:0] wdata,
        input  logic [AXI_DATA_W/8  -1:0] wstrb,
        output logic [AXI_ID_W      -1:0] bid,
        output logic [2             -1:0] bresp,
        output logic                      bvalid,
        input  logic                      bready,
        // AXI4 read channels interface
        input  logic                      arvalid,
        output logic                      arready,
        input  logic [AXI_ADDR_W    -1:0] araddr,
        input  logic [3             -1:0] arprot,
        input  wire  [4             -1:0] arcache,
        input  logic [AXI_ID_W      -1:0] arid,
        input  wire  [8             -1:0] arlen,
        input  wire  [4             -1:0] arregion,
        input  wire  [4             -1:0] arqos,
        input  wire  [3             -1:0] arsize,
        input  wire  [2             -1:0] arburst,
        input  logic                      arlock,
        output logic                      rvalid,
        input  logic                      rready,
        output logic                      rlast,
        output logic [AXI_ID_W      -1:0] rid,
        output logic [2             -1:0] rresp,
        output logic [AXI_DATA_W    -1:0] rdata,
        // RAM block interface
        output logic                      ram_wen,
        output logic [AXI_ADDR_W    -1:0] ram_awaddr,
        output logic [AXI_ID_W      -1:0] ram_awid,
        output logic                      ram_awlock,
        output logic [8             -1:0] ram_awlen,
        output logic [RAM_DATA_W    -1:0] ram_wdata,
        output logic [RAM_DATA_W/8  -1:0] ram_strb,
        input  wire                       ram_block,
        output logic                      ram_ren,
        output logic [AXI_ADDR_W    -1:0] ram_araddr,
        output logic [AXI_ID_W      -1:0] ram_arid,
        output logic [8             -1:0] ram_arlen,
        output logic                      ram_arlock,
        input  wire  [RAM_DATA_W    -1:0] ram_rdata,
        input  wire                       ram_rlock
    );


    localparam BUS_RATIO = (RAM_DATA_W == AXI_DATA_W) ? 1 : 
                           (RAM_DATA_W <  AXI_DATA_W) ? (AXI_DATA_W / RAM_DATA_W) :
                           (RAM_DATA_W >  AXI_DATA_W) ? (RAM_DATA_W / AXI_DATA_W) : 0 ;

    parameter ADDR_LSB_W = $clog2(BUS_RATIO);
    parameter ADDRW = AXI_ADDR_W-ADDR_LSB_W;

    logic [ADDR_LSB_W   -1:0] rd_position;
    logic [AXI_ADDR_W   -1:0] araddr_s;
    logic [AXI_ID_W     -1:0] arid_s;
    logic [8            -1:0] arlen_s;
    logic                     arlock_s;

    logic                     araddr_full;
    logic                     araddr_pull;
    logic                     araddr_empty;

    logic                     awaddr_full;
    logic                     awaddr_empty;
    logic                     wdata_full;
    logic                     wdata_empty;
    logic                     awpull, wpull;

    logic [ADDR_LSB_W   -1:0] wr_position;

    logic [AXI_ADDR_W   -1:0] awaddr_s;
    logic [8            -1:0] awlen_s;
    logic [AXI_ID_W     -1:0] awid_s;
    logic                     awlock_s;

    logic [AXI_DATA_W   -1:0] wdata_s;
    logic [AXI_DATA_W/8 -1:0] wstrb_s;
    logic                     wlast_s;


    ///////////////////////////////////////////////////////////////
    //
    // Read Address Channel
    //
    ///////////////////////////////////////////////////////////////

    friscv_scfifo
    #(
        .ADDR_WIDTH ($clog2(OSTDREQ_NUM)),
        .DATA_WIDTH (AXI_ID_W + AXI_ADDR_W + 8 + 1)
    )
    archannel_fifo
    (
        .aclk     (aclk),
        .aresetn  (aresetn),
        .srst     (srst),
        .flush    (1'b0),
        .data_in  ({arid, araddr, arlen, arlock}),
        .push     (arvalid & arready),
        .full     (araddr_full),
        .data_out ({arid_s, araddr_s, arlen_s, arlock_s}),
        .pull     (araddr_pull),
        .empty    (araddr_empty)
    );

    generate if (MODE=="compliance") begin : READ_ADDR_COMPLIANCE

        logic arready_rnd;

        amba_rnd_ready #(
            RD_ADDR_SEED
        )
        arready_inst(
            aclk, aresetn, srst, arvalid, arready, arready_rnd
        );

        assign arready = arready_rnd & ~araddr_full;

    // Performance mode
    end else begin : READ_ADDR_PERF_MODE

        assign arready = ~araddr_full;

    end
    endgenerate

    ///////////////////////////////////////////////////////////////////////////
    //
    // Read data channels
    //
    ///////////////////////////////////////////////////////////////////////////

    assign araddr_pull = rvalid & rready & rlast;

    generate if (MODE=="compliance") begin : READ_COMPLETION_COMPLIANCE

        logic rvalid_rnd;

        amba_rnd_valid #(
            RD_DATA_SEED
        )
        rvalid_inst
        (
            aclk,aresetn,srst, rvalid,rready,rvalid_rnd
        );

        assign rvalid = rvalid_rnd & ~araddr_empty;

    // Performance Mode
    end else begin : READ_COMPLETION_PERFORMANCE

        assign rvalid = !araddr_empty;

    end
    endgenerate



    generate if (AXI_DATA_W<RAM_DATA_W) begin: RDATA_DOWNSIZE

        assign ram_ren = !araddr_empty & rvalid & rready;
        assign ram_araddr = araddr_s[ADDR_LSB_W+:ADDRW];
        assign ram_arid = arid_s;
        assign ram_arlen = arlen_s;
        assign ram_arlock = arlock_s;

        // Get the position in the RAM line in bits:
        //  - araddr_s[0+:ADDR_LSB_W] : get the start address in byte
        //  - /4 : convert it in instruction index (if 4 instructions per line, can be 0-1-2-3)
        //         divide by 4 because XLEN = 32 bits = 4 bytes
        //  - *32 : convert the instruction index in bits
        assign rd_position = (araddr_s[0+:ADDR_LSB_W]/4)*32;
        assign rdata = ram_rdata[rd_position+:AXI_DATA_W];

    end else begin: RDATA_NO_CONVERSION

        assign ram_ren = !araddr_empty & rvalid & rready;
        assign ram_araddr = araddr_s[ADDR_LSB_W+:ADDRW];
        assign ram_arid = arid_s;
        assign ram_arlen = arlen_s;
        assign ram_arlock = arlock_s;

        assign rd_position = '0;
        assign rdata = ram_rdata[0+:AXI_DATA_W];

    end
    endgenerate

    assign rid = arid_s;

    assign rresp = (ram_rlock & arlock_s) ? 2'h1 : // EXOKAY
                                            2'h0 ; // OKAY

    assign rlast = '1;



    ///////////////////////////////////////////////////////////////////////////
    //
    // Write address channel
    //
    ///////////////////////////////////////////////////////////////////////////

    friscv_scfifo
    #(
        .ADDR_WIDTH ($clog2(OSTDREQ_NUM)),
        .DATA_WIDTH (AXI_ADDR_W + AXI_ID_W + 8 + 1)
    )
    awchannel_fifo
    (
        .aclk     (aclk),
        .aresetn  (aresetn),
        .srst     (srst),
        .flush    (1'b0),
        .data_in  ({awid, awaddr, awlen, awlock}),
        .push     (awvalid & awready),
        .full     (awaddr_full),
        .data_out ({awid_s, awaddr_s, awlen_s, awlock_s}),
        .pull     (awpull),
        .empty    (awaddr_empty)
    );

    generate if (MODE=="compliance") begin : WRITE_ADDR_COMPLIANCE

        logic awready_rnd;

        amba_rnd_ready #(
            WR_ADDR_SEED
        )
        awready_inst (
            aclk, aresetn, srst, awvalid, awready, awready_rnd
        );


        assign awready = awready_rnd & ~wdata_full & ~awaddr_full;

    // Performance Mode
    end else begin: WRITE_ADDR_PERF_MODE

        assign awready = ~wdata_full & ~awaddr_full;

    end
    endgenerate


    ///////////////////////////////////////////////////////////////////////////
    // Write data channel
    ///////////////////////////////////////////////////////////////////////////

    friscv_scfifo
    #(
        .ADDR_WIDTH ($clog2(OSTDREQ_NUM)),
        .DATA_WIDTH (AXI_DATA_W + AXI_DATA_W/8 + 1)
    )
    wdata_fifo
    (
        .aclk     (aclk),
        .aresetn  (aresetn),
        .srst     (srst),
        .flush    (1'b0),
        .data_in  ({wlast,wstrb,wdata}),
        .push     (wvalid & wready),
        .full     (wdata_full),
        .data_out ({wlast_s,wstrb_s,wdata_s}),
        .pull     (wpull),
        .empty    (wdata_empty)
    );

    assign wready = awready;
    assign ram_wen = !awaddr_empty & !wdata_empty & !bvalid;

    generate 

    // FIXME: bugged code, not tested
    if (AXI_DATA_W<RAM_DATA_W) begin: WDATA_UPSIZE

        // Get the position in the RAM line in bits
        assign wr_position = awaddr_s[0+:ADDR_LSB_W];

        assign ram_awaddr = awaddr_s[ADDR_LSB_W+:ADDRW];
        assign ram_awid = awid_s;
        assign ram_awlock = awlock_s;
        assign ram_awlen = awlen_s;

        always @ (*) begin

            ram_wdata = '0;
            ram_strb = '0;

            if (AXI_DATA_W<RAM_DATA_W) begin
                for (int i=0;i<AXI_DATA_W/8;i++) begin
                    if (wstrb_s[i]) begin
                        ram_wdata[(wr_position*AXI_DATA_W + i*8)+:8] = wdata_s[8*i+:8];
                        ram_strb[wr_position*AXI_DATA_W/8 + i] = 1'b1;
                    end
                end
            end else begin
                for (int i=0;i<AXI_DATA_W/8;i++) begin
                    if (wstrb_s[i]) begin
                        ram_wdata[8*i+:8] = wdata_s[8*i+:8];
                        ram_strb[wr_position + i] = 1'b1;
                    end
                end
            end
        end
    end else begin : NO_WDATA_CONVERSION

        assign wr_position = '0;

        assign ram_awaddr = awaddr_s;
        assign ram_awid = awid_s;
        assign ram_awlock = awlock_s;
        assign ram_awlen = awlen_s;
        assign ram_wdata = wdata_s;
        assign ram_strb = wstrb_s;

    end
    endgenerate

    ///////////////////////////////////////////////////////////////////////////
    // Write response channel
    ///////////////////////////////////////////////////////////////////////////

    always @ (posedge aclk or negedge aresetn) begin

        if (!aresetn) begin
            awpull <= 1'b0;
            wpull <= 1'b0;
            bvalid <= 1'b0;
            bid <= '0;
            bresp <= '0;
        end else if (srst) begin
            awpull <= 1'b0;
            wpull <= 1'b0;
            bvalid <= 1'b0;
            bid <= '0;
            bresp <= '0;
        end else begin

            // Under B channel handshake
            if (bvalid) begin

                awpull <= 1'b0;
                wpull <= 1'b0;

                if (bready) begin
                    bvalid <= 1'b0;
                    bresp <= '0;
                    bid <= '0;
                end

            end else if (!awaddr_empty) begin

                awpull <= !wdata_empty & wlast;
                wpull <= !wdata_empty;

                bvalid <= !wdata_empty & wlast;
                bid <= awid_s;

                if (awlock_s)
                    if (ram_block) bresp <= 2'h1; // EXOKAY 
                    else           bresp <= 2'h0; // OKAY

            end else begin
                awpull <= 1'b0;
                wpull <= 1'b0;
                bvalid <= 1'b0;
                bresp <= '0;
                bid <= '0;
            end
        end
    end
endmodule

`resetall
