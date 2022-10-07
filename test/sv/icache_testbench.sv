// Mandatory file to be able to launch SVUT flow
`include "svut_h.sv"
`timescale 1 ns / 100 ps

module icache_testbench();

    `SVUT_SETUP

    ///////////////////////////////////////////////////////////////////////////////
    // Variables and parameters
    ///////////////////////////////////////////////////////////////////////////////

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
    parameter XLEN = ILEN;
    parameter OSTDREQ_NUM = 8;
    parameter AXI_ADDR_W = ILEN;
    parameter AXI_ID_W = 8;
    parameter AXI_DATA_W = 128;
    parameter AXI_ID_MASK = 'h10;
    parameter CACHE_PREFETCH_EN = 0;
    parameter CACHE_BLOCK_W = AXI_DATA_W;
    parameter CACHE_DEPTH = 512;

    logic                       aclk;
    logic                       aresetn;
    logic                       srst;
    logic                       error;
    logic                       en;
    logic                       cache_ready;
    logic                       check_flush_reqs;
    logic                       check_flush_blocks;
    logic                       flush_reqs;
    logic                       flush_blocks;
    logic                       flush_ack;
    logic                       ctrl_arvalid;
    logic                       ctrl_arready;
    logic [AXI_ADDR_W     -1:0] ctrl_araddr;
    logic [3              -1:0] ctrl_arprot;
    logic [AXI_ID_W       -1:0] ctrl_arid;
    logic                       ctrl_rvalid;
    logic                       ctrl_rready;
    logic [AXI_ID_W       -1:0] ctrl_rid;
    logic [2              -1:0] ctrl_rresp;
    logic [ILEN           -1:0] ctrl_rdata;
    logic                       icache_arvalid;
    logic                       icache_arready;
    logic [AXI_ADDR_W     -1:0] icache_araddr;
    logic [8              -1:0] icache_arlen;
    logic [3              -1:0] icache_arsize;
    logic [2              -1:0] icache_arburst;
    logic [2              -1:0] icache_arlock;
    logic [4              -1:0] icache_arcache;
    logic [3              -1:0] icache_arprot;
    logic [4              -1:0] icache_arqos;
    logic [4              -1:0] icache_arregion;
    logic [AXI_ID_W       -1:0] icache_arid;
    logic                       icache_rvalid;
    logic                       icache_rready;
    logic [AXI_ID_W       -1:0] icache_rid;
    logic [2              -1:0] icache_rresp;
    logic [AXI_DATA_W     -1:0] icache_rdata;
    logic                       icache_rlast;

    string                      tbname;
    integer                     timer;
    integer                     req_num;

    ///////////////////////////////////////////////////////////////////////////////
    // Instances
    ///////////////////////////////////////////////////////////////////////////////

    driver
    #(
        .KEY        (KEY),
        .TIMEOUT    (TIMEOUT),
        .INIT       ("./ram_32b.txt"),
        .ILEN       (ILEN),
        .AXI_ADDR_W (AXI_ADDR_W),
        .AXI_ID_W   (AXI_ID_W),
        .AXI_DATA_W (ILEN)
    )
    driver
    (
        .aclk               (aclk),
        .aresetn            (aresetn),
        .srst               (srst),
        .en                 (en),
        .cache_ready        (cache_ready),
        .error              (error),
        .check_flush_reqs   (check_flush_reqs),
        .check_flush_blocks (check_flush_blocks),
        .flush_reqs         (flush_reqs),
        .flush_blocks       (flush_blocks),
        .flush_ack          (flush_ack),
        .gen_io_req         (1'b0),
        .gen_mem_req        (1'b0),
        .awvalid            (),
        .awready            (1'b0),
        .awaddr             (),
        .awprot             (),
        .awcache            (),
        .awid               (),
        .wvalid             (),
        .wready             (1'b0),
        .wdata              (),
        .wstrb              (),
        .bvalid             (1'b0),
        .bready             (),
        .bid                ({AXI_ID_W{1'b0}}),
        .bresp              (2'b0),
        .arvalid            (ctrl_arvalid),
        .arready            (ctrl_arready),
        .araddr             (ctrl_araddr),
        .arprot             (ctrl_arprot),
        .arcache            (),
        .arid               (ctrl_arid),
        .rvalid             (ctrl_rvalid),
        .rready             (ctrl_rready),
        .rid                (ctrl_rid),
        .rresp              (ctrl_rresp),
        .rdata              (ctrl_rdata)
    );

    friscv_icache
    #(
        .ILEN              (ILEN),
        .XLEN              (XLEN),
        .OSTDREQ_NUM       (OSTDREQ_NUM),
        .AXI_ADDR_W        (AXI_ADDR_W),
        .AXI_ID_W          (AXI_ID_W),
        .AXI_DATA_W        (AXI_DATA_W),
        .AXI_ID_MASK       (AXI_ID_MASK),
        .CACHE_PREFETCH_EN (CACHE_PREFETCH_EN),
        .CACHE_BLOCK_W     (CACHE_BLOCK_W),
        .CACHE_DEPTH       (CACHE_DEPTH)
    )
    icache
    (
        .aclk            (aclk),
        .aresetn         (aresetn),
        .srst            (srst),
        .cache_ready     (cache_ready),
        .flush_reqs      (flush_reqs),
        .flush_blocks    (flush_blocks),
        .flush_ack       (flush_ack),
        .ctrl_arvalid    (ctrl_arvalid),
        .ctrl_arready    (ctrl_arready),
        .ctrl_araddr     (ctrl_araddr),
        .ctrl_arprot     (ctrl_arprot),
        .ctrl_arid       (ctrl_arid),
        .ctrl_rvalid     (ctrl_rvalid),
        .ctrl_rready     (ctrl_rready),
        .ctrl_rid        (ctrl_rid),
        .ctrl_rresp      (ctrl_rresp),
        .ctrl_rdata      (ctrl_rdata),
        .icache_arvalid  (icache_arvalid),
        .icache_arready  (icache_arready),
        .icache_araddr   (icache_araddr),
        .icache_arlen    (icache_arlen),
        .icache_arsize   (icache_arsize),
        .icache_arburst  (icache_arburst),
        .icache_arlock   (icache_arlock),
        .icache_arcache  (icache_arcache),
        .icache_arprot   (icache_arprot),
        .icache_arqos    (icache_arqos),
        .icache_arregion (icache_arregion),
        .icache_arid     (icache_arid),
        .icache_rvalid   (icache_rvalid),
        .icache_rready   (icache_rready),
        .icache_rid      (icache_rid),
        .icache_rresp    (icache_rresp),
        .icache_rdata    (icache_rdata),
        .icache_rlast    (icache_rlast)
    );

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
        .aclk       (aclk          ),
        .aresetn    (aresetn       ),
        .srst       (srst          ),
        .p1_awvalid (1'b0),
        .p1_awready (),
        .p1_awaddr  ({AXI_ADDR_W{1'b0}}),
        .p1_awprot  (3'h0),
        .p1_awid    ({AXI_ID_W{1'b0}}),
        .p1_wvalid  (1'b0),
        .p1_wready  (),
        .p1_wdata   ({CACHE_BLOCK_W{1'b0}}),
        .p1_wstrb   ({CACHE_BLOCK_W/8{1'b0}}),
        .p1_bid     (),
        .p1_bresp   (),
        .p1_bvalid  (),
        .p1_bready  (1'h0),
        .p1_arvalid (icache_arvalid),
        .p1_arready (icache_arready),
        .p1_araddr  (icache_araddr ),
        .p1_arprot  (icache_arprot ),
        .p1_arid    (icache_arid   ),
        .p1_rvalid  (icache_rvalid ),
        .p1_rready  (icache_rready ),
        .p1_rid     (icache_rid    ),
        .p1_rresp   (icache_rresp  ),
        .p1_rdata   (icache_rdata  ),
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

    assign icache_rlast = 1'b1;

    ///////////////////////////////////////////////////////////////////////////////
    // Testbench internals
    ///////////////////////////////////////////////////////////////////////////////

    initial aclk = 0;
    always #2 aclk = ~aclk;

    `ifdef TRACE_VCD
    // To dump data for visualization:
    initial begin
        `INFO("Tracing into icache_testbench.vcd");
        $dumpfile("icache_testbench.vcd");
        $dumpvars(0, icache_testbench);
        `INFO("Model running...");
    end
    `endif

    // Setup time format when printing with $realtime()
    initial $timeformat(-9, 1, "ns", 8);


    initial begin
        $sformat(tbname, "%s", ``TBNAME);
    end


    task setup(msg="");
    begin
        en = 0;
        check_flush_reqs = 0;
        check_flush_blocks = 0;
        timer = 0;
        req_num = 0;
        srst = 1'b0;
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


    task run_testcase;
        while (timer<TIMEOUT && req_num<MAX_TRAFFIC && error===1'b0) begin
            timer = timer + 1;
            if (ctrl_arvalid && ctrl_arready) begin
                req_num = req_num + 1;
            end
            @(posedge aclk);
        end
    endtask


    task check_results;
        if (timer >= TIMEOUT)
            `ERROR("Testbench reached timeout");

        if (error)
            `ERROR("Driver detected an issue");

        if (req_num==MAX_TRAFFIC)
            `SUCCESS("Maximum traffic has been issued!");
    endtask


    `TEST_SUITE(tbname)


    `UNIT_TEST("Randomized traffic -flush_reqs -FENCE.i")

        en = 1'b1;
        check_flush_reqs = 0;
        check_flush_blocks = 0;

        run_testcase;

    `UNIT_TEST_END


    `UNIT_TEST("Randomized traffic +flush_reqs -FENCE.i")

        en = 1'b1;
        check_flush_reqs = 1;
        check_flush_blocks = 0;

        run_testcase;

    `UNIT_TEST_END


    `UNIT_TEST("Randomized traffic -flush_reqs +FENCE.i")

        en = 1'b1;
        check_flush_reqs = 0;
        check_flush_blocks = 1;

        run_testcase;

    `UNIT_TEST_END


    `UNIT_TEST("Randomized traffic +flush_reqs +FENCE.i")

        en = 1'b1;
        check_flush_reqs = 1;
        check_flush_blocks = 1;

        run_testcase;

    `UNIT_TEST_END


    `TEST_SUITE_END

endmodule
