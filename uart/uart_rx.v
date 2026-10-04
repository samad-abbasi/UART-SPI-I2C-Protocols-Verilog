`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Module Name: uart_rx
// Description:
// UART Receiver using 16x oversampling.
//
// Lab Task:
// Complete the UART Receiver by implementing:
//   1. Input synchronization
//   2. UART state machine
//   3. Start bit detection
//   4. Data bit reception
//   5. Stop bit verification
//   6. Data valid and framing error generation
//////////////////////////////////////////////////////////////////////////////////

module uart_rx #(
    parameter integer OVERSAMPLE = 16
)(
    input  wire       clk,
    input  wire       rst_n,
    input  wire       sample_tick,
    input  wire       rx,

    output reg [7:0]  data_out,
    output reg        data_valid,
    output reg        framing_error
);

    //====================================================
    // State Encoding
    //====================================================
    localparam ST_IDLE  = 2'd0;
    localparam ST_START = 2'd1;
    localparam ST_DATA  = 2'd2;
    localparam ST_STOP  = 2'd3;

    //====================================================
    // Internal Registers
    //====================================================
    reg [1:0] state;

    reg [3:0] sample_count;

    reg [2:0] bit_index;

    reg [7:0] shift_reg;

    // Synchronizer Registers
    reg rx_meta;
    reg rx_sync;

    //====================================================
    // Part 1
    // Synchronize the asynchronous RX input
    //====================================================
    always @(posedge clk or negedge rst_n)
    begin
        if(!rst_n)
        begin
         rx_meta <=1'b1;   // Initialize synchronizer registers
         rx_sync <=1'b1;
        end
        else
        begin
          rx_meta <=rx;
         rx_sync <= rx_meta;  // Implement two-stage synchronizer
        end
    end


    //====================================================
    // Part 2
    // UART Receiver State Machine
    //====================================================
    always @(posedge clk or negedge rst_n)
    begin
        if(!rst_n)
        begin
            // Reset all registers
            
        state<= ST_IDLE;
         sample_count   <= 4'd0;
        bit_index      <= 3'd0;
         shift_reg      <= 8'd0;
        data_out       <= 8'd0;
         data_valid     <= 1'b0;
        framing_error  <= 1'b0;
        end
        else
        begin

            // Default output
            data_valid <= 1'b0;

            if(sample_tick)
            begin

                case(state)

                //------------------------------------------------
                // IDLE State
                //------------------------------------------------
                ST_IDLE:
                begin
                    // Wait for start bit (RX goes LOW)
                    framing_error <= 1'b0;

                    if(rx_sync == 1'b0)
                    begin
                        sample_count <= 4'd0;
                        state <= ST_START;
                    end
                end


                //------------------------------------------------
                // START State
                //------------------------------------------------
                ST_START:
                begin
                    // Wait until middle of start bit
                    // Verify it is still LOW
                    // Otherwise return to IDLE
                    sample_count <= sample_count + 1'b1;

                    // Sample in middle of start bit
                    if(sample_count == (OVERSAMPLE/2)-1)
                    begin
                        if(rx_sync == 1'b0)
                        begin
                            sample_count <= 4'd0;
                            bit_index <= 3'd0;
                            state <= ST_DATA;
                        end
                        else 
                         state <= ST_IDLE;
                       
                           
                 end           
                end


                //------------------------------------------------
                // DATA State
                //------------------------------------------------
                ST_DATA:
                begin
                    // Receive 8 data bits
                    // Store each bit into shift register
                    // Increment bit counter
                    
                     sample_count <= sample_count + 1'b1;

                    if(sample_count == OVERSAMPLE-1)
                    begin
                        sample_count <= 4'd0;

                        // Store received bit (LSB first)
                        shift_reg[bit_index] <= rx_sync;

                        if(bit_index == 3'd7)
                        begin
                            state <= ST_STOP;
                        end
                        else
                        begin
                            bit_index <= bit_index + 1'b1;
                        end
                    end
                end


                //------------------------------------------------
                // STOP State
                //------------------------------------------------
                ST_STOP:
                begin
                    // Check stop bit
                    // Copy received byte to data_out
                    // Assert data_valid if stop bit is HIGH
                    // Otherwise generate framing_error
                     sample_count <= sample_count + 1'b1;

                    if(sample_count == OVERSAMPLE-1)
                    begin
                        sample_count <= 4'd0;

                        if(rx_sync == 1'b1)
                        begin
                            data_out <= shift_reg;
                            data_valid <= 1'b1;
                            framing_error <= 1'b0;
                        end
                        else
                        begin
                            framing_error <= 1'b1;
                        end

                        state <= ST_IDLE;
                    end
                end


                //------------------------------------------------
                // Default
                //------------------------------------------------
                default:
                begin
                     state <= ST_IDLE;  // Return to IDLE
                end

                endcase

            end

        end
    end

endmodule