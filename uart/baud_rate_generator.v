`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Module Name : baud_rate_generator
//
// Description:
// Parameterized Baud Rate Generator
//
// Lab Tasks:
// 1. Calculate the divider value.
// 2. Implement a counter.
// 3. Generate a one-clock-cycle tick.
// 4. Reset the counter.
//
// Applications:
// • UART Transmitter  : TICK_RATE_HZ = BAUD_RATE
// • UART Receiver     : TICK_RATE_HZ = BAUD_RATE × OVERSAMPLE
//
//////////////////////////////////////////////////////////////////////////////////

module baud_rate_generator #(
    parameter integer CLOCK_FREQ_HZ = 100_000_000,
    parameter integer TICK_RATE_HZ  = 9600
)
(
    input  wire clk,
    input  wire rst_n,

    output reg  tick
);

    //====================================================
    // Divider Calculation
    //====================================================

    // Calculate the divider value
    //
    // Divider =
    // CLOCK_FREQ_HZ / TICK_RATE_HZ

    localparam integer DIVIDER = CLOCK_FREQ_HZ/TICK_RATE_HZ;


    //====================================================
    // Counter Register
    //====================================================

    // Declare a counter register

    reg [31:0] count;


    //====================================================
    // Baud Rate Generator
    //====================================================

    always @(posedge clk or negedge rst_n)
    begin

        if(!rst_n)
        begin

            //------------------------------------------------
        count <= 32'd0;    // Reset counter
         tick  <= 1'b0;    // Clear tick signal
            //------------------------------------------------

        end
        else
        begin

            //------------------------------------------------
            // Check whether the counter has reached
            // (DIVIDER - 1)
            //------------------------------------------------
        
            if( count == DIVIDER-1 )
            begin

                //--------------------------------------------
                count <= 32'd0;   // Reset counter
               tick  <= 1'b1;         // Generate one-clock-cycle tick
                //--------------------------------------------

            end
            else
            begin

                //--------------------------------------------
               count <= count + 1'b1;  // Increment counter
               tick  <= 1'b0;  // Keep tick LOW
                //--------------------------------------------

            end

        end

    end

endmodule