`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Module Name: uart_tx
// Description:
// UART Transmitter (8 Data Bits, No Parity, 1 Stop Bit)
//
// Lab Task:
// Complete the UART transmitter by implementing:
//   1. Idle state
//   2. Start bit transmission
//   3. Data bit transmission (LSB first)
//   4. Stop bit transmission
//   5. Busy and done signal generation
//////////////////////////////////////////////////////////////////////////////////

module uart_tx(
    input  wire       clk,
    input  wire       rst_n,
    input  wire       baud_tick,
    input  wire       start,
    input  wire [7:0] data_in,

    output reg        tx,
    output reg        busy,
    output reg        done
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

    reg [2:0] bit_index;

    reg [7:0] shift_reg;

    //====================================================
    // UART Transmitter State Machine
    //====================================================
    always @(posedge clk or negedge rst_n)
    begin

        if(!rst_n)
        begin
            //------------------------------------------------
            // Reset all registers
            // Set TX line HIGH (Idle)
            //------------------------------------------------
            state <=ST_IDLE;
            bit_index<=3'b0;
            shift_reg<=8'b0;
            tx<=1'b1;
            busy<=1'b0;
            done<=1'b0;
        end
        else
        begin

            //------------------------------------------------
            // Make done signal active for only one clock cycle
            //------------------------------------------------
       
            done<=1'b0;
            case(state)

            //------------------------------------------------
            // IDLE State
            //------------------------------------------------
            ST_IDLE:
            begin

              tx<=1'b1;  
              busy <= 1'b0;
              
                        // TX line remains HIGH
             if(start) begin       // Wait for start signal
              shift_reg<=data_in;  // Load data into shift register
              bit_index<=3'b0;      // Initialize bit counter
              busy<=1'b1;        // Set busy signal
              state <=ST_START;   // Move to START state
            end
            end


            //------------------------------------------------
            // START State
            //------------------------------------------------
            ST_START:
            begin

               tx<=1'b0;  // Transmit start bit (Logic LOW)
               if(baud_tick)    // Wait for baud_tick
                begin
                    state <= ST_DATA;     // Move to DATA state
                end
            end   
               

          


            //------------------------------------------------
            // DATA State
            //------------------------------------------------
            ST_DATA:
            begin

             // Transmit one data bit
              // Send LSB first
                // Increment bit counter
                // After transmitting all 8 bits,
               // move to STOP state
               tx<=shift_reg[0];
              
               if(baud_tick) begin
               shift_reg<=shift_reg>>1;
               
               if(bit_index==3'd7)
               begin
               state<=ST_STOP;
               end
              
               else
                bit_index <= bit_index + 1'b1;           
               
               end

            end


            //------------------------------------------------
            // STOP State
            //------------------------------------------------
            ST_STOP:
            begin

                // Transmit stop bit (Logic HIGH)
                // Wait for baud_tick
                // Clear busy signal
                // Generate done pulse
                // Return to IDLE state
                 tx <= 1'b1;   

                if(baud_tick)
                begin
                    busy  <= 1'b0;
                    done  <= 1'b1;
                    state <= ST_IDLE;
                end
            end


            //------------------------------------------------
            // Default State
            //------------------------------------------------
            default:
            begin

                // Return to IDLE state
                state <= ST_IDLE;
                tx    <= 1'b1;
                busy  <= 1'b0;
            end

            endcase

        end

    end

endmodule