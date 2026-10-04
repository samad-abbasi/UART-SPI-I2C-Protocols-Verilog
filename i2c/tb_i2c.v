`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Module Name : tb_i2c
//
// Description:
// Testbench for I2C Master and I2C Slave
//
// Lab Tasks
// ----------
// 1. Generate a 100 MHz clock.
// 2. Apply reset.
// 3. Instantiate the I2C Master.
// 4. Instantiate the I2C Slave.
// 5. Connect SDA using an open-drain bus.
// 6. Perform an I2C write transaction.
// 7. Verify received data.
// 8. Observe SDA and SCL waveforms.
//
//////////////////////////////////////////////////////////////////////////////////
module tb_i2c;

    //====================================================
    // Testbench Registers
    //====================================================

    reg clk;

    reg rst_n;

    reg start;

    reg rw;

    reg [7:0] tx_data;


    //====================================================
    // Testbench Wires
    //====================================================

    wire [7:0] rx_data;

    wire busy;

    wire done;

    wire ack_error;

    wire scl;

    // Declare SDA as a pull-up line
      // I2C SDA line (pulled HIGH when nobody drives it)
    tri1 sda;


    //====================================================
    // Slave Outputs
    //====================================================

    wire [7:0] slave_received;

    wire slave_valid;


    reg slave_valid_latched;


    //====================================================
    // Clock Generation
    //====================================================

    // Generate a 100 MHz clock
    //
    // Clock Period = 10 ns

    initial
    begin

     clk = 1'b0;
    end

    always
    begin
        #5 clk = ~clk;
    end

   

    always @(posedge clk or negedge rst_n)
    begin
        if(!rst_n)
            slave_valid_latched <= 1'b0;
        else if(slave_valid)
            slave_valid_latched <= 1'b1;
    end


    //====================================================
    // I2C Master
    //====================================================

    // Instantiate I2C Master
    //
    // Parameters:
    //   CLOCK_FREQ_HZ
    //   I2C_FREQ_HZ
    //
    // Connect all ports

    i2c_master
    #(
        .CLOCK_FREQ_HZ(100_000_000),
        .I2C_FREQ_HZ(100_000)
    )
    DUT
    (
        .clk(clk),
        .rst_n(rst_n),

        .start(start),
        .rw(rw),

        .slave_addr(7'h50),
        .tx_data(tx_data),

        .rx_data(rx_data),

        .busy(busy),
        .done(done),
        .ack_error(ack_error),

        .scl(scl),
        .sda(sda)
    );
    //====================================================
    // I2C Slave
    //====================================================

    // Instantiate I2C Slave
    //
    // Slave Address = 7'h50
    //
    // Connect SDA and SCL
    i2c_slave
    #(
        .SLAVE_ADDR(7'h50)
    )
    SLAVE
    (
        .clk(clk),
        .rst_n(rst_n),

        .scl(scl),
        .sda(sda),

        .received_data(slave_received),

        .transmit_data(8'hA5),

        .data_valid(slave_valid)
    );

    //====================================================
    // Test Sequence
    //====================================================

    initial
    begin

        //------------------------------------------------
        // Create waveform dump
        //------------------------------------------------
           $dumpfile("i2c.vcd");
           $dumpvars(0,tb_i2c);


        //------------------------------------------------
        // Initialize all signals
        //------------------------------------------------
        rst_n   = 0;
        start   = 0;
        rw      = 0;          // Write
        tx_data = 8'h3C;
        slave_valid_latched = 1'b0;

        //------------------------------------------------
        // Apply reset
        //------------------------------------------------
           #100;
        rst_n = 1;

        //------------------------------------------------
        // Wait after reset
        //------------------------------------------------
          #100;

        //------------------------------------------------
        // Perform WRITE transaction
        //------------------------------------------------
        //
      
        @(posedge clk);
        start <= 1'b1;

        @(posedge clk);
        start <= 1'b0;

        //------------------------------------------------
        // Assert start signal
        //------------------------------------------------


        //------------------------------------------------
        // Wait until master becomes busy
        //------------------------------------------------
        wait(busy);

        $display("--------------------------------");
        $display("Master Started Transaction");
        $display("--------------------------------");

        //------------------------------------------------
        // Wait until transaction finishes
        //------------------------------------------------
           wait(done);

        //------------------------------------------------
        // Check ACK status
        //------------------------------------------------
             

        //------------------------------------------------
        // Display received data
        //------------------------------------------------
                if(ack_error)
            $display("ACK ERROR");
        else
            $display("ACK RECEIVED");

        if(slave_valid_latched)
            $display("Slave Received = %h",slave_received);
        else
            $display("Slave did not receive data.");

        $display("--------------------------------");

        //------------------------------------------------
        // Wait
        //------------------------------------------------

        #5000;

        //------------------------------------------------
        // Wait for waveform observation
        //------------------------------------------------


        //------------------------------------------------
        // Finish simulation
        //------------------------------------------------
                $finish;
    end

endmodule

