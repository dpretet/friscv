// distributed under the mit license
// https://opensource.org/licenses/mit-license.php

`timescale 1 ns / 1 ps
`default_nettype none

`include "friscv_h.sv"

module friscv_uart

    #(
        parameter ADDRW           = 16,
        parameter XLEN            = 32,
        parameter RXTX_FIFO_DEPTH = 4,
        parameter CLK_DIVIDER     = 4
    )(
        // clock & reset
        input  wire                         aclk,
        input  wire                         aresetn,
        input  wire                         srst,
        // APB Master
        input  wire                         slv_en,
        input  wire                         slv_wr,
        input  wire  [ADDRW           -1:0] slv_addr,
        input  wire  [XLEN            -1:0] slv_wdata,
        input  wire  [XLEN/8          -1:0] slv_strb,
        output logic [XLEN            -1:0] slv_rdata,
        output logic                        slv_ready,
        // UART interface
        input  wire                         uart_rx,
        output logic                        uart_tx,
        output logic                        uart_rts,
        input  wire                         uart_cts
    );

    ///////////////////////////////////////////////////////////////////////////
    //
    // Parameters and variables declarations
    //
    ///////////////////////////////////////////////////////////////////////////

    typedef enum logic[3:0] {
        IDLE = 0,
        XFER = 1,
        RWFIFO = 2
    } xfer_fsm;

    xfer_fsm rxfsm;
    xfer_fsm txfsm;

    logic            enable;
    logic            busy;
    logic            loopback_mode;
    logic            parity_en;
    logic            parity_mode;
    logic            stop_mode;
    logic [XLEN-1:0] register0;
    logic [16  -1:0] clock_divider;
    logic [8   -1:0] register2;
    logic [8   -1:0] register3;

    logic            tx_push;
    logic            tx_full;
    logic            tx_pull;
    logic            tx_empty;
    logic [8   -1:0] tx_data;
    logic [8   -1:0] tx_data_srr;

    logic            rx_push;
    logic            rx_full;
    logic            rx_pull;
    logic            rx_empty;
    logic [8   -1:0] rx_data;
    logic            uart_rx_sync;
    logic            uart_cts_sync;
    logic [16  -1:0] rx_baud_cnt;
    logic [4   -1:0] rx_bit_cnt;
    logic [16  -1:0] tx_baud_cnt;
    logic [4   -1:0] tx_bit_cnt;

    //////////////////////////////////////////////////////////////////////////
    //
    // # Register Map Description
    //
    // ## Register 0: Control and Status [RW] - Address 0x0 - 16 bits wide
    //
    // - bit 0     : Enable the UART engine (both RX and TX) [RW]
    // - bit 1     : Loopback mode, every received data will be stored in RX
    //               FIFO and forwarded back to TX [RW]
    // - bit 2     : Enable parity bit [RW]
    // - bit 3     : 0 for even parity, 1 for odd parity [RW]
    // - bit 4     : 0 for one stop bit, 1 for two stop bits [RW]
    // - bit 7:5   : Reserved
    // - bit 8     : Busy flag, the UART engine is processing (RX or TX) [RO]
    // - bit 9     : TX FIFO is empty [RO]
    // - bit 10    : TX FIFO is full [RO]
    // - bit 11    : RX FIFO is empty [RO]
    // - bit 12    : RX FIFO is full [RO]
    // - bit 13    : UART RTS, flagging it can't receive anymore data [RO]
    // - bit 14    : UART CTS, flagging it can't send anymore data [RO]
    // - bit 15    : Parity error of the last RX transaction [RO]
    // - bit 31:16 : Reserved
    //
    // ## Register 1: UART Clock Divider [RW] - Address 0x4 - 16 bits wide
    //
    // The number of CPU core cycles to divide down to get the UART data bit
    // rate (baud rate).
    //
    // - Bit 15:0  : Clock divider
    // - Bit 31:16 : Reserved
    //
    //
    // ## Register 2: TX FIFO [RW] - Address 0x8 - 8 bits wide
    //
    // Push data into TX FIFO. Writing into this register will block the APB
    // write request if TX FIFO is full, until the engine transmit a new word.
    //
    // - Bit 7:0  : data to write
    // - Bit 31:8 : Reserved
    //
    //
    // ## Register 3: RX FIFO [RO] - Address 0xC - 8 bits wide
    //
    // Pull data from RX FIFO. Reading into this register will block the APB
    // read request if FIFO is empty, until the engine receives a new word.
    //
    // - Bit 7:0  : data ready to be read
    // - Bit 31:8 : Reserved
    //
    //
    // ## Comments
    //
    // Any attempt to write in a read-only [RO] register or a reserved field
    // will be without effect and can't change the register content neither
    // the engine behavior. RW registers can be written partially by setting
    // properly the WSTRB signal.
    //
    // Register 1, setting up the baud rate, can be changed anytime like any
    // register; but an update during an ongoing operation will certainly lead
    // to compromise the transfer integrity and possibly make unstable the
    // UART engine. The user is advised to configure the baud rate during
    // start up and be sure the engine is disabled before changing this value.
    //
    // If a transfer (RX or TX) is active and the enable bit is setup back to
    // 0, the transfer will terminate only after the complete frame transmission
    //
    //////////////////////////////////////////////////////////////////////////


    //////////////////////////////////////////////////////////////////////////
    //
    // Registers
    //
    //////////////////////////////////////////////////////////////////////////

    assign register0 = {{XLEN-16{1'b0}},
                        1'b0, uart_cts_sync, uart_rts, rx_full, rx_empty, tx_full, tx_empty, busy,
                        3'b0, stop_mode, parity_mode, parity_en, loopback_mode, enable};

    assign busy = (rxfsm!=IDLE) || (txfsm!=IDLE);

    //////////////////////////////////////////////////////////////////////////
    //
    // APB Control FSM
    //
    //////////////////////////////////////////////////////////////////////////

    always @ (posedge aclk or negedge aresetn) begin

        if (~aresetn) begin
            enable <= 1'b1;
            loopback_mode <= 1'b0;
            parity_en <= 1'b0;
            parity_mode <= 1'b0;
            stop_mode <= 1'b0;
            tx_push <= 1'b0;
            rx_pull <= 1'b0;
            clock_divider <= CLK_DIVIDER;
            register2 <= {8{1'b0}};
            slv_rdata <= {XLEN{1'b0}};
            slv_ready <= 1'b0;
        end else if (srst) begin
            enable <= 1'b1;
            loopback_mode <= 1'b0;
            parity_en <= 1'b0;
            parity_mode <= 1'b0;
            stop_mode <= 1'b0;
            tx_push <= 1'b0;
            rx_pull <= 1'b0;
            clock_divider <= CLK_DIVIDER;
            register2 <= {8{1'b0}};
            slv_rdata <= {XLEN{1'b0}};
            slv_ready <= 1'b0;
        end else begin

            // If previously requested, go back to IDLE to serve a new request
            if (slv_ready) begin
                tx_push <= 1'b0;
                rx_pull <= 1'b0;
                slv_ready <= 1'b0;

            // Serve a new request
            end else if (slv_en) begin
                
                // Unmapped address
                if (slv_addr > {{(ADDRW-4){1'b0}},4'hC}) begin
                    slv_ready <= 1'b1;
                    slv_rdata <= {XLEN{1'b1}};

                // Register 0: Control and Status
                end else if (slv_addr=={{(ADDRW-4){1'b0}},4'h0}) begin
                    if (slv_wr) begin
                        if (slv_strb[0]) begin
                            enable <= slv_wdata[0];
                            loopback_mode <= slv_wdata[1];
                            parity_en <= slv_wdata[2];
                            parity_mode <= slv_wdata[3];
                            stop_mode <= slv_wdata[4];
                        end
                    end
                    slv_rdata <= register0;
                    slv_ready <= 1'b1;

                // Register 1: baud rate
                end else if (slv_addr=={{(ADDRW-4){1'b0}},4'h4}) begin
                    if (slv_wr) begin
                        if (slv_strb[0]) clock_divider[0+:8] <= slv_wdata[0+:8];
                        if (slv_strb[1]) clock_divider[8+:8] <= slv_wdata[8+:8];
                    end
                    slv_rdata <= {16'b0, clock_divider};
                    slv_ready <= 1'b1;

                // Register 2: TX FIFO
                end else if (slv_addr=={{(ADDRW-4){1'b0}},4'h8}) begin
                    if (slv_wr) begin
                        // Wait until the FIFO can store a new word
                        if (~tx_full) begin
                            if (slv_strb[0]) register2[0+:8] <= slv_wdata[0+:8];
                            tx_push <= 1'b1;
                            slv_ready <= 1'b1;
                        end
                    end
                    slv_rdata <= {24'b0, register2};

                // Register 3: RX FIFO
                end else if (slv_addr=={{(ADDRW-4){1'b0}},4'hC}) begin
                    // Wait until the FIFO is filled
                    if (!rx_empty) begin
                        rx_pull <= 1'b1;
                        slv_ready <= 1'b1;
                    end
                    slv_rdata <= {24'b0, register3};
                end
            end
        end
    end


    //////////////////////////////////////////////////////////////////////////
    //
    // UART TX Engine
    //
    //////////////////////////////////////////////////////////////////////////

    friscv_scfifo
    #(
        .ADDR_WIDTH ($clog2(RXTX_FIFO_DEPTH)),
        .DATA_WIDTH (8)
    )
    tx_fifo
    (
        .aclk     (aclk     ),
        .aresetn  (aresetn  ),
        .srst     (srst     ),
        .flush    (1'b0     ),
        .data_in  (register2),
        .push     (tx_push  ),
        .full     (tx_full  ),
        .afull    (         ),
        .data_out (tx_data  ),
        .pull     (tx_pull  ),
        .empty    (tx_empty ),
        .aempty   (         )
    );


    always @ (posedge aclk or negedge aresetn) begin

        if (~aresetn) begin
            tx_pull <= 1'b0;
            tx_data_srr <= 8'b0;
            tx_bit_cnt <= 4'b0;
            tx_baud_cnt <= 16'b0;
            uart_tx <= 1'b1;
            txfsm <= IDLE;
        end else if (srst) begin
            tx_pull <= 1'b0;
            tx_data_srr <= 8'b0;
            tx_bit_cnt <= 4'b0;
            tx_baud_cnt <= 16'b0;
            uart_tx <= 1'b1;
            txfsm <= IDLE;
        end else begin

            case (txfsm)

                default: begin
                    tx_pull <= 1'b0;
                    tx_bit_cnt <= 4'b0;
                    tx_baud_cnt <= 16'b0;
                    tx_data_srr <= 8'b0;
                    uart_tx <= 1'b1;
                    // if the engine is enabled:
                    // wait for a start bit and ensure the FIFO is not full
                    if (enable && uart_cts && ~tx_empty) begin
                        tx_data_srr <= tx_data;
                        uart_tx <= 1'b0;
                        txfsm <= XFER;
                    end
                end

                XFER: begin

                    tx_pull <= 1'b0;
                    tx_baud_cnt <= tx_baud_cnt + 1;

                    if (tx_baud_cnt==clock_divider) begin
                        tx_baud_cnt <= 16'b0;
                        tx_bit_cnt <= tx_bit_cnt + 1'b1;
                        if (tx_bit_cnt==4'h8) begin
                            uart_tx <= 1'b1;
                            tx_pull <= 1'b1;
                        end else if (tx_bit_cnt==4'h9 && stop_mode==1'b0) begin
                            uart_tx <= 1'b1;
                            txfsm <= RWFIFO;
                        end else if (tx_bit_cnt==4'hA && stop_mode==1'b1) begin
                            uart_tx <= 1'b1;
                            txfsm <= RWFIFO;
                        end else begin
                            uart_tx <= tx_data_srr[0];
                            tx_data_srr <= tx_data_srr >> 1;
                        end
                    end
                end

                RWFIFO: begin
                    tx_pull <= 1'b0;
                    txfsm <= IDLE;
                end

            endcase
        end
    end


    //////////////////////////////////////////////////////////////////////////
    //
    // UART RX Engine
    //
    //////////////////////////////////////////////////////////////////////////

    friscv_bit_sync 
    #(
    .DEFAULT_LEVEL (1),
    .DEPTH (2)
    )
    rx_sync 
    (
    .aclk    (aclk),
    .aresetn (aresetn),
    .srst    (srst),
    .bit_i   (uart_rx),
    .bit_o   (uart_rx_sync)
    );

    friscv_bit_sync 
    #(
    .DEFAULT_LEVEL (1),
    .DEPTH (2)
    )
    cts_sync 
    (
    .aclk    (aclk),
    .aresetn (aresetn),
    .srst    (srst),
    .bit_i   (uart_cts),
    .bit_o   (uart_cts_sync)
    );


    always @ (posedge aclk or negedge aresetn) begin

        if (~aresetn) begin
            rx_push <= 1'b0;
            rx_data <= 8'b0;
            rx_bit_cnt <= 4'b0;
            rx_baud_cnt <= 16'b0;
            rxfsm <= IDLE;
        end else if (srst) begin
            rx_push <= 1'b0;
            rx_data <= 8'b0;
            rx_bit_cnt <= 4'b0;
            rx_baud_cnt <= 16'b0;
            rxfsm <= IDLE;
        end else begin

            case (rxfsm)

                default: begin
                    rx_push <= 1'b0;
                    rx_bit_cnt <= 4'b0;
                    rx_baud_cnt <= 16'b0;
                    rx_data <= 8'b0;
                    // if the engine is enabled:
                    // wait for a start bit and ensure the FIFO is not full
                    if (enable && uart_rts && ~uart_rx_sync) begin
                        rxfsm <= XFER;
                    end
                end

                XFER: begin

                    rx_baud_cnt <= rx_baud_cnt + 1;

                    if (rx_baud_cnt==clock_divider) begin
                        rx_baud_cnt <= 16'b0;
                        rx_bit_cnt <= rx_bit_cnt + 1'b1;
                        if (rx_bit_cnt==4'h8) begin
                            rx_push <= 1'b1;
                            rxfsm <= RWFIFO;
                        end else begin
                            rx_data <= {uart_rx_sync, rx_data[7:1]};
                        end
                    end
                end

                RWFIFO: begin
                    rx_push <= 1'b0;
                    rx_data <= 8'b0;
                    rxfsm <= IDLE;
                end

            endcase
        end
    end

    // RTS indicates to the other side it can't receive anymore data
    assign uart_rts = ~rx_full;

    friscv_scfifo
    #(
        .ADDR_WIDTH ($clog2(RXTX_FIFO_DEPTH)),
        .DATA_WIDTH (8)
    )
    rx_fifo
    (
        .aclk     (aclk     ),
        .aresetn  (aresetn  ),
        .srst     (srst     ),
        .flush    (1'b0     ),
        .data_in  (rx_data  ),
        .push     (rx_push  ),
        .full     (rx_full  ),
        .afull    (         ),
        .data_out (register3),
        .pull     (rx_pull  ),
        .empty    (rx_empty ),
        .aempty   (         )
    );

endmodule

`resetall
