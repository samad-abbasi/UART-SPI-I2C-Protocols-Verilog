`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Module Name : spi_slave
//
// Description:
// SPI Slave Controller
//
// Features
// --------
// • SPI Mode 0 (CPOL = 0, CPHA = 0)
// • 8-bit Full-Duplex Communication
// • Receives data from MOSI
// • Sends data on MISO
//
// Lab Tasks
// ---------
// 1. Detect SPI clock edges.
// 2. Detect Chip Select.
// 3. Receive one byte.
// 4. Transmit one byte.
// 5. Generate data_valid after reception.
//
//////////////////////////////////////////////////////////////////////////////////

module spi_slave
(
    input  wire       clk,
    input  wire       rst_n,

    input  wire       sclk,
    input  wire       cs_n,

    input  wire       mosi,
    output reg        miso,

    input  wire [7:0] tx_data,

    output reg [7:0]  rx_data,

    output reg        data_valid
);

    //====================================================
    // Internal Registers
    //====================================================
    reg sclk_d;
    reg cs_d;

    reg [2:0] bit_cnt;
    reg [7:0] tx_shift;
    reg [7:0] rx_shift;


    //====================================================
    // Edge Detection
    //====================================================
    // Detect SCLK rising edge
    assign sclk_rise = (sclk == 1'b1) && (sclk_d == 1'b0);

    // Detect SCLK falling edge
    assign sclk_fall = (sclk == 1'b0) && (sclk_d == 1'b1);

    // Detect Chip Select falling edge
    assign cs_fall   = (cs_n == 1'b0) && (cs_d == 1'b1);


    //====================================================
    // Synchronize Signals
    //====================================================
    always @(posedge clk or negedge rst_n)
    begin
        if(!rst_n)
        begin
            //--------------------------------------------
            // Initialize delayed signals
            //--------------------------------------------
            sclk_d <= 1'b0;
            cs_d   <= 1'b1; // CS active low, default idle high
        end
        else
        begin
            //--------------------------------------------
            // Store previous values of SCLK and CS
            //--------------------------------------------
            sclk_d <= sclk;
            cs_d   <= cs_n;
        end
    end


    //====================================================
    // SPI Slave Logic
    //====================================================
    always @(posedge clk or negedge rst_n)
    begin
        if(!rst_n)
        begin
            //--------------------------------------------
            // Initialize all registers
            //--------------------------------------------
            bit_cnt    <= 3'd0;
            tx_shift   <= 8'd0;
            rx_shift   <= 8'd0;
            miso       <= 1'b0;
            rx_data    <= 8'd0;
            data_valid <= 1'b0;
        end
        else
        begin
            //--------------------------------------------
            // Default data_valid signal
            //--------------------------------------------
            data_valid <= 1'b0;

            //------------------------------------------------
            // Chip Select Inactive
            //------------------------------------------------
            if(cs_n)
            begin
                //----------------------------------------
                // Load transmit data & Reset bit counter
                //----------------------------------------
                tx_shift <= tx_data;
                bit_cnt  <= 3'd7;       // Pre-load counter to match MSB index (7 downto 0)
                miso     <= tx_data[7]; // Pre-drive MSB onto MISO line for Mode 0
            end
            //------------------------------------------------
            // Chip Select Active
            //------------------------------------------------
            else
            begin
                //----------------------------------------
                // Detect beginning of SPI transaction
                //----------------------------------------
                if (cs_fall) begin
                    tx_shift <= tx_data;
                    bit_cnt  <= 3'd7;
                    miso     <= tx_data[7]; // Ensure immediate driver execution upon select drop
                end

                //----------------------------------------
                // Rising Edge: Receive data from MOSI
                //----------------------------------------
                if (sclk_rise) begin
                    // Sample incoming bit from MOSI (MSB first)
                    rx_shift <= {rx_shift[6:0], mosi};
                    
                    // Once bit_cnt equals 0 on a sample cycle, the 8th bit has successfully landed
                    if (bit_cnt == 3'd0) begin
                        rx_data    <= {rx_shift[6:0], mosi}; // Capture immediate stable data block
                        data_valid <= 1'b1;                  // Strobe valid flag for 1 system clock cycle
                    end
                end

                //----------------------------------------
                // Falling Edge: Shift next transmit bit onto MISO
                //----------------------------------------
                if (sclk_fall) begin
                    if (bit_cnt > 3'd0) begin
                        miso     <= tx_shift[bit_cnt - 1]; // Shift out the next MSB-ordered data bit
                        bit_cnt  <= bit_cnt - 1'b1;        // Decrement step counter
                    end
                end
            end
        end
    end

endmodule