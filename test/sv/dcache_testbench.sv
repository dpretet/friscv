// Mandatory file to be able to launch SVUT flow
`include "svut_h.sv"
// Specify the module to load or on files.f
`timescale 1 ns / 100 ps

module dcache_testbench();

    `SVUT_SETUP

    parameter ILEN = 32;
    parameter XLEN = 32;
    parameter OSTDREQ_NUM = 4;
    parameter AXI_ADDR_W = 8;
    parameter AXI_ID_W = 8;
    parameter AXI_DATA_W = 128;
    parameter AXI_ID_MASK = 'h20;
    parameter AXI_REORDER_CPL = 1;
    parameter IO_MAP_NB = 1;
    parameter CACHE_PREFETCH_EN = 0;
    parameter CACHE_BLOCK_W = 128;
    parameter CACHE_DEPTH = 512;

    logic                       aclk;
    logic                       aresetn;
    logic                       srst;
    logic                       memfy_awvalid;
    logic                      memfy_awready;
    logic  [AXI_ADDR_W    -1:0] memfy_awaddr;
    logic  [3             -1:0] memfy_awprot;
    logic  [4             -1:0] memfy_awcache;
    logic  [AXI_ID_W      -1:0] memfy_awid;
    logic                       memfy_wvalid;
    logic                      memfy_wready;
    logic  [XLEN          -1:0] memfy_wdata;
    logic  [XLEN/8        -1:0] memfy_wstrb;
    logic                      memfy_bvalid;
    logic                       memfy_bready;
    logic [AXI_ID_W      -1:0] memfy_bid;
    logic [2             -1:0] memfy_bresp;
    logic                       memfy_arvalid;
    logic                      memfy_arready;
    logic  [AXI_ADDR_W    -1:0] memfy_araddr;
    logic  [3             -1:0] memfy_arprot;
    logic  [4             -1:0] memfy_arcache;
    logic  [AXI_ID_W      -1:0] memfy_arid;
    logic                      memfy_rvalid;
    logic                       memfy_rready;
    logic [AXI_ID_W      -1:0] memfy_rid;
    logic [2             -1:0] memfy_rresp;
    logic [XLEN          -1:0] memfy_rdata;
    logic                      dcache_awvalid;
    logic                       dcache_awready;
    logic [AXI_ADDR_W    -1:0] dcache_awaddr;
    logic [8             -1:0] dcache_awlen;
    logic [3             -1:0] dcache_awsize;
    logic [2             -1:0] dcache_awburst;
    logic [2             -1:0] dcache_awlock;
    logic [4             -1:0] dcache_awcache;
    logic [3             -1:0] dcache_awprot;
    logic [4             -1:0] dcache_awqos;
    logic [4             -1:0] dcache_awregion;
    logic [AXI_ID_W      -1:0] dcache_awid;
    logic                      dcache_wvalid;
    logic                       dcache_wready;
    logic                      dcache_wlast;
    logic [AXI_DATA_W    -1:0] dcache_wdata;
    logic [AXI_DATA_W/8  -1:0] dcache_wstrb;
    logic                       dcache_bvalid;
    logic                      dcache_bready;
    logic  [AXI_ID_W      -1:0] dcache_bid;
    logic  [2             -1:0] dcache_bresp;
    logic                      dcache_arvalid;
    logic                       dcache_arready;
    logic [AXI_ADDR_W    -1:0] dcache_araddr;
    logic [8             -1:0] dcache_arlen;
    logic [3             -1:0] dcache_arsize;
    logic [2             -1:0] dcache_arburst;
    logic [2             -1:0] dcache_arlock;
    logic [4             -1:0] dcache_arcache;
    logic [3             -1:0] dcache_arprot;
    logic [4             -1:0] dcache_arqos;
    logic [4             -1:0] dcache_arregion;
    logic [AXI_ID_W      -1:0] dcache_arid;
    logic                       dcache_rvalid;
    logic                      dcache_rready;
    logic  [AXI_ID_W      -1:0] dcache_rid;
    logic  [2             -1:0] dcache_rresp;
    logic  [AXI_DATA_W    -1:0] dcache_rdata;
    logic                       dcache_rlast;

    friscv_dcache
    #(
    .ILEN              (ILEN),
    .XLEN              (XLEN),
    .OSTDREQ_NUM       (OSTDREQ_NUM),
    .AXI_ADDR_W        (AXI_ADDR_W),
    .AXI_ID_W          (AXI_ID_W),
    .AXI_DATA_W        (AXI_DATA_W),
    .AXI_ID_MASK       (AXI_ID_MASK),
    .AXI_REORDER_CPL   (AXI_REORDER_CPL),
    .IO_MAP_NB         (IO_MAP_NB),
    .CACHE_PREFETCH_EN (CACHE_PREFETCH_EN),
    .CACHE_BLOCK_W     (CACHE_BLOCK_W),
    .CACHE_DEPTH       (CACHE_DEPTH)
    )
    dut
    (
    .aclk            (aclk),
    .aresetn         (aresetn),
    .srst            (srst),
    .memfy_awvalid   (memfy_awvalid),
    .memfy_awready   (memfy_awready),
    .memfy_awaddr    (memfy_awaddr),
    .memfy_awprot    (memfy_awprot),
    .memfy_awcache   (memfy_awcache),
    .memfy_awid      (memfy_awid),
    .memfy_wvalid    (memfy_wvalid),
    .memfy_wready    (memfy_wready),
    .memfy_wdata     (memfy_wdata),
    .memfy_wstrb     (memfy_wstrb),
    .memfy_bvalid    (memfy_bvalid),
    .memfy_bready    (memfy_bready),
    .memfy_bid       (memfy_bid),
    .memfy_bresp     (memfy_bresp),
    .memfy_arvalid   (memfy_arvalid),
    .memfy_arready   (memfy_arready),
    .memfy_araddr    (memfy_araddr),
    .memfy_arprot    (memfy_arprot),
    .memfy_arcache   (memfy_arcache),
    .memfy_arid      (memfy_arid),
    .memfy_rvalid    (memfy_rvalid),
    .memfy_rready    (memfy_rready),
    .memfy_rid       (memfy_rid),
    .memfy_rresp     (memfy_rresp),
    .memfy_rdata     (memfy_rdata),
    .dcache_awvalid  (dcache_awvalid),
    .dcache_awready  (dcache_awready),
    .dcache_awaddr   (dcache_awaddr),
    .dcache_awlen    (dcache_awlen),
    .dcache_awsize   (dcache_awsize),
    .dcache_awburst  (dcache_awburst),
    .dcache_awlock   (dcache_awlock),
    .dcache_awcache  (dcache_awcache),
    .dcache_awprot   (dcache_awprot),
    .dcache_awqos    (dcache_awqos),
    .dcache_awregion (dcache_awregion),
    .dcache_awid     (dcache_awid),
    .dcache_wvalid   (dcache_wvalid),
    .dcache_wready   (dcache_wready),
    .dcache_wlast    (dcache_wlast),
    .dcache_wdata    (dcache_wdata),
    .dcache_wstrb    (dcache_wstrb),
    .dcache_bvalid   (dcache_bvalid),
    .dcache_bready   (dcache_bready),
    .dcache_bid      (dcache_bid),
    .dcache_bresp    (dcache_bresp),
    .dcache_arvalid  (dcache_arvalid),
    .dcache_arready  (dcache_arready),
    .dcache_araddr   (dcache_araddr),
    .dcache_arlen    (dcache_arlen),
    .dcache_arsize   (dcache_arsize),
    .dcache_arburst  (dcache_arburst),
    .dcache_arlock   (dcache_arlock),
    .dcache_arcache  (dcache_arcache),
    .dcache_arprot   (dcache_arprot),
    .dcache_arqos    (dcache_arqos),
    .dcache_arregion (dcache_arregion),
    .dcache_arid     (dcache_arid),
    .dcache_rvalid   (dcache_rvalid),
    .dcache_rready   (dcache_rready),
    .dcache_rid      (dcache_rid),
    .dcache_rresp    (dcache_rresp),
    .dcache_rdata    (dcache_rdata),
    .dcache_rlast    (dcache_rlast)
    );


    // To create a clock:
    // initial aclk = 0;
    // always #2 aclk = ~aclk;

    // To dump data for visualization:
    // initial begin
    //     $dumpfile("dcache_testbench.vcd");
    //     $dumpvars(0, dcache_testbench);
    // end

    // Setup time format when printing with $realtime()
    initial $timeformat(-9, 1, "ns", 8);

    task setup(msg="");
    begin
        // setup() runs when a test begins
    end
    endtask

    task teardown(msg="");
    begin
        // teardown() runs when a test ends
    end
    endtask

    `TEST_SUITE("TESTSUITE_NAME")

    //  Available macros:"
    //
    //    - `MSG("message"):       Print a raw white message
    //    - `INFO("message"):      Print a blue message with INFO: prefix
    //    - `SUCCESS("message"):   Print a green message if SUCCESS: prefix
    //    - `WARNING("message"):   Print an orange message with WARNING: prefix and increment warning counter
    //    - `CRITICAL("message"):  Print a purple message with CRITICAL: prefix and increment critical counter
    //    - `ERROR("message"):     Print a red message with ERROR: prefix and increment error counter
    //
    //    - `FAIL_IF(aSignal):                 Increment error counter if evaluaton is true
    //    - `FAIL_IF_NOT(aSignal):             Increment error coutner if evaluation is false
    //    - `FAIL_IF_EQUAL(aSignal, 23):       Increment error counter if evaluation is equal
    //    - `FAIL_IF_NOT_EQUAL(aSignal, 45):   Increment error counter if evaluation is not equal
    //    - `ASSERT(aSignal):                  Increment error counter if evaluation is not true
    //    - `ASSERT((aSignal == 0)):           Increment error counter if evaluation is not true
    //
    //  Available flag:
    //
    //    - `LAST_STATUS: tied to 1 is last macro did experience a failure, else tied to 0

    `UNIT_TEST("TESTCASE_NAME")

        // Describe here the testcase scenario
        //
        // Because SVUT uses long nested macros, it's possible
        // some local variable declaration leads to compilation issue.
        // You should declare your variables after the IOs declaration to avoid that.

    `UNIT_TEST_END

    `TEST_SUITE_END

endmodule
