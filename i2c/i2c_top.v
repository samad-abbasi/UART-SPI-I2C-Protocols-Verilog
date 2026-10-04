`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Module Name : i2c_top
// Board       : Nexys A7
//
// Description:
// Top-level I2C demonstration design.
//
// Features
// --------
// • Push button starts I2C transaction
// • Switches provide transmit data
// • LEDs display controller status
// • I2C Master communicates with an external I2C slave
//
// Lab Tasks
// ---------
// 1. Connect board reset.
// 2. Detect push-button press.
// 3. Generate a one-clock start pulse.
// 4. Instantiate I2C Master.
// 5. Connect SDA and SCL signals.
// 6. Display controller status on LEDs.
//
//////////////////////////////////////////////////////////////////////////////////
module i2c_top #(
    parameter integer CLOCK_FREQ_HZ = 100_000_000,
    parameter integer I2C_FREQ_HZ   = 100_000
)
(
    input  wire        CLK100MHZ,
    input  wire        CPU_RESETN,
    input  wire        BTNC,
    input  wire [7:0]  SW,

    // I2C Interface
    inout  wire        i2c_sda,
    output wire        i2c_scl,

    output wire [15:0] LED
);

    //====================================================
    // Reset Signal
    //====================================================

    wire rst_n;

    // Connect active-low reset signal
    //
    // Example:
    // assign rst_n = CPU_RESETN;

     assign rst_n = CPU_RESETN;

    //====================================================
    // Push Button Edge Detector
    //====================================================

    reg btnc_d;

    // Register previous button value
     always @(posedge CLK100MHZ or negedge rst_n)
    begin
        if(!rst_n)
            btnc_d <= 1'b0;
        else
            btnc_d <= BTNC;
    end

    //====================================================
    // Generate Start Pulse
    //====================================================

    // Generate one-clock pulse when
    // the center push button is pressed

    wire start_i2c;
        // One-clock pulse on button rising edge
    assign start_i2c = BTNC & ~btnc_d;

    //====================================================
    // Internal Signals
    //====================================================

    wire [7:0] rx_data;

    wire busy;
    wire done;

    wire ack_error;


    //====================================================
    // I2C Master
    //====================================================

    // Instantiate I2C Master
    //
    // Inputs:
    //   Clock
    //   Reset
    //   Start Signal
    //   Read/Write Control
    //   Slave Address
    //   Transmit Data
    //
    // Outputs:
    //   Received Data
    //   Busy
    //   Done
    //   ACK Error
    //   SCL
    //   SDA

       i2c_master #(
        .CLOCK_FREQ_HZ(CLOCK_FREQ_HZ),
        .I2C_FREQ_HZ(I2C_FREQ_HZ)
    )
    master_inst
    (
        .clk        (CLK100MHZ),
        .rst_n      (rst_n),

        .start      (start_i2c),

        // 0 = Write
        // 1 = Read
        .rw         (1'b0),

        .slave_addr (7'h50),

        .tx_data    (SW),

        .rx_data    (rx_data),

        .busy       (busy),
        .done       (done),
        .ack_error  (ack_error),

        .scl        (i2c_scl),
        .sda        (i2c_sda)
    );
    //====================================================
    // LED Connections
    //====================================================

    // Display switch value
    // on LED[7:0]



    // Display busy signal
    // on LED[8]



    // Display done signal
    // on LED[9]



    // Display ACK error
    // on LED[10]



    // Turn OFF remaining LEDs
   
    // Switch value
    assign LED[7:0] = SW;

    // Busy
    assign LED[8] = busy;

    // Done
    assign LED[9] = done;

    // ACK Error
    assign LED[10] = ack_error;

    // Read data indication (optional)
    //assign LED[15:11] = rx_data[4:0];
    assign LED[15:11] = 5'b00000;
endmodule