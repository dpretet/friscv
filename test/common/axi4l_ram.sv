// distributed under the mit license
// https://opensource.org/licenses/mit-license.php

`timescale 1 ns / 1 ps
`default_nettype none

module axi4l_ram

    #(
        parameter INIT  = "init.v",
        // Enable variation in RRESP and BRESP channels to handshake
        parameter VARIABLE_LATENCY = 0,
        // Address bus width defined for both control and AXI4 address signals
        parameter AXI_ADDR_W = 8,
        // AXI ID width, setup by default to 8 and unused
        parameter AXI_ID_W = 8,
        // AXI4 data width, independant of control unit width
        parameter AXI_DATA_W = 8,
        // Number of outstanding requests supported
        parameter OSTDREQ_NUM = 4
    )(
        // Global signals
        input  logic                      aclk,
        input  logic                      aresetn,
        input  logic                      srst,
        // AXI4-lite write channels interface
        input  logic                      awvalid,
        output logic                      awready,
        input  logic [AXI_ADDR_W    -1:0] awaddr,
        input  logic [3             -1:0] awprot,
        input  logic [AXI_ID_W      -1:0] awid,
        input  logic                      wvalid,
        input  logic                      wready,
        input  logic [AXI_DATA_W    -1:0] wdata,
        input  logic [AXI_ID_W      -1:0] wid,
        output logic [2             -1:0] bresp,
        output logic                      bvalid,
        input  logic                      bready,
        // AXI4-lite read channels interface
        input  logic                      arvalid,
        output logic                      arready,
        input  logic [AXI_ADDR_W    -1:0] araddr,
        input  logic [3             -1:0] arprot,
        input  logic [AXI_ID_W      -1:0] arid,
        output logic                      rvalid,
        input  logic                      rready,
        output logic [AXI_ID_W      -1:0] rid,
        output logic [2             -1:0] rresp,
        output logic [AXI_DATA_W    -1:0] rdata
    );

    ///////////////////////////////////////////////////////////////////////////
    // Parameters and signals declarations
    ///////////////////////////////////////////////////////////////////////////

    parameter ADDR_LSB_W = $clog2(AXI_DATA_W/8);

    logic [AXI_DATA_W+AXI_ID_W-1:0] mem [2**AXI_ADDR_W-1:0];
    initial $readmemh(INIT, mem, 0, 2**AXI_ADDR_W-1);

    integer                 random;
    integer                 rcounter;

    logic [AXI_ADDR_W -1:0] araddr_s;
    logic [AXI_ID_W   -1:0] arid_s;

    logic                   raddr_full;
    logic                   raddr_pull;
    logic                   raddr_empty;

    ///////////////////////////////////////////////////////////////////////////
    // FIFO buffering the incoming outstanding requests
    ///////////////////////////////////////////////////////////////////////////

    friscv_scfifo
    #(
        .ADDR_WIDTH ($clog2(OSTDREQ_NUM)),
        .DATA_WIDTH (AXI_ID_W+AXI_ADDR_W)
    )
    arch_fifo
    (
        .aclk     (aclk),
        .aresetn  (aresetn),
        .srst     (srst),
        .flush    (1'b0),
        .data_in  ({arid, araddr}),
        .push     (arvalid),
        .full     (raddr_full),
        .data_out ({arid_s, araddr_s}),
        .pull     (raddr_pull),
        .empty    (raddr_empty)
    );

    assign arready = ~raddr_full;

    assign raddr_pull = rvalid & rready;

    ///////////////////////////////////////////////////////////////////////////
    // Read control FSM
    ///////////////////////////////////////////////////////////////////////////

    always @ (posedge aclk or negedge aresetn) begin
        if (~aresetn) begin
            random <= $urandom() % 5;
            rcounter <= 0;
            rvalid <= 1'b0;
        end else if (srst) begin
            random <= $urandom() % 5;
            rcounter <= 0;
            rvalid <= 1'b0;
        end else begin
            if (~raddr_empty) begin
                if (random==rcounter) begin
                    rvalid <= 1'b1;
                    if (rready) begin
                        if (VARIABLE_LATENCY>0) random <= $urandom() % 5;
                        else random <= 0;
                        rcounter <= 0;
                    end
                end else begin
                    rvalid <= 1'b0;
                    rcounter <= rcounter + 1;
                end
            end else begin
                rvalid <= 1'b0;
                rcounter <= 0;
            end
        end
    end

    assign rdata = mem[araddr_s[ADDR_LSB_W+:AXI_ADDR_W-ADDR_LSB_W]];
    assign rid = arid_s;
    assign rresp = 2'b0;

endmodule

`resetall
