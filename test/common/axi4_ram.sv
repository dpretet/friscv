// distributed under the mit license
// https://opensource.org/licenses/mit-license.php

`timescale 1 ns / 1 ps
`default_nettype none

`include "svlogger.sv"

///////////////////////////////////////////////////////////////////////////////
// A simple AXI4 RAM model, simulation only. Dual port which can be with
// different widths.
//
// TODO: Manage independant write address and data channel in compliance mode
// TODO: Write response should use LSFR and support compliance vs speed mode
// TODO: Support burst mode
// TODO: Log r/w collision for debug
///////////////////////////////////////////////////////////////////////////////

module axi4_ram

    #(
        // File name used to initalize the RAM content
        parameter INIT  = "init.v",

        // Performance or Compliance mode
        //  - compliance: throttle all channels handshakes to ensure proper back-pressure support
        //  - performance: complete ASAP a read or write request
        parameter MODE = "compliance",

        // Seeds used in LSFR, per channel and port
        parameter P1_RD_ADDR_SEED = 32'h215F0617,
        parameter P1_RD_DATA_SEED = 32'h986A23CC,
        parameter P1_WR_ADDR_SEED = 32'h8711CBAA,
        parameter P1_WR_DATA_SEED = 32'hBC2387AA,
        parameter P1_WR_RESP_SEED = 32'hAC3145BD,
        parameter P2_RD_ADDR_SEED = 32'h1C6CDCC5,
        parameter P2_RD_DATA_SEED = 32'h4567CCA0,
        parameter P2_WR_ADDR_SEED = 32'h12349876,
        parameter P2_WR_DATA_SEED = 32'h567B2433,
        parameter P2_WR_RESP_SEED = 32'h8900AC11,

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
        input  wire  [4             -1:0] p1_awcache,
        input  logic [AXI_ID_W      -1:0] p1_awid,
        input  wire  [8             -1:0] p1_awlen,
        input  wire  [3             -1:0] p1_awsize,
        input  wire  [2             -1:0] p1_awburst,
        input  wire  [4             -1:0] p1_awregion,
        input  wire  [4             -1:0] p1_awqos,
        input  logic                      p1_awlock,
        input  logic                      p1_wvalid,
        output logic                      p1_wready,
        input  logic                      p1_wlast,
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
        input  wire  [4             -1:0] p1_arcache,
        input  logic [AXI_ID_W      -1:0] p1_arid,
        input  wire  [8             -1:0] p1_arlen,
        input  wire  [4             -1:0] p1_arregion,
        input  wire  [4             -1:0] p1_arqos,
        input  wire  [3             -1:0] p1_arsize,
        input  wire  [2             -1:0] p1_arburst,
        input  logic                      p1_arlock,
        output logic                      p1_rvalid,
        input  logic                      p1_rready,
        output logic                      p1_rlast,
        output logic [AXI_ID_W      -1:0] p1_rid,
        output logic [2             -1:0] p1_rresp,
        output logic [AXI1_DATA_W   -1:0] p1_rdata,
        // AXI4-lite write channels interface
        input  logic                      p2_awvalid,
        output logic                      p2_awready,
        input  logic [AXI_ADDR_W    -1:0] p2_awaddr,
        input  logic [3             -1:0] p2_awprot,
        input  wire  [4             -1:0] p2_awcache,
        input  logic [AXI_ID_W      -1:0] p2_awid,
        input  wire  [8             -1:0] p2_awlen,
        input  wire  [4             -1:0] p2_awregion,
        input  wire  [4             -1:0] p2_awqos,
        input  wire  [3             -1:0] p2_awsize,
        input  wire  [2             -1:0] p2_awburst,
        input  logic                      p2_awlock,
        input  logic                      p2_wvalid,
        output logic                      p2_wready,
        input  logic                      p2_wlast,
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
        input  wire  [4             -1:0] p2_arcache,
        input  logic [AXI_ID_W      -1:0] p2_arid,
        input  wire  [8             -1:0] p2_arlen,
        input  wire  [4             -1:0] p2_arregion,
        input  wire  [4             -1:0] p2_arqos,
        input  wire  [3             -1:0] p2_arsize,
        input  wire  [2             -1:0] p2_arburst,
        input  logic                      p2_arlock,
        output logic                      p2_rvalid,
        input  logic                      p2_rready,
        output logic                      p2_rlast,
        output logic [AXI_ID_W      -1:0] p2_rid,
        output logic [2             -1:0] p2_rresp,
        output logic [AXI2_DATA_W   -1:0] p2_rdata
    );

    // Logger setup
    `ifdef TRACE_TB_RAM
    initial f = $fopen("trace_tb_ram.txt","w");

    svlogger log;
    initial begin
        log = new("AXI4_RAM",
                  `SVL_VERBOSE_DEBUG,
                  `SVL_ROUTE_FILE);
        log.set_filename("trace_axi4_ram.txt");

    end

    `endif

    ///////////////////////////////////////////////////////////////////////////
    // Parameters and signals declarations
    ///////////////////////////////////////////////////////////////////////////

    parameter RAM_DATA_W = (AXI1_DATA_W>AXI2_DATA_W) ? AXI1_DATA_W : AXI2_DATA_W;
    parameter ADDR_LSB_W = $clog2(RAM_DATA_W/8);
    parameter ADDRW = AXI_ADDR_W-ADDR_LSB_W;

    logic                      p1_ram_wen;
    logic [AXI_ADDR_W    -1:0] p1_ram_awaddr;
    logic [AXI_ID_W      -1:0] p1_ram_awid;
    logic [8             -1:0] p1_ram_awlen;
    logic                      p1_ram_awlock;
    logic [RAM_DATA_W    -1:0] p1_ram_wdata;
    logic [RAM_DATA_W/8  -1:0] p1_ram_strb;
    logic                      p1_ram_block;
    logic                      p1_ram_ren;
    logic [AXI_ADDR_W    -1:0] p1_ram_araddr;
    logic [AXI_ID_W      -1:0] p1_ram_arid;
    logic [8             -1:0] p1_ram_arlen;
    logic                      p1_ram_arlock;
    logic [RAM_DATA_W    -1:0] p1_ram_rdata;
    logic                      p1_ram_rlock;

    logic                      p2_ram_wen;
    logic [AXI_ADDR_W    -1:0] p2_ram_awaddr;
    logic [AXI_ID_W      -1:0] p2_ram_awid;
    logic [8             -1:0] p2_ram_awlen;
    logic                      p2_ram_awlock;
    logic [RAM_DATA_W    -1:0] p2_ram_wdata;
    logic [RAM_DATA_W/8  -1:0] p2_ram_strb;
    logic                      p2_ram_block;
    logic                      p2_ram_ren;
    logic [AXI_ADDR_W    -1:0] p2_ram_araddr;
    logic [AXI_ID_W      -1:0] p2_ram_arid;
    logic [8             -1:0] p2_ram_arlen;
    logic                      p2_ram_arlock;
    logic [RAM_DATA_W    -1:0] p2_ram_rdata;
    logic                      p2_ram_rlock;

    // the memory array
    logic [RAM_DATA_W-1:0] mem [2**ADDRW-1:0];
    // the lock array to track exclusive access
    logic                  lock_token [2**ADDRW-1:0];
    logic [AXI_ID_W  -1:0] lock_id [2**ADDRW-1:0];

    integer f;
    string msg;

    initial $readmemh(INIT, mem, 0, 2**ADDRW-1);

    // init lock array to unreserved
    initial begin
        for (int i=0; i<2**ADDRW; i++) begin
            lock_token[i] = '0;
            lock_id[i] = '0;
        end
    end


    axi4_ram_port

    #(
        .MODE         (MODE),
        .RD_ADDR_SEED (P1_RD_ADDR_SEED),
        .RD_DATA_SEED (P1_RD_DATA_SEED),
        .WR_ADDR_SEED (P1_WR_ADDR_SEED),
        .WR_DATA_SEED (P1_WR_DATA_SEED),
        .WR_RESP_SEED (P1_WR_RESP_SEED),
        .AXI_ADDR_W   (AXI_ADDR_W),
        .AXI_ID_W     (AXI_ID_W),
        .AXI_DATA_W   (AXI1_DATA_W),
        .RAM_DATA_W   (RAM_DATA_W),
        .OSTDREQ_NUM  (OSTDREQ_NUM)
    ) p1_rd_inst (

      .aclk        (aclk),
      .aresetn     (aresetn),
      .srst        (srst),
      .awvalid     (p1_awvalid),
      .awready     (p1_awready),
      .awaddr      (p1_awaddr),
      .awprot      (p1_awprot),
      .awcache     (p1_awcache),
      .awid        (p1_awid),
      .awlen       (p1_awlen),
      .awsize      (p1_awsize),
      .awburst     (p1_awburst),
      .awregion    (p1_awregion),
      .awqos       (p1_awqos),
      .awlock      (p1_awlock),
      .wvalid      (p1_wvalid),
      .wready      (p1_wready),
      .wlast       (p1_wlast),
      .wdata       (p1_wdata),
      .wstrb       (p1_wstrb),
      .bid         (p1_bid),
      .bresp       (p1_bresp),
      .bvalid      (p1_bvalid),
      .bready      (p1_bready),
      .arvalid     (p1_arvalid),
      .arready     (p1_arready),
      .araddr      (p1_araddr),
      .arprot      (p1_arprot),
      .arcache     (p1_arcache),
      .arid        (p1_arid),
      .arlen       (p1_arlen),
      .arregion    (p1_arregion),
      .arqos       (p1_arqos),
      .arsize      (p1_arsize),
      .arburst     (p1_arburst),
      .arlock      (p1_arlock),
      .rvalid      (p1_rvalid),
      .rready      (p1_rready),
      .rlast       (p1_rlast),
      .rid         (p1_rid),
      .rresp       (p1_rresp),
      .rdata       (p1_rdata),
      .ram_wen     (p1_ram_wen),
      .ram_awaddr  (p1_ram_awaddr),
      .ram_awid    (p1_ram_awid),
      .ram_awlock  (p1_ram_awlock),
      .ram_wdata   (p1_ram_wdata),
      .ram_strb    (p1_ram_strb),
      .ram_block   (p1_ram_block),
      .ram_ren     (p1_ram_ren),
      .ram_araddr  (p1_ram_araddr),
      .ram_arid    (p1_ram_arid),
      .ram_arlock  (p1_ram_arlock),
      .ram_rdata   (p1_ram_rdata),
      .ram_rlock   (p1_ram_rlock)
    );

    axi4_ram_port

    #(
        .MODE         (MODE),
        .RD_ADDR_SEED (P2_RD_ADDR_SEED),
        .RD_DATA_SEED (P2_RD_DATA_SEED),
        .WR_ADDR_SEED (P2_WR_ADDR_SEED),
        .WR_DATA_SEED (P2_WR_DATA_SEED),
        .WR_RESP_SEED (P2_WR_RESP_SEED),
        .AXI_ADDR_W   (AXI_ADDR_W),
        .AXI_ID_W     (AXI_ID_W),
        .AXI_DATA_W   (AXI1_DATA_W),
        .RAM_DATA_W   (RAM_DATA_W),
        .OSTDREQ_NUM  (OSTDREQ_NUM)
    ) p2_rd_inst (

      .aclk        (aclk),
      .aresetn     (aresetn),
      .srst        (srst),
      .awvalid     (p2_awvalid),
      .awready     (p2_awready),
      .awaddr      (p2_awaddr),
      .awprot      (p2_awprot),
      .awcache     (p2_awcache),
      .awid        (p2_awid),
      .awlen       (p2_awlen),
      .awsize      (p2_awsize),
      .awburst     (p2_awburst),
      .awregion    (p2_awregion),
      .awqos       (p2_awqos),
      .awlock      (p2_awlock),
      .wvalid      (p2_wvalid),
      .wready      (p2_wready),
      .wlast       (p2_wlast),
      .wdata       (p2_wdata),
      .wstrb       (p2_wstrb),
      .bid         (p2_bid),
      .bresp       (p2_bresp),
      .bvalid      (p2_bvalid),
      .bready      (p2_bready),
      .arvalid     (p2_arvalid),
      .arready     (p2_arready),
      .araddr      (p2_araddr),
      .arprot      (p2_arprot),
      .arcache     (p2_arcache),
      .arid        (p2_arid),
      .arlen       (p2_arlen),
      .arregion    (p2_arregion),
      .arqos       (p2_arqos),
      .arsize      (p2_arsize),
      .arburst     (p2_arburst),
      .arlock      (p2_arlock),
      .rvalid      (p2_rvalid),
      .rready      (p2_rready),
      .rlast       (p2_rlast),
      .rid         (p2_rid),
      .rresp       (p2_rresp),
      .rdata       (p2_rdata),
      .ram_wen     (p2_ram_wen),
      .ram_awaddr  (p2_ram_awaddr),
      .ram_awid    (p2_ram_awid),
      .ram_awlock  (p2_ram_awlock),
      .ram_wdata   (p2_ram_wdata),
      .ram_strb    (p2_ram_strb),
      .ram_block   (p2_ram_block),
      .ram_ren     (p2_ram_ren),
      .ram_araddr  (p2_ram_araddr),
      .ram_arid    (p2_ram_arid),
      .ram_arlock  (p2_ram_arlock),
      .ram_rdata   (p2_ram_rdata),
      .ram_rlock   (p2_ram_rlock)
    );

    `ifdef TRACE_TB_RAM

    always @ (posedge aclk)
    begin

        if (p1_ram_ren) begin

            $sformat(msg, "Read Port1: Addr=%x, ID=%x, Len=%x, Lock=%x",
                p1_ram_araddr, p1_ram_arid, p1_ram_arlen, p1_ram_arlock
            );
            log.info(msg);

            if (p1_ram_arlock) begin
                log.info("Read Port1: Exclusive access granted");
            end
        end

        if (p2_ram_ren) begin

            $sformat(msg, "Read Port2: Addr=%x, ID=%x, Len=%x, Lock=%x",
                p2_ram_araddr, p2_ram_arid, p2_ram_arlen, p2_ram_arlock
            );

            log.info(msg);

            if (p2_ram_arlock) begin
                log.info("Read Port2: Exclusive access granted");
            end

        end

        if (p1_ram_wen) begin

            $sformat(msg, "Write Port1: Addr=%x, ID=%x, Len=%x, Lock=%x",
                p1_ram_awaddr, p1_ram_awid, p1_ram_awlen, p1_ram_awlock
            );
            log.info(msg);

            if (p1_ram_awlock && lock_token[p1_ram_awaddr] && p1_ram_awid == lock_id[p1_ram_awaddr]) begin
                log.info("Write Port1: complete the exclusive access");
            end

            if (p1_ram_awlock && lock_token[p1_ram_awaddr] && lock_id[p1_ram_awaddr] != p1_ram_awid) begin
                log.error("Write Port1: try to complete an exclusive access with the wrong ID");
            end

            if (p1_ram_awlock && !lock_token[p1_ram_awaddr]) begin
                log.error("Write Port1: try to complete an exclusive access on unreserved register");
            end

            if (!p1_ram_awlock && lock_token[p1_ram_awaddr]) begin
                log.error("Write Port1: Exclusive access reservation broken a non-exclusive write access");
            end
        end

        if (p2_ram_wen) begin

            $sformat(msg, "Write Port2: Addr=%x, ID=%x, Len=%x, Lock=%x",
                p2_ram_awaddr, p2_ram_awid, p2_ram_awlen, p2_ram_awlock
            );
            log.info(msg);

            if (p2_ram_awlock && lock_token[p2_ram_awaddr] && p2_ram_awid == lock_id[p2_ram_awaddr]) begin
                log.info("Write Port2: complete the exclusive access");
            end

            if (p2_ram_awlock && lock_token[p2_ram_awaddr] && lock_id[p2_ram_awaddr] != p2_ram_awid) begin
                log.error("Write Port2: try to complete an exclusive access with the wrong ID");
            end

            if (p2_ram_awlock && !lock_token[p2_ram_awaddr]) begin
                log.error("Write Port2: try to complete an exclusive access on unreserved register");
            end

            if (!p2_ram_awlock && lock_token[p2_ram_awaddr]) begin
                log.error("Write Port2: Exclusive access reservation broken a non-exclusive write access");
            end
        end
    end

    `endif


    always @ (posedge aclk) begin

        if (p1_ram_ren) begin
            if (p1_ram_arlock) begin
                lock_token[p1_ram_araddr] <= '1;
                lock_id[p1_ram_araddr] <= p1_ram_arid;
            end
        end

        if (p1_ram_wen) begin

            lock_token[p1_ram_awaddr] <= '0;
            lock_id[p1_ram_awaddr] <= p1_ram_awid;

            if (lock_token[p1_ram_awaddr] && lock_id[p1_ram_awaddr] == p1_ram_awid ||
                !lock_token[p1_ram_awaddr]
               )
                for (int i=0; i<RAM_DATA_W/8; i++)
                    if (p1_ram_strb[i])
                        mem[p1_ram_awaddr][8*i+:8] <= p1_ram_wdata[8*i+:8];;

        end

        if (p2_ram_ren) begin
            if (p2_ram_arlock) begin
                lock_token[p2_ram_araddr] <= '1;
                lock_id[p2_ram_araddr] <= p2_ram_arid;
            end
        end

        if (p2_ram_wen) begin

            lock_token[p2_ram_awaddr] <= '0;
            lock_id[p2_ram_awaddr] <= p1_ram_awid;

            if (lock_token[p2_ram_awaddr] && lock_id[p2_ram_awaddr] == p2_ram_awid ||
                !lock_token[p2_ram_awaddr]
               )
                for (int i=0; i<RAM_DATA_W/8; i++)
                    if (p2_ram_strb[i])
                        mem[p2_ram_awaddr][8*i+:8] <= p2_ram_wdata[8*i+:8];;
        end

    end

    assign p1_ram_rdata = mem[p1_ram_araddr];
    assign p1_ram_rlock = p1_ram_arlock;

    assign p2_ram_rdata = mem[p2_ram_araddr];
    assign p2_ram_rlock = p2_ram_arlock;

    assign p1_ram_block = (lock_token[p1_ram_awaddr] && lock_id[p1_ram_awaddr] == p1_ram_awid);
    assign p2_ram_block = (lock_token[p2_ram_awaddr] && lock_id[p2_ram_awaddr] == p2_ram_awid);

endmodule

`resetall
