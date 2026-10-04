`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Module Name : spi_top
// Board       : Nexys A7
//
// Description:
// Top-level SPI demonstration design.
//
// Features
// --------
// • Push button starts SPI transmission
// • Switches provide transmit data
// • LEDs display received data and SPI status
// • Communicates with an external SPI slave
//
// Lab Tasks
// ---------
// 1. Connect the reset signal.
// 2. Detect push-button press.
// 3. Generate a one-clock-cycle start pulse.
// 4. Instantiate the SPI Master.
// 5. Connect the SPI interface.
// 6. Display received data and status on LEDs.
//
//////////////////////////////////////////////////////////////////////////////////

module spi_top #(
    parameter integer CLOCK_DIV = 50
)
(
    input  wire        CLK100MHZ,
    input  wire        CPU_RESETN,
    input  wire        BTNC,
    input  wire [7:0]  SW,

    // SPI Interface
    input  wire        spi_miso,
    output wire        spi_mosi,
    output wire        spi_sclk,
    output wire        spi_cs_n,

    output wire [15:0] LED
);

    //====================================================
    // Reset Signal
    //====================================================
    wire rst_n;

    // Connect active-low reset
    assign rst_n = CPU_RESETN;


    //====================================================
    // Push Button Edge Detector
    //====================================================
    reg btnc_d;

    // Store previous push-button value
    always @(posedge CLK100MHZ or negedge rst_n) begin
        if (!rst_n) begin
            btnc_d <= 1'b0;
        end else begin
            btnc_d <= BTNC;
        end
    end


    //====================================================
    // Generate Start Pulse
    //====================================================
    // Generate one-clock-cycle pulse when BTNC goes from low to high (rising edge)
    wire start_spi;
    assign start_spi = (BTNC == 1'b1) && (btnc_d == 1'b0);


    //====================================================
    // Internal Signals
    //====================================================
    wire [7:0] rx_data;
    wire       busy;
    wire       done;


    //====================================================
    // SPI Master
    //====================================================
    // Instantiate SPI Master
    spi_master #(
        .CLOCK_DIV(CLOCK_DIV)
    ) u_spi_master (
        .clk     (CLK100MHZ),
        .rst_n   (rst_n),
        
        .start   (start_spi),
        .tx_data (SW),
        
        .miso    (spi_miso),
        .mosi    (spi_mosi),
        .sclk    (spi_sclk),
        .cs_n    (spi_cs_n),
        
        .rx_data (rx_data),
        .busy    (busy),
        .done    (done)
    );


    //====================================================
    // LED Connections
    //====================================================
    // Display received data on LED[7:0]
    assign LED[7:0] = rx_data;

    // Display busy signal on LED[8]
    assign LED[8] = busy;

    // Display done signal on LED[9]
    assign LED[9] = done;

    // Turn OFF remaining LEDs (LED[15:10])
    assign LED[15:10] = 6'b000000;

endmodule