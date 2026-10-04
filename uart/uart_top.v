`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Module Name : uart_top
// Board       : NEXYS A7
//
// Description:
// Top-level UART design.
//
// Lab Tasks:
// 1. Generate baud-rate ticks for transmitter.
// 2. Generate 16× oversampling ticks for receiver.
// 3. Detect push-button press to start transmission.
// 4. Instantiate UART Transmitter.
// 5. Instantiate UART Receiver.
// 6. Display received data on LEDs.
// 7. Display UART status signals.
//
//////////////////////////////////////////////////////////////////////////////////
module uart_top #(
    parameter integer CLOCK_FREQ_HZ = 100_000_000,
    parameter integer BAUD_RATE      = 9600
)
(
    input  wire        CLK100MHZ,
    input  wire        CPU_RESETN,
    input  wire        BTNC,
    input  wire [7:0]  SW,

    // USB-UART Interface
    input  wire        UART_TXD_IN,
    output wire        UART_RXD_OUT,

    output wire [15:0] LED
);

    //====================================================
    // Reset Signal
    //====================================================
    wire rst_n;

    // Connect the board reset signal
    // Example:
    assign rst_n = CPU_RESETN;


    //====================================================
    // Internal Signals
    //====================================================

    // Baud-rate generator outputs
    wire tx_tick;
    wire rx_sample_tick;

    // UART Transmitter signals
    wire tx_busy;
    wire tx_done;

    // UART Receiver signals
    wire rx_valid;
    wire framing_error;
    wire [7:0] rx_data;

    //====================================================
    // Push Button Edge Detector
    //====================================================

    reg btnc_d;
    
    always @(posedge CLK100MHZ or negedge rst_n)
    begin
        if(!rst_n)
        begin
            btnc_d <= 1'b0;
        end
        else
        begin
            btnc_d <= BTNC; 
        end
    end

    // Register previous button value


    // Generate one-clock pulse
    // when push button is pressed

    wire start_tx;
    assign start_tx = BTNC & ~btnc_d;


    //====================================================
    // Baud Rate Generator
    //====================================================

    // Instantiate baud-rate generator
    // for UART transmitter
    //
    // Tick Frequency = BAUD_RATE
    
    baud_rate_generator #(
        .CLOCK_FREQ_HZ(CLOCK_FREQ_HZ),
        .TICK_RATE_HZ(BAUD_RATE)) tx_baud_gen (
        .clk(CLK100MHZ), 
        .rst_n(rst_n), 
        .tick(tx_tick)
    );


    //====================================================
    // Receiver Sample Generator
    //====================================================

    // Instantiate baud-rate generator
    // for UART receiver
    //
    // Tick Frequency = BAUD_RATE × 16
    
    baud_rate_generator #(
        .CLOCK_FREQ_HZ(CLOCK_FREQ_HZ),
        .TICK_RATE_HZ(BAUD_RATE * 16)) rx_baud_gen (
        .clk(CLK100MHZ), 
        .rst_n(rst_n), 
        .tick(rx_sample_tick)
    );


    //====================================================
    // UART Transmitter
    //====================================================

    // Instantiate UART Transmitter
    //
    // Inputs:
    //  Clock
    //  Reset
    //  Baud Tick
    //  Start Signal
    //  Switches (SW)
    //
    // Outputs:
    //  UART_RXD_OUT
    //  tx_busy
    //  tx_done
    
    uart_tx uart_trans (
    .clk(CLK100MHZ), .rst_n(rst_n), .baud_tick(tx_tick), .start(start_tx), .data_in(SW),
    .tx(UART_RXD_OUT), .busy(tx_busy), .done(tx_done));
    //====================================================
    // UART Receiver
    //====================================================

    // Instantiate UART Receiver
    //
    // Inputs:
    //  Clock
    //  Reset
    //  Sample Tick
    //  UART_TXD_IN
    //
    // Outputs:
    //  rx_data
    //  rx_valid
    //  framing_error
    
    uart_rx #(.OVERSAMPLE(16)) uart_rcv (
        .clk(CLK100MHZ), .rst_n(rst_n), .sample_tick(rx_sample_tick), .rx(UART_TXD_IN),           
        .data_out(rx_data), .data_valid(rx_valid), .framing_error(framing_error));


    //====================================================
    // LED Connections
    //====================================================

    // Display received data
    // on LED[7:0]
    assign LED[7:0]   = rx_data;


    // Display transmitter busy signal
    // on LED[8]
    assign LED[8]     = tx_busy;


    // Display transmitter done signal
    // on LED[9]
    assign LED[9]     = tx_done;


    // Display receiver valid signal
    // on LED[10]
    assign LED[10]    = rx_valid;


    // Display framing error
    // on LED[11]
    assign LED[11]    = framing_error;


    // Turn OFF remaining LEDs
    assign LED[15:12] = 4'b0000;
    
//    assign LED = { 4'b0000, framing_error, rx_valid, tx_done, tx_busy, rx_data };


endmodule
