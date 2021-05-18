// copyright damien pretet 2021
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
        input  logic                        aclk,
        input  logic                        aresetn,
        input  logic                        srst,
        // APB Master
        input  logic                        mst_en,
        input  logic                        mst_wr,
        input  logic [ADDRW           -1:0] mst_addr,
        input  logic [XLEN            -1:0] mst_wdata,
        input  logic [XLEN/8          -1:0] mst_strb,
        output logic [XLEN            -1:0] mst_rdata,
        output logic                        mst_ready,
        // UART interface
        input  logic                        uart_rx,
        output logic                        uart_tx,
        output logic                        uart_rts,
        input  logic                        uart_cts
    );

    ///////////////////////////////////////////////////////////////////////////
    //
    // Parameters and variables declarations
    //
    ///////////////////////////////////////////////////////////////////////////

    typedef enum logic[3:0] {
        IDLE = 0,
        XFER = 1,
        RW = 2,
        WAIT = 3
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
    logic [2   -1:0] uart_rx_cdc;
    logic            uart_rx_sync;
    logic [16  -1:0] rx_baud_cnt;
    logic [4   -1:0] rx_bit_cnt;
    logic [16  -1:0] tx_baud_cnt;
    logic [4   -1:0] tx_bit_cnt;

    //////////////////////////////////////////////////////////////////////////
    //
    // # Register Map Description
    //
    // ## Register 0: Control and Status [RW] - Address 0 - 16 bits
    //
    // - bit 0     : Enable the UART engine (both RX and TX) [RW]
    // - bit 1     : Loopback mode, every received data will be stored in RX
    //               FIFO and forwarded back to TX
    // - bit 2     : Enable parity bit
    // - bit 3     : 0 for even parity, 1 for odd parity
    // - bit 4     : 0 for one stop bit, 1 for two stop bits
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
    // ## Register 1: UART Clock Divider [RW] - Address 1 - 16 bits
    //
    // The number of CPU core cycles to divide down to get the UART data bit
    // rate (baud rate).
    //
    // - Bit 15:0  : Clock divider
    // - Bit 31:16 : Reserved
    //
    //
    // ## Register 2: TX FIFO [RW] - Address 1 - 8 bits
    //
    // Push data into TX FIFO. Writing into this register will block the APB
    // write request if TX FIFO is full, until the engine transmit a new word.
    //
    // - Bit 7:0  : data to write
    // - Bit 31:8 : Reserved
    //
    //
    // ## Register 3: RX FIFO [RO] - Address 1 - 8 bits
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
                        1'b0, uart_cts, uart_rts, rx_full, rx_empty, tx_full, tx_empty, busy,
                        3'b0, stop_mode, parity_mode, parity_en, loopback_mode, enable};

    assign busy = (rxfsm!=IDLE) || (txfsm!=IDLE);

    //////////////////////////////////////////////////////////////////////////
    //
    // APB Control FSM
    //
    //////////////////////////////////////////////////////////////////////////

    always @ (posedge aclk or negedge aresetn) begin

        if (~aresetn) begin
            enable <= 1'b0;
            loopback_mode <= 1'b0;
            parity_en <= 1'b0;
            parity_mode <= 1'b0;
            stop_mode <= 1'b0;
            tx_push <= 1'b0;
            rx_pull <= 1'b0;
            clock_divider <= CLK_DIVIDER;
            register2 <= {8{1'b0}};
            mst_rdata <= {XLEN{1'b0}};
            mst_ready <= 1'b0;
        end else if (srst) begin
            enable <= 1'b0;
            loopback_mode <= 1'b0;
            parity_en <= 1'b0;
            parity_mode <= 1'b0;
            stop_mode <= 1'b0;
            tx_push <= 1'b0;
            rx_pull <= 1'b0;
            clock_divider <= CLK_DIVIDER;
            register2 <= {8{1'b0}};
            mst_rdata <= {XLEN{1'b0}};
            mst_ready <= 1'b0;
        end else begin

            // If previously requested, go back to IDLE to serve a new request
            if (mst_ready) begin
                tx_push <= 1'b0;
                rx_pull <= 1'b0;
                mst_ready <= 1'b0;

            // Serve a new request
            end else if (mst_en) begin

                // Register 0: Control and Status
                if (mst_addr=={ADDRW{1'b0}}) begin
                    if (mst_wr) begin
                        if (mst_strb[0]) begin
                            enable <= mst_wdata[0];
                            loopback_mode <= mst_wdata[1];
                            parity_en <= mst_wdata[2];
                            parity_mode <= mst_wdata[3];
                            stop_mode <= mst_wdata[4];
                        end
                        mst_ready <= 1'b1;
                    end else begin
                        mst_rdata <= register0;
                        mst_ready <= 1'b1;
                    end

                // Register 1: baud rate
                end else if (mst_addr=={{ADDRW-1{1'b0}}, 1'b1}) begin
                    if (mst_wr) begin
                        if (mst_strb[0]) clock_divider[ 0+:8] <= mst_wdata[ 0+:8];
                        if (mst_strb[1]) clock_divider[ 8+:8] <= mst_wdata[ 8+:8];
                        mst_ready <= 1'b1;
                    end else begin
                        mst_rdata <= {16'b0, clock_divider};
                        mst_ready <= 1'b1;
                    end

                // Register 2: TX FIFO
                end else if (mst_addr=={{ADDRW-2{1'b0}}, 2'b10}) begin
                    if (mst_wr) begin
                        // Wait until the FIFO can store a new word
                        if (~tx_full) begin
                            if (mst_strb[0]) register2[ 0+:8] <= mst_wdata[ 0+:8];
                            tx_push <= 1'b1;
                            mst_ready <= 1'b1;
                        end
                    end else begin
                        mst_rdata <= {24'b0, register2};
                        mst_ready <= 1'b1;
                    end

                // Register 3: RX FIFO
                end else if (mst_addr=={{ADDRW-2{1'b0}}, 2'b11}) begin
                    // Wait until the FIFO is filled
                    if (~rx_empty) begin
                        rx_pull <= 1'b1;
                        mst_rdata <= {24'b0, register3};
                        mst_ready <= 1'b1;
                    end
                end

            // Just wait for the next APB request
            end else begin
                tx_push <= 1'b0;
                rx_pull <= 1'b0;
                mst_ready <= 1'b0;
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
        .data_in  (register2),
        .push     (tx_push  ),
        .full     (tx_full  ),
        .data_out (tx_data  ),
        .pull     (tx_pull  ),
        .empty    (tx_empty )
    );


    always @ (posedge aclk or negedge aresetn) begin

        if (~aresetn) begin
            tx_pull <= 1'b0;
            tx_data_srr <= 8'b0;
            tx_bit_cnt <= 4'b0;
            tx_baud_cnt <= 16'b0;
            txfsm <= IDLE;
        end else if (srst) begin
            tx_pull <= 1'b0;
            tx_data_srr <= 8'b0;
            tx_bit_cnt <= 4'b0;
            tx_baud_cnt <= 16'b0;
            txfsm <= IDLE;
        end else begin
            case (txfsm)

                default: begin
                    tx_pull <= 1'b0;
                    tx_bit_cnt <= 4'b1;
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

                    tx_baud_cnt <= tx_baud_cnt + 1;

                    if (tx_baud_cnt==clock_divider) begin
                        tx_baud_cnt <= 16'b0;
                        tx_bit_cnt <= tx_bit_cnt + 1'b1;
                        uart_tx <= tx_data_srr[0];
                        tx_data_srr <= tx_data_srr >> 1;
                        if (tx_bit_cnt==8) begin
                            tx_pull <= 1'b1;
                            txfsm <= RW;
                        end
                    end
                end

                RW: begin
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


    // Synchronize the incoming bitstream in the interface domain
    always @ (posedge aclk or negedge aresetn) begin
        if (~aresetn) uart_rx_cdc <= 2'b0;
        else if (srst) uart_rx_cdc <= 2'b0;
        else uart_rx_cdc <= {uart_rx_cdc[0], uart_rx};
    end

    assign uart_rx_sync = uart_rx_cdc[1];

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
                    rx_bit_cnt <= 4'b1;
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
                        rx_data <= {uart_rx_sync, rx_data[7:1]};
                        if (rx_bit_cnt==8) begin
                            rx_push <= 1'b1;
                            rxfsm <= RW;
                        end
                    end

                end
                RW: begin
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
        .data_in  (rx_data  ),
        .push     (rx_push  ),
        .full     (rx_full  ),
        .data_out (register3),
        .pull     (rx_pull  ),
        .empty    (rx_empty )
    );

endmodule

`resetall
