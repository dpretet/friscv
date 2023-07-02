// Mandatory file to be able to launch SVUT flow
`include "svut_h.sv"
`timescale 1 ns / 100 ps

module dcache_testbench();

    `SVUT_SETUP
    // Maximum request the driver must issue during the execution of a testcase
    `ifdef MAX_TRAFFIC
        parameter MAX_TRAFFIC = `MAX_TRAFFIC;
    `else
        parameter MAX_TRAFFIC = 100;
    `endif
    // Timeout value used for outstanding request monitoring
    `ifdef TIMEOUT
        parameter TIMEOUT = `TIMEOUT;
    `else
        parameter TIMEOUT = 100000;
    `endif
    // LFSR key init
    parameter KEY = 32'h28346450;
    parameter ILEN = 32;
    parameter XLEN = 32;
    parameter OSTDREQ_NUM = 8;
    parameter AXI_ADDR_W = XLEN;
    parameter AXI_ID_W = 8;
    parameter AXI_DATA_W = 128;
    parameter AXI_ID_MASK = 'h20;
    parameter AXI_REORDER_CPL = 1;
    parameter IO_MAP_NB = 1;
    parameter CACHE_PREFETCH_EN = 0;
    parameter CACHE_BLOCK_W = 128;
    parameter CACHE_DEPTH = 512;

    logic                      aclk;
    logic                      aresetn;
    logic                      srst;
    logic                      cache_ready;
    logic                      memfy_awvalid;
    logic                      memfy_awready;
    logic  [AXI_ADDR_W   -1:0] memfy_awaddr;
    logic  [3            -1:0] memfy_awprot;
    logic  [4            -1:0] memfy_awcache;
    logic  [AXI_ID_W     -1:0] memfy_awid;
    logic                      memfy_wvalid;
    logic                      memfy_wready;
    logic  [XLEN         -1:0] memfy_wdata;
    logic  [XLEN/8       -1:0] memfy_wstrb;
    logic                      memfy_bvalid;
    logic                      memfy_bready;
    logic [AXI_ID_W      -1:0] memfy_bid;
    logic [2             -1:0] memfy_bresp;
    logic                      memfy_arvalid;
    logic                      memfy_arready;
    logic  [AXI_ADDR_W   -1:0] memfy_araddr;
    logic  [3            -1:0] memfy_arprot;
    logic  [4            -1:0] memfy_arcache;
    logic  [AXI_ID_W     -1:0] memfy_arid;
    logic                      memfy_rvalid;
    logic                      memfy_rready;
    logic [AXI_ID_W      -1:0] memfy_rid;
    logic [2             -1:0] memfy_rresp;
    logic [XLEN          -1:0] memfy_rdata;
    logic                      dcache_awvalid;
    logic                      dcache_awready;
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
    logic                      dcache_wready;
    logic                      dcache_wlast;
    logic [AXI_DATA_W    -1:0] dcache_wdata;
    logic [AXI_DATA_W/8  -1:0] dcache_wstrb;
    logic                      dcache_bvalid;
    logic                      dcache_bready;
    logic  [AXI_ID_W     -1:0] dcache_bid;
    logic  [2            -1:0] dcache_bresp;
    logic                      dcache_arvalid;
    logic                      dcache_arready;
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
    logic                      dcache_rvalid;
    logic                      dcache_rready;
    logic  [AXI_ID_W     -1:0] dcache_rid;
    logic  [2            -1:0] dcache_rresp;
    logic  [AXI_DATA_W   -1:0] dcache_rdata;
    logic                      dcache_rlast;

    logic                      gen_io_req;
    logic                      gen_mem_req;
    logic                      error;
    string                     tbname;
    integer                    timer;
    integer                    rd_req_num;
    integer                    wr_req_num;
    logic                      en;

    driver
    #(
        .OSTDREQ_NUM      (OSTDREQ_NUM),
        .RW_MODE          (1),
        .KEY              (KEY),
        .TIMEOUT          (TIMEOUT),
        .INIT             ("./ram_32b.txt"),
        .ILEN             (ILEN),
        .AXI_ADDR_W       (AXI_ADDR_W),
        .AXI_ID_W         (AXI_ID_W),
        .AXI_DATA_W       (ILEN)
    )
    driver
    (
        .aclk               (aclk),
        .aresetn            (aresetn),
        .srst               (srst),
        .en                 (en),
        .cache_ready        (cache_ready),
        .error              (error),
        .check_flush_reqs   (1'b0),
        .check_flush_blocks (1'b0),
        .flush_reqs         (),
        .flush_blocks       (),
        .flush_ack          (1'b0),
        .gen_io_req         (gen_io_req),
        .gen_mem_req        (gen_mem_req),
        .awvalid            (memfy_awvalid),
        .awready            (memfy_awready),
        .awaddr             (memfy_awaddr),
        .awprot             (memfy_awprot),
        .awcache            (memfy_awcache),
        .awid               (memfy_awid),
        .wvalid             (memfy_wvalid),
        .wready             (memfy_wready),
        .wdata              (memfy_wdata),
        .wstrb              (memfy_wstrb),
        .bvalid             (memfy_bvalid),
        .bready             (memfy_bready),
        .bid                (memfy_bid),
        .bresp              (memfy_bresp),
        .arvalid            (memfy_arvalid),
        .arready            (memfy_arready),
        .araddr             (memfy_araddr),
        .arprot             (memfy_arprot),
        .arcache            (memfy_arcache),
        .arid               (memfy_arid),
        .rvalid             (memfy_rvalid),
        .rready             (memfy_rready),
        .rid                (memfy_rid),
        .rresp              (memfy_rresp),
        .rdata              (memfy_rdata)
    );


    friscv_dcache
    #(
        .ILEN                (ILEN),
        .XLEN                (XLEN),
        .OSTDREQ_NUM         (OSTDREQ_NUM),
        .AXI_ADDR_W          (AXI_ADDR_W),
        .AXI_ID_W            (AXI_ID_W),
        .AXI_DATA_W          (AXI_DATA_W),
        .AXI_ID_MASK         (AXI_ID_MASK),
        .AXI_ID_FIXED        (0),
        .NO_RDC_BACKPRESSURE (0),
        .AXI_REORDER_CPL     (AXI_REORDER_CPL),
        .IO_MAP_NB           (IO_MAP_NB),
        .CACHE_PREFETCH_EN   (CACHE_PREFETCH_EN),
        .CACHE_BLOCK_W       (CACHE_BLOCK_W),
        .CACHE_DEPTH         (CACHE_DEPTH)
    )
    dut
    (
        .aclk            (aclk),
        .aresetn         (aresetn),
        .srst            (srst),
        .cache_ready     (cache_ready),
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

    assign dcache_rlast = 1'b0;

    axi4l_ram
    #(
        .INIT             ("./ram_128b.txt"),
        .AXI_ADDR_W       (AXI_ADDR_W),
        .AXI_ID_W         (AXI_ID_W),
        .AXI1_DATA_W      (AXI_DATA_W),
        .AXI2_DATA_W      (AXI_DATA_W),
        .OSTDREQ_NUM      (OSTDREQ_NUM)
    )
    axi4l_ram
    (
        .aclk       (aclk),
        .aresetn    (aresetn),
        .srst       (srst),
        .p1_awvalid (dcache_awvalid),
        .p1_awready (dcache_awready),
        .p1_awaddr  (dcache_awaddr),
        .p1_awprot  (dcache_awprot),
        .p1_awid    (dcache_awid),
        .p1_wvalid  (dcache_wvalid),
        .p1_wready  (dcache_wready),
        .p1_wdata   (dcache_wdata),
        .p1_wstrb   (dcache_wstrb),
        .p1_bid     (dcache_bid),
        .p1_bresp   (dcache_bresp),
        .p1_bvalid  (dcache_bvalid),
        .p1_bready  (dcache_bready),
        .p1_arvalid (dcache_arvalid),
        .p1_arready (dcache_arready),
        .p1_araddr  (dcache_araddr),
        .p1_arprot  (dcache_arprot ),
        .p1_arid    (dcache_arid),
        .p1_rvalid  (dcache_rvalid),
        .p1_rready  (dcache_rready),
        .p1_rid     (dcache_rid),
        .p1_rresp   (dcache_rresp),
        .p1_rdata   (dcache_rdata),
        .p2_awvalid (1'b0),
        .p2_awready (),
        .p2_awaddr  ({AXI_ADDR_W{1'b0}}),
        .p2_awprot  (3'h0),
        .p2_awid    ({AXI_ID_W{1'b0}}),
        .p2_wvalid  (1'b0),
        .p2_wready  (),
        .p2_wdata   ({CACHE_BLOCK_W{1'b0}}),
        .p2_wstrb   ({CACHE_BLOCK_W/8{1'b0}}),
        .p2_bid     (),
        .p2_bresp   (),
        .p2_bvalid  (),
        .p2_bready  (1'h0),
        .p2_arvalid (1'b0),
        .p2_arready (),
        .p2_araddr  ({AXI_ADDR_W{1'b0}}),
        .p2_arprot  (3'h0),
        .p2_arid    ({AXI_ID_W{1'b0}}),
        .p2_rvalid  (),
        .p2_rready  (1'h0),
        .p2_rid     (),
        .p2_rresp   (),
        .p2_rdata   ()
    );


    initial aclk = 0;
    always #2 aclk = ~aclk;

    `ifdef TRACE_VCD
    // To dump data for visualization:
    initial begin
        `INFO("Tracing into dcache_testbench.vcd");
        $dumpfile("dcache_testbench.vcd");
        $dumpvars(0, dcache_testbench);
        `INFO("Model running...");
    end
    `endif

    // Setup time format when printing with $realtime()
    initial $timeformat(-9, 1, "ns", 8);

    task setup(msg="");
    begin
        en = 1'b0;
        timer = 0;
        rd_req_num = 0;
        srst = 1'b0;
        gen_mem_req = 1'b0;
        gen_io_req = 1'b0;
        aresetn = 1'b0;
        #20;
        @(posedge aclk);
        aresetn = 1'b1;
    end
    endtask

    task teardown(msg="");
    begin
        check_results;
    end
    endtask

    task check_results;
        if (timer >= TIMEOUT)
            `ERROR("Testbench reached timeout");

        if (error)
            `ERROR("Driver detected an issue");

        if (rd_req_num==MAX_TRAFFIC)
            `SUCCESS("Maximum read traffic has been issued!");

        if (wr_req_num==MAX_TRAFFIC)
            `SUCCESS("Maximum write traffic has been issued!");
    endtask

    task run_testcase;
        while (timer<TIMEOUT && (rd_req_num<MAX_TRAFFIC || wr_req_num<MAX_TRAFFIC) && error===1'b0) begin
            timer = timer + 1;
            if (memfy_arvalid && memfy_arready) begin
                rd_req_num = rd_req_num + 1;
            end
            if (memfy_awvalid && memfy_awready) begin
                wr_req_num = wr_req_num + 1;
            end
            @(posedge aclk);
        end
    endtask


    `TEST_SUITE(tbname)

    `UNIT_TEST("Randomized traffic -io_req +blk_req")

        gen_mem_req = 1;
        gen_io_req = 0;
        en = 1'b1;
        run_testcase;

    `UNIT_TEST_END

    `UNIT_TEST("Randomized traffic +io_req -blk_req")

        en = 1'b1;
        gen_mem_req = 0;
        gen_io_req = 1;
        run_testcase;

    `UNIT_TEST_END

    `UNIT_TEST("Randomized traffic +io_req +blk_req")

        en = 1'b1;
        gen_mem_req = 1;
        gen_io_req = 1;
        run_testcase;

    `UNIT_TEST_END

    `TEST_SUITE_END

endmodule
