`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Module Name : i2c_slave
//
// Description:
// Educational I2C Slave Controller
//
// Features
// --------
// • 7-bit Slave Address
// • Single-byte Write
// • Single-byte Read
// • ACK Generation
// • Open-Drain SDA
//
// Lab Tasks
// ---------
// 1. Detect START condition.
// 2. Detect STOP condition.
// 3. Receive slave address.
// 4. Compare received address with SLAVE_ADDR.
// 5. Generate ACK.
// 6. Receive one data byte.
// 7. Transmit one data byte.
// 8. Generate ACK after write.
//
//////////////////////////////////////////////////////////////////////////////////
module i2c_slave #(
    parameter [6:0] SLAVE_ADDR = 7'h50
)
(
    input  wire       clk,
    input  wire       rst_n,

    input  wire       scl,
    inout  wire       sda,

    output reg [7:0]  received_data,
    input  wire [7:0] transmit_data,

    output reg        data_valid
);

    //====================================================
    // State Encoding
    //====================================================

    localparam ST_IDLE      = 3'd0;
    localparam ST_ADDR      = 3'd1;
    localparam ST_ACK_ADDR  = 3'd2;
    localparam ST_WRITE     = 3'd3;
    localparam ST_ACK_DATA  = 3'd4;
    localparam ST_READ      = 3'd5;


    //====================================================
    // Internal Registers
    //====================================================

    reg [2:0] state;

    reg [3:0] bit_cnt;

    reg [7:0] shift_reg;

    reg rw_bit;

    reg [1:0] ack_phase;

    reg sda_drive_low;

    reg scl_d;
    reg sda_d;


    //====================================================
    // Open-Drain SDA Driver
    //====================================================

    // Drive SDA LOW when required.
    // Otherwise release the line.

    assign sda = (sda_drive_low) ? 1'b0:1'bz;


    //====================================================
    // Edge Detection
    //====================================================

    // Detect SCL rising edge

    wire scl_rise;
    assign scl_rise = (~scl_d) & scl;

    // Detect SCL falling edge

    wire scl_fall;
      assign scl_fall = scl_d & (~scl);

    // Detect START condition

    wire start_condition;
       assign start_condition = sda_d & (~sda) & scl;

    // Detect STOP condition

    wire stop_condition;
     assign stop_condition = (~sda_d) & sda & scl;

    //====================================================
    // Synchronize SCL and SDA
    //====================================================

    always @(posedge clk or negedge rst_n)
    begin

        if(!rst_n)
        begin

            //--------------------------------------------
            // Initialize delayed signals
            //--------------------------------------------
           scl_d <= 1'b1;
           sda_d <= 1'b1;
        end
        else
        begin

            //--------------------------------------------
            // Store previous values of
            // SCL and SDA
            //--------------------------------------------
              scl_d <= scl;
             sda_d <= sda;
        end

    end


    //====================================================
    // I2C Slave State Machine
    //====================================================

    always @(posedge clk or negedge rst_n)
    begin

        if(!rst_n)
        begin

            //--------------------------------------------
            // Initialize all registers
            //--------------------------------------------
            state           <= ST_IDLE;
            ack_phase       <= 2'd0;
            bit_cnt         <= 4'd0;
            shift_reg       <= 8'd0;
            rw_bit          <= 1'b0;
            sda_drive_low   <= 1'b0;
            received_data   <= 8'd0;
            data_valid      <= 1'b0;
        end
        else
        begin

            //--------------------------------------------
            // Default data_valid signal
            //--------------------------------------------
               data_valid <= 1'b0;

            //--------------------------------------------
            // Handle STOP condition
            //--------------------------------------------
              if(stop_condition)
                begin
                    state <= ST_IDLE;
                    sda_drive_low <= 1'b0;
                end

            //--------------------------------------------
            // Handle START condition
            //--------------------------------------------
                if(start_condition)
                begin
                    state <= ST_ADDR;
                    bit_cnt <= 4'd7;
                end 

            case(state)

            //------------------------------------------------
            // IDLE State
            //------------------------------------------------
            ST_IDLE:
            begin

                // Release SDA
                // Wait for START condition
                 // Release SDA
                sda_drive_low <= 1'b0;
            
                // Wait for START
                if(start_condition)
                begin
                    state   <= ST_ADDR;
                    bit_cnt <= 4'd7;
                end 
            end


            //------------------------------------------------
            // Receive Address
            //------------------------------------------------
            ST_ADDR:
            begin

                // Receive 7-bit address
                // Receive R/W bit
            if(scl_rise)
            begin
                shift_reg[bit_cnt] <= sda;
        
                if(bit_cnt == 0)
                begin
                    rw_bit <= sda;
                    state <= ST_ACK_ADDR;
                end
                else
                begin
                    bit_cnt <= bit_cnt - 1'b1;
                end
            end    
            end


            //------------------------------------------------
            // Address ACK
            //------------------------------------------------
            ST_ACK_ADDR:
            begin

                // Compare received address
                // with SLAVE_ADDR
                //
                // Generate ACK
                //
                // Decide whether to
                // READ or WRITE
            
               
                case(ack_phase)

                //----------------------------------------
                // Phase 0 : drive ACK/NACK now, and wait
                // out the tail of the last address bit
                //----------------------------------------
                2'd0:
                begin
                    if(shift_reg[7:1] == SLAVE_ADDR)
                        sda_drive_low <= 1'b1;     // ACK
                    else
                        sda_drive_low <= 1'b0;     // NACK

                    if(scl_fall)
                        ack_phase <= 2'd1;
                end

                //----------------------------------------
                // Phase 1 : keep driving ACK/NACK through
                // the master's dedicated ACK clock pulse,
                // finish on its falling edge
                //----------------------------------------
                2'd1:
                begin
                    if(scl_fall)
                    begin
                        sda_drive_low <= 1'b0;     // Release SDA
                        ack_phase     <= 2'd0;

                        if(shift_reg[7:1] == SLAVE_ADDR)
                        begin
                            if(rw_bit)
                            begin
                                shift_reg <= transmit_data;
                                bit_cnt   <= 4'd7;
                                state     <= ST_READ;
                            end
                            else
                            begin
                                bit_cnt <= 4'd7;
                                state   <= ST_WRITE;
                            end
                        end
                        else
                        begin
                            state <= ST_IDLE;   // Address mismatch -> NACK, back to idle
                        end
                    end
                end

                endcase
            end


            //------------------------------------------------
            // Write Operation
            //------------------------------------------------
            ST_WRITE:
            begin

                // Receive one data byte
                // Store into received_data
                // Assert data_valid
           if(scl_rise)
            begin
                shift_reg[bit_cnt] <= sda;
        
                if(bit_cnt == 0)
                begin
                    received_data <= shift_reg;
                    data_valid <= 1'b1;
                    state <= ST_ACK_DATA;
                end
                else
                begin
                    bit_cnt <= bit_cnt - 1'b1;
                end
            end 
            end


            //------------------------------------------------
            // ACK Data
            //------------------------------------------------
            ST_ACK_DATA:
            begin

                // Generate ACK
                // Return to IDLE
                //
               
                case(ack_phase)

                //----------------------------------------
                // Phase 0 : drive ACK, wait out the tail
                // of the last data bit
                //----------------------------------------
                2'd0:
                begin
                    sda_drive_low <= 1'b1;    // ACK

                    if(scl_fall)
                        ack_phase <= 2'd1;
                end

                //----------------------------------------
                // Phase 1 : keep ACK asserted through the
                // master's dedicated ACK clock pulse,
                // release and finish on its falling edge
                //----------------------------------------
                2'd1:
                begin
                    if(scl_fall)
                    begin
                        sda_drive_low <= 1'b0;    // Release SDA after ACK pulse
                        ack_phase     <= 2'd0;
                        state         <= ST_IDLE;
                    end
                end

                endcase
            end


            //------------------------------------------------
            // Read Operation
            //------------------------------------------------
            ST_READ:
            begin

                // Send transmit_data
                // MSB first
                // Release SDA after last bit
                //recieving...scl_rise   : transmitting...scl_fall
            if(scl_fall)
            begin
                if(shift_reg[bit_cnt])
                    sda_drive_low <= 1'b0;      // Send '1'
                else
                    sda_drive_low <= 1'b1;      // Send '0';
        
                if(bit_cnt == 0)
                begin
                    sda_drive_low <= 1'b0;      // Release SDA
                    state <= ST_IDLE;
                end
                else
                begin
                    bit_cnt <= bit_cnt - 1'b1;
                end
            end 
            end


            //------------------------------------------------
            // Default
            //------------------------------------------------
            default:
            begin

                // Return to IDLE
             state <= ST_IDLE;
               sda_drive_low <= 1'b0;
            end

            endcase

        end

    end
    endmodule