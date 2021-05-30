/// Mandatory file to be able to launch SVUT flow
`include "svut_h.sv"

`timescale 1 ns / 100 ps

module friscv_icache_testbench();

    `SVUT_SETUP

    parameter XLEN = 32;
    parameter ADDRW = 16;
    parameter AXI_IDW = 8;
    parameter AXI_DATAW = 128;
    parameter CACHE_LINE_WIDTH = 128;
    parameter CACHE_DEPTH = 512;

    logic                      aclk;
    logic                      aresetn;
    logic                      srst;
    logic                      flush_req;
    logic                      flush_ack;
    logic                      inst_en;
    logic [ADDRW         -1:0] inst_addr;
    logic [XLEN          -1:0] inst_rdata;
    logic                      inst_ready;
    logic [AXI_IDW -1:0]       s_axi_awid;
    logic [ADDRW   -1:0]     s_axi_awaddr;
    logic [7:0]                s_axi_awlen;
    logic [2:0]                s_axi_awsize;
    logic [1:0]                s_axi_awburst;
    logic [1:0]                s_axi_awlock;
    logic [3:0]                s_axi_awcache;
    logic [2:0]                s_axi_awprot;
    logic                      s_axi_awvalid;
    logic                      s_axi_awready;
    logic [AXI_DATAW -1:0]     s_axi_wdata;
    logic [AXI_DATAW/8 -1:0]   s_axi_wstrb;
    logic                      s_axi_wlast;
    logic                      s_axi_wvalid;
    logic                      s_axi_wready;
    logic [AXI_IDW -1:0]       s_axi_bid;
    logic [1:0]                s_axi_bresp;
    logic                      s_axi_bvalid;
    logic                      s_axi_bready;
    logic                      icache_arvalid;
    logic                      icache_arready;
    logic [ADDRW         -1:0] icache_araddr;
    logic [8             -1:0] icache_arlen;
    logic [3             -1:0] icache_arsize;
    logic [2             -1:0] icache_arburst;
    logic [2             -1:0] icache_arlock;
    logic [4             -1:0] icache_arcache;
    logic [3             -1:0] icache_arprot;
    logic [4             -1:0] icache_arqos;
    logic [4             -1:0] icache_arlogicion;
    logic [AXI_IDW       -1:0] icache_arid;
    logic                      icache_rvalid;
    logic                      icache_rready;
    logic                      icache_rlast;
    logic [AXI_IDW       -1:0] icache_rid;
    logic [2             -1:0] icache_rresp;
    logic [AXI_DATAW     -1:0] icache_rdata;

    friscv_icache
    #(
    XLEN,
    ADDRW,
    AXI_IDW,
    AXI_DATAW,
    CACHE_LINE_WIDTH,
    CACHE_DEPTH
    )
    icache
    (
    aclk,
    aresetn,
    srst,
    flush_req,
    flush_ack,
    inst_en,
    inst_addr,
    inst_rdata,
    inst_ready,
    icache_arvalid,
    icache_arready,
    icache_araddr,
    icache_arlen,
    icache_arsize,
    icache_arburst,
    icache_arlock,
    icache_arcache,
    icache_arprot,
    icache_arqos,
    icache_arlogicion,
    icache_arid,
    icache_rvalid,
    icache_rready,
    icache_rid,
    icache_rresp,
    icache_rdata,
    icache_rlast
    );


    axi_ram
    #(
    .ADDR_WIDTH (ADDRW),
    .DATA_WIDTH (AXI_DATAW),
    .STRB_WIDTH (AXI_DATAW/8),
    .ID_WIDTH   (AXI_IDW)
    )
    axi4_ram
    (
    .aclk          (aclk          ),
    .aresetn       (aresetn       ),
    .s_axi_awid    (s_axi_awid    ),
    .s_axi_awaddr  (s_axi_awaddr  ),
    .s_axi_awlen   (s_axi_awlen   ),
    .s_axi_awsize  (s_axi_awsize  ),
    .s_axi_awburst (s_axi_awburst ),
    .s_axi_awlock  (s_axi_awlock  ),
    .s_axi_awcache (s_axi_awcache ),
    .s_axi_awprot  (s_axi_awprot  ),
    .s_axi_awvalid (s_axi_awvalid ),
    .s_axi_awready (s_axi_awready ),
    .s_axi_wdata   (s_axi_wdata   ),
    .s_axi_wstrb   (s_axi_wstrb   ),
    .s_axi_wlast   (s_axi_wlast   ),
    .s_axi_wvalid  (s_axi_wvalid  ),
    .s_axi_wready  (s_axi_wready  ),
    .s_axi_bid     (s_axi_bid     ),
    .s_axi_bresp   (s_axi_bresp   ),
    .s_axi_bvalid  (s_axi_bvalid  ),
    .s_axi_bready  (s_axi_bready  ),
    .s_axi_arid    (icache_arid   ),
    .s_axi_araddr  (icache_araddr ),
    .s_axi_arlen   (icache_arlen  ),
    .s_axi_arsize  (icache_arsize ),
    .s_axi_arburst (icache_arburst),
    .s_axi_arlock  (icache_arlock ),
    .s_axi_arcache (icache_arcache),
    .s_axi_arprot  (icache_arprot ),
    .s_axi_arvalid (icache_arvalid),
    .s_axi_arready (icache_arready),
    .s_axi_rid     (icache_rid    ),
    .s_axi_rdata   (icache_rdata  ),
    .s_axi_rresp   (icache_rresp  ),
    .s_axi_rlast   (icache_rlast  ),
    .s_axi_rvalid  (icache_rvalid ),
    .s_axi_rready  (icache_rready )
    );

    // To create a clock:
    initial aclk = 0;
    always #2 aclk = ~aclk;

    // To dump data for visualization:
    initial begin
    $dumpfile("friscv_icache_testbench.vcd");
    $dumpvars(0, friscv_icache_testbench);
    end

    initial begin
        // $readmemh(INIT, axi4_ram.mem, 0, 2**ADDRW-1);
    end

    task setup(msg="");
    begin
        aresetn=1'b0;
        srst=1'b0;
        flush_req=1'b0;
        inst_en=1'b0;
        inst_addr='h0;
        s_axi_awvalid = 1'b0;
        s_axi_wvalid = 1'b0;
        s_axi_bready = 1'b0;
        repeat (10) @(posedge aclk);
        aresetn=1'b0;
        repeat (10) @(posedge aclk);
    end
    endtask

    task teardown(msg="");
    begin
        /// teardown() runs when a test ends
    end
    endtask

    `TEST_SUITE("iCache Testsuite")

    `UNIT_TEST("Basics")


        inst_en = 1'b1;
        inst_addr = {ADDRW{1'b0}};
        repeat (10) @(posedge aclk);
        inst_en = 1'b0;


    `UNIT_TEST_END

    `TEST_SUITE_END

endmodule
