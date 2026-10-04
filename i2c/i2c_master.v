`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Module Name : i2c_master
//
// Description:
// Single-Master I2C Controller
//
// Features:
// • Single-byte Write
// • Single-byte Read
// • 7-bit Slave Address
// • Standard Mode (100 kHz)
//
// Lab Tasks
// ----------
// 1. Generate I2C timing tick.
// 2. Generate START condition.
// 3. Transmit slave address + R/W bit.
// 4. Receive ACK from slave.
// 5. Write one data byte.
// 6. Read one data byte.
// 7. Generate ACK/NACK.
// 8. Generate STOP condition.
//
//////////////////////////////////////////////////////////////////////////////////
module i2c_master #(
    parameter integer CLOCK_FREQ_HZ = 100_000_000,
    parameter integer I2C_FREQ_HZ   = 100_000
)
(
    input  wire       clk,
    input  wire       rst_n,

    input  wire       start,
    input  wire       rw,          // 0 = Write, 1 = Read

    input  wire [6:0] slave_addr,
    input  wire [7:0] tx_data,

    output reg [7:0]  rx_data,

    output reg        busy,
    output reg        done,
    output reg        ack_error,

    output reg        scl,

    inout  wire       sda
);

    //====================================================
    // Clock Divider
    //====================================================

    // Calculate tick divider

    localparam integer TICK_DIV = CLOCK_FREQ_HZ/(I2C_FREQ_HZ*4);


    //====================================================
    // State Encoding
    //====================================================

    localparam ST_IDLE      = 4'd0;
    localparam ST_START     = 4'd1;
    localparam ST_SEND_ADDR = 4'd2;
    localparam ST_ADDR_ACK  = 4'd3;
    localparam ST_WRITE     = 4'd4;
    localparam ST_WRITE_ACK = 4'd5;
    localparam ST_READ      = 4'd6;
    localparam ST_READ_ACK  = 4'd7;
    localparam ST_STOP      = 4'd8;
    localparam ST_DONE      = 4'd9;


    //====================================================
    // Internal Registers
    //====================================================

    reg [3:0] state;

    reg [1:0] phase;

    reg [3:0] bit_cnt;

    reg [7:0] shift_reg;

    reg [31:0] tick_count;

    reg tick;

    reg sda_drive_low;


    //====================================================
    // SDA Open-Drain Driver
    //====================================================

    // Drive SDA LOW when required.
    // Otherwise release the line.

    assign sda = (sda_drive_low) ? 1'b0 : 1'bz;


    //====================================================
    // Tick Generator
    //====================================================

    always @(posedge clk or negedge rst_n)
    begin

        if(!rst_n)
        begin

            //--------------------------------------------
            // Reset counter
            //--------------------------------------------
            tick_count <= 0;
            tick <= 0;
        end
        else
        begin

            //--------------------------------------------
            // Generate timing tick
            //--------------------------------------------
          if(tick_count == TICK_DIV-1)
          begin
           tick_count <= 0;
            tick <= 1;
          end
          else begin
          tick_count <= tick_count + 1'b1;
            tick <= 0;
      
          end
        end

    end


    //====================================================
    // I2C Master State Machine
    //====================================================

    always @(posedge clk or negedge rst_n)
    begin

        if(!rst_n)
        begin

            //--------------------------------------------
            // Initialize all registers
            //--------------------------------------------
      state     <= ST_IDLE;
     phase          <= 2'd0;
     bit_cnt        <= 4'd0;
     shift_reg      <= 8'd0;
     rx_data        <= 8'd0;

     busy           <= 1'b0;
     done           <= 1'b0;
     ack_error      <= 1'b0;

    scl            <= 1'b1;   // Bus idle
    sda_drive_low  <= 1'b0;   // Release SDA
        end
        else
        begin

            //--------------------------------------------
            // Default done signal
            //--------------------------------------------
           done <= 1'b0;

    
            if(state == ST_IDLE && start)
            begin
                shift_reg <= {slave_addr, rw};
                bit_cnt   <= 4'd7;
                phase     <= 2'd0;
                busy      <= 1'b1;
                ack_error <= 1'b0;
                state     <= ST_START;
            end
            else if(tick)
            begin

                case(state)

                //------------------------------------------------
                // IDLE State
                //------------------------------------------------
                ST_IDLE:
                begin

                    // Wait for start command
                    // Load slave address
                    // Initialize bit counter
                  
                
                end


                //------------------------------------------------
                // START Condition
                //------------------------------------------------
                ST_START:
                begin

                    // Generate I2C START condition
                    case(phase)

                //------------------------------------------------
                // Phase 0 : Ensure bus is idle
                //------------------------------------------------
                2'd0:
                begin
                    scl <= 1'b1;
                    sda_drive_low <= 1'b0;      // Release SDA (HIGH via pull-up)
                    phase <= 2'd1;
                end
            
                //------------------------------------------------
                // Phase 1 : Generate START
                //------------------------------------------------
                2'd1:
                begin
                    scl <= 1'b1;
                    sda_drive_low <= 1'b1;      // Pull SDA LOW
                    phase <= 2'd2;
                end
            
                //------------------------------------------------
                // Phase 2 : Pull SCL LOW
                //------------------------------------------------
                2'd2:
                begin
                    scl <= 1'b0;                // Ready to transmit bits
                    phase <= 2'd0;
                    state <= ST_SEND_ADDR;
                end
            
                default:
                    phase <= 2'd0;
            
                endcase 
                    end 


                //------------------------------------------------
                // Send Slave Address + R/W
                //------------------------------------------------
                ST_SEND_ADDR:
                begin

                    // Send address bits
                    // MSB first
                   case(phase)

                //----------------------------------------
                // Phase 0 : Put next bit on SDA
                //----------------------------------------
                2'd0:
                begin
                    scl <= 1'b0;
            
                    if(shift_reg[bit_cnt])
                        sda_drive_low <= 1'b0;      // Send '1' (release SDA)
                    else
                        sda_drive_low <= 1'b1;      // Send '0' (pull SDA LOW)
            
                    phase <= 2'd1;
                end 
    
                //----------------------------------------
                // Phase 1 : Raise SCL
                //----------------------------------------
                2'd1:
                begin
                    scl <= 1'b1;
                    phase <= 2'd2;
                end
            
                //----------------------------------------
                // Phase 2 : Hold SCL HIGH
                //----------------------------------------
                2'd2:
                begin
                    phase <= 2'd3;
                end 
        
                //----------------------------------------
                // Phase 3 : Lower SCL
                //----------------------------------------
                2'd3:
                begin
                    scl <= 1'b0;
            
                    if(bit_cnt == 0)
                    begin
                        phase <= 2'd0;
                        state <= ST_ADDR_ACK;
                    end
                    else
                    begin
                        bit_cnt <= bit_cnt - 1'b1;
                        phase <= 2'd0;
                    end
                end
            
                endcase 
                        end


                //------------------------------------------------
                // Address ACK
                //------------------------------------------------
                ST_ADDR_ACK:
                begin

                    // Release SDA
                    // Read ACK bit
                      case(phase)
        
                //----------------------------------------
                // Phase 0 : Release SDA
                //----------------------------------------
                2'd0:
                begin
                    scl <= 1'b0;
                    sda_drive_low <= 1'b0;      // Release SDA
                    phase <= 2'd1;
                end
        
                //----------------------------------------
                // Phase 1 : Raise SCL
                //----------------------------------------
                2'd1:
                begin
                    scl <= 1'b1;
                    phase <= 2'd2;
                end
                
                //----------------------------------------
                // Phase 2 : Read ACK
                //----------------------------------------
                2'd2:
                begin
                    if(sda == 1'b1)
                        ack_error <= 1'b1;
                
                    phase <= 2'd3;
                end
        
                //----------------------------------------
                // Phase 3 : Lower SCL
                //----------------------------------------
                2'd3:
                begin
                    scl <= 1'b0;
                    phase <= 2'd0;
                
                    if(ack_error)
                        state <= ST_STOP;
                    else if(rw)
                    begin
                        bit_cnt <= 4'd7;
                        state <= ST_READ;
                    end
                    else
                    begin
                        shift_reg <= tx_data;
                        bit_cnt <= 4'd7;
                        state <= ST_WRITE;
                    end
                end
                
                endcase 
                end


                //------------------------------------------------
                // Write Data
                //------------------------------------------------
               ST_WRITE:
                begin
                    case(phase)
                
                    //----------------------------------------
                    // Phase 0 : Put data bit on SDA
                    //----------------------------------------
                    2'd0:
                    begin
                        scl <= 1'b0;
                
                        if(shift_reg[bit_cnt])
                            sda_drive_low <= 1'b0;      // Send '1'
                        else
                            sda_drive_low <= 1'b1;      // Send '0'
                
                        phase <= 2'd1;
                    end
                
                    //----------------------------------------
                    // Phase 1 : Raise SCL
                    //----------------------------------------
                    2'd1:
                    begin
                        scl <= 1'b1;
                        phase <= 2'd2;
                    end
                
                    //----------------------------------------
                    // Phase 2 : Hold SCL HIGH
                    //----------------------------------------
                    2'd2:
                    begin
                        phase <= 2'd3;
                    end
                
                    //----------------------------------------
                    // Phase 3 : Lower SCL
                    //----------------------------------------
                    2'd3:
                    begin
                        scl <= 1'b0;
                
                        if(bit_cnt == 0)
                        begin
                            phase <= 2'd0;
                            state <= ST_WRITE_ACK;
                        end
                        else
                        begin
                            bit_cnt <= bit_cnt - 1'b1;
                            phase <= 2'd0;
                        end
                    end
                
                    default:
                        phase <= 2'd0;
                
                    endcase
                end

                    //------------------------------------------------
                    // Write ACK
                    //------------------------------------------------
                ST_WRITE_ACK:
                begin
                    case(phase)
                
                    //----------------------------------------
                    // Phase 0 : Release SDA
                    //----------------------------------------
                    2'd0:
                    begin
                        scl <= 1'b0;
                        sda_drive_low <= 1'b0;      // Release SDA
                        phase <= 2'd1;
                    end
                
                    //----------------------------------------
                    // Phase 1 : Raise SCL
                    //----------------------------------------
                    2'd1:
                    begin
                        scl <= 1'b1;
                        phase <= 2'd2;
                    end
                
                    //----------------------------------------
                    // Phase 2 : Read ACK
                    //----------------------------------------
                    2'd2:
                    begin
                        if(sda)
                            ack_error <= 1'b1;
                
                        phase <= 2'd3;
                    end
                
                    //----------------------------------------
                    // Phase 3 : Finish ACK cycle
                    //----------------------------------------
                    2'd3:
                    begin
                        scl <= 1'b0;
                        phase <= 2'd0;
                        state <= ST_STOP;
                    end
                
                    default:
                        phase <= 2'd0;
                
                    endcase
                end 
                
    
                    //------------------------------------------------
                    // Read Data
                    //------------------------------------------------
                ST_READ:
                begin

                    // Read one byte
                    // Store into rx_data
                      case(phase)

                //----------------------------------------
                // Phase 0 : Prepare to receive
                //----------------------------------------
                2'd0:
                begin
                    scl <= 1'b0;
                    sda_drive_low <= 1'b0;      // Release SDA
                    phase <= 2'd1;
                end
            
                //----------------------------------------
                // Phase 1 : Raise SCL
                //----------------------------------------
                2'd1:
                begin
                    scl <= 1'b1;
                    phase <= 2'd2;
                end
            
                //----------------------------------------
                // Phase 2 : Sample data
                //----------------------------------------
                2'd2:
                begin
                    shift_reg[bit_cnt] <= sda;
            
                    phase <= 2'd3;
                end
            
                //----------------------------------------
                // Phase 3 : Finish bit
                //----------------------------------------
                2'd3:
                begin
                    scl <= 1'b0;
            
                    if(bit_cnt == 0)
                    begin
                        rx_data <= shift_reg;
                        phase <= 2'd0;
                        state <= ST_READ_ACK;
                    end
                    else
                    begin
                        bit_cnt <= bit_cnt - 1'b1;
                        phase <= 2'd0;
                    end
                end
            
                endcase
                end


                //------------------------------------------------
                // Read ACK/NACK
                //------------------------------------------------
                ST_READ_ACK:
                begin

                    // Send NACK after last byte
                        case(phase)
                
                    2'd0:
                    begin
                        scl <= 1'b0;
                        sda_drive_low <= 1'b0;      // Release SDA = NACK
                        phase <= 2'd1;
                    end
                
                    2'd1:
                    begin
                        scl <= 1'b1;
                        phase <= 2'd2;
                    end
                
                    2'd2:
                    begin
                        phase <= 2'd3;
                    end
                
                    2'd3:
                    begin
                        scl <= 1'b0;
                        phase <= 2'd0;
                        state <= ST_STOP;
                    end
                
                    endcase 
                       
                end


                //------------------------------------------------
                // STOP Condition
                //------------------------------------------------
                ST_STOP:
                begin

                    // Generate STOP condition
                   case(phase)
            
                //----------------------------------------
                // Phase 0
                //----------------------------------------
                2'd0:
                begin
                    scl <= 1'b0;
                    sda_drive_low <= 1'b1;      // Keep SDA LOW
                    phase <= 2'd1;
                end
            
                //----------------------------------------
                // Phase 1
                //----------------------------------------
                2'd1:
                begin
                    scl <= 1'b1;
                    phase <= 2'd2;
                end
            
                //----------------------------------------
                // Phase 2
                //----------------------------------------
                2'd2:
                begin
                    sda_drive_low <= 1'b0;      // Release SDA -> STOP
                    phase <= 2'd0;
                    state <= ST_DONE;
                end

                endcase
                end


                //------------------------------------------------
                // DONE State
                //------------------------------------------------
                ST_DONE:
                begin

                    // Clear busy
                    // Assert done
                    // Return to IDLE
                   busy <= 1'b0;
                    done <= 1'b1;
                    state <= ST_IDLE;
                end


                //------------------------------------------------
                // Default
                //------------------------------------------------
                default:
                begin

                    // Return to IDLE
                       state <= ST_IDLE;
                    phase <= 2'd0;
                end

                endcase

            end

        end

    end

endmodule