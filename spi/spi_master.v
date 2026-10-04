`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Module Name : spi_master
//
// Description:
// SPI Master Controller
//
// Features
// --------
// • SPI Mode 0 (CPOL = 0, CPHA = 0)
// • Full-Duplex Communication
// • 8-bit Data Transfer
// • Programmable Clock Divider
//
// Lab Tasks
// ---------
// 1. Generate SPI clock.
// 2. Generate Chip Select.
// 3. Transmit one byte.
// 4. Receive one byte.
// 5. Control SPI transfer using an FSM.
//
//////////////////////////////////////////////////////////////////////////////////

module spi_master #(
    parameter integer CLOCK_DIV = 50  // System clocks per half-period of sclk
)
(
    input  wire        clk,
    input  wire        rst_n,

    input  wire        start,

    input  wire [7:0]  tx_data,

    input  wire        miso,

    output reg         mosi,
    output reg         sclk,
    output reg         cs_n,

    output reg [7:0]   rx_data,

    output reg         busy,
    output reg         done
);

    //====================================================
    // State Encoding
    //====================================================
    localparam ST_IDLE      = 2'd0;
    localparam ST_TRANSFER  = 2'd1;
    localparam ST_DONE      = 2'd2;


    //====================================================
    // Internal Registers
    //====================================================
    reg [1:0]  state;
    reg [7:0]  tx_shift;
    reg [7:0]  rx_shift;
    reg [2:0]  bit_cnt;   // Tracks 0 to 7 bits
    reg [31:0] div_cnt;   // Clock division counter
    wire div_tick;
    // Track internal phase/edges of SCLK
    reg   sclk_edge_phase; // 0 = Rising edge phase, 1 = Falling edge phase

    //====================================================
    // Clock Divider Tick Generator
    //====================================================
    // Generates a tick at every half-period of the SPI clock
    assign div_tick = (div_cnt == (CLOCK_DIV - 1));

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            div_cnt <= 32'd0;
        end else begin
            if (state == ST_TRANSFER) begin
                if (div_tick)
                    div_cnt <= 32'd0;
                else
                    div_cnt <= div_cnt + 1'b1;
            end else begin
                div_cnt <= 32'd0;
            end
        end
    end


    //====================================================
    // SPI Master FSM
    //====================================================
    always @(posedge clk or negedge rst_n)
    begin
        if(!rst_n)
        begin
            //--------------------------------------------
            // Initialize all registers
            //--------------------------------------------
            state           <= ST_IDLE;
            tx_shift        <= 8'd0;
            rx_shift        <= 8'd0;
            bit_cnt         <= 3'd0;
            sclk_edge_phase <= 1'b0;
            
            mosi            <= 1'b0;
            sclk            <= 1'b0; // CPOL = 0
            cs_n            <= 1'b1; // CS is active-low
            rx_data         <= 8'd0;
            busy            <= 1'b0;
            done            <= 1'b0;
        end
        else
        begin
            //--------------------------------------------
            // Default done signal
            //--------------------------------------------
            done <= 1'b0;

            case(state)

            //------------------------------------------------
            // IDLE State
            //------------------------------------------------
            ST_IDLE:
            begin
                sclk            <= 1'b0; // CPOL = 0
                sclk_edge_phase <= 1'b0;
                bit_cnt         <= 3'd7; // Setup to count from MSB (7) down to LSB (0)
                busy            <= 1'b0;

                if (start) begin
                    cs_n     <= 1'b0;             // Activate Chip Select
                    tx_shift <= tx_data;          // Load transmit register
                    mosi     <= tx_data[7];       // Drive first bit (MSB) out immediately (CPHA = 0)
                    busy     <= 1'b1;
                    state    <= ST_TRANSFER;
                end else begin
                    cs_n     <= 1'b1;
                    mosi     <= 1'b0;
                end
            end


            //------------------------------------------------
            // Transfer State
            //------------------------------------------------
            ST_TRANSFER:
            begin
                busy <= 1'b1;
                
                if (div_tick) begin
                    if (!sclk_edge_phase) begin
                        //------------------------------------
                        // SCLK Rising Edge Phase (CPHA = 0)
                        //------------------------------------
                        sclk            <= 1'b1;
                        sclk_edge_phase <= 1'b1;
                        
                        // Sample incoming MISO line (MSB first)
                        rx_shift        <= {rx_shift[6:0], miso};
                    end 
                    else begin
                        //------------------------------------
                        // SCLK Falling Edge Phase
                        //------------------------------------
                        sclk            <= 1'b0;
                        sclk_edge_phase <= 1'b0;
                        
                        if (bit_cnt == 3'd0) begin
                            // All 8 bits transferred
                            state <= ST_DONE;
                        end 
                        else begin
                            // Shift next MOSI bit out on the falling edge
                            mosi    <= tx_shift[bit_cnt - 1];
                            bit_cnt <= bit_cnt - 1'b1;
                        end
                    end
                end
            end


            //------------------------------------------------
            // DONE State
            //------------------------------------------------
            ST_DONE:
            begin
                cs_n    <= 1'b1;       // Deactivate Chip Select
                mosi    <= 1'b0;
                sclk    <= 1'b0;
                rx_data <= rx_shift;   // Output the collected byte
                done    <= 1'b1;       // Assert done flag for 1 cycle
                busy    <= 1'b0;
                state   <= ST_IDLE;    // Return to IDLE
            end


            //------------------------------------------------
            // Default
            //------------------------------------------------
            default:
            begin
                state <= ST_IDLE;
            end

            endcase
        end
    end

endmodule