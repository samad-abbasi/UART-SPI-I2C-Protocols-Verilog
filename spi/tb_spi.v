`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Module Name : tb_spi
//
// Description:
// Testbench for SPI Master and SPI Slave
//
// Lab Tasks
// ---------
// 1. Generate a 100 MHz clock.
// 2. Apply reset.
// 3. Instantiate SPI Master.
// 4. Instantiate SPI Slave.
// 5. Connect SPI signals.
// 6. Perform one SPI transaction.
// 7. Verify transmitted and received data.
// 8. Observe SPI waveforms.
//
//////////////////////////////////////////////////////////////////////////////////

module tb_spi;

    //====================================================
    // Testbench Registers
    //====================================================
    reg clk;
    reg rst_n;
    reg start;
    reg [7:0] master_tx;

    //====================================================
    // Testbench Wires
    //====================================================
    wire [7:0] master_rx;
    wire       busy;
    wire       done;

    wire       mosi;
    wire       miso;
    wire       sclk;
    wire       cs_n;

    wire [7:0] slave_rx;
    wire       slave_valid;

    // Constant for Slave TX Data
    localparam [7:0] SLAVE_TX_DATA = 8'h5A;


    //====================================================
    // SPI Master
    //====================================================
    // Instantiate SPI Master
    spi_master #(
        .CLOCK_DIV(50) // 100MHz / (2 * 50) = 1MHz SPI Clock frequency
    ) u_spi_master (
        .clk     (clk),
        .rst_n   (rst_n),
        .start   (start),
        .tx_data (master_tx),
        .miso    (miso),
        .mosi    (mosi),
        .sclk    (sclk),
        .cs_n    (cs_n),
        .rx_data (master_rx),
        .busy    (busy),
        .done    (done)
    );


    //====================================================
    // SPI Slave
    //====================================================
    // Instantiate SPI Slave
    spi_slave u_spi_slave (
        .clk        (clk),
        .rst_n      (rst_n),
        .sclk       (sclk),
        .cs_n       (cs_n),
        .mosi       (mosi),
        .miso       (miso),
        .tx_data    (SLAVE_TX_DATA), // Hardcoded slave response payload
        .rx_data    (slave_rx),
        .data_valid (slave_valid)
    );


    //====================================================
    // Clock Generation
    //====================================================
    // Generate a 100 MHz clock (Clock Period = 10 ns)
    initial
    begin
        clk = 1'b0;
    end

    always
    begin
        #5 clk = ~clk; // Toggle every 5ns for a total 10ns cycle
    end


    //====================================================
    // Test Sequence
    //====================================================
    initial
    begin
        //------------------------------------------------
        // Generate waveform dump
        //------------------------------------------------
        $dumpfile("tb_spi.vcd");
        $dumpvars(0, tb_spi);

        //------------------------------------------------
        // Initialize all signals
        //------------------------------------------------
        start     = 1'b0;
        master_tx = 8'h00;

        //------------------------------------------------
        // Apply reset
        //------------------------------------------------
        rst_n = 1'b0;
        #40; // Hold reset low for 4 clock cycles

        //------------------------------------------------
        // Wait after reset
        //------------------------------------------------
        @(posedge clk);
        rst_n = 1'b1;
        repeat(5) @(posedge clk); // Allow system stability padding

        //------------------------------------------------
        // Start SPI transaction
        //------------------------------------------------
        $display("[TB] --- Starting SPI Full-Duplex Transaction ---");
        master_tx = 8'hA5; // Master sends 0xA5, expects to receive 0x5A
        
        @(posedge clk);
        start = 1'b1;     // Assert start pulse
        @(posedge clk);
        start = 1'b0;     // Clear start pulse (1-cycle pulse duration)

        //------------------------------------------------
        // Wait until transfer completes
        //------------------------------------------------
        @(posedge done);  // Block execution until master asserts done flag
        @(posedge clk);   // Cycle offset to capture safe updated register sets

        //------------------------------------------------
        // Compare transmitted and received data
        //------------------------------------------------
        // Check 1: Did the slave receive what the master transmitted?
        // Check 2: Did the master receive what the slave transmitted?
        if ((slave_rx == 8'hA5) && (master_rx == SLAVE_TX_DATA)) begin
            //--------------------------------------------
            // Display PASS
            //--------------------------------------------
            $display("[TB] SUCCESS: SPI Transaction verification PASSED!");
            $display("[TB] Master Sent: 0x%h | Slave Received: 0x%h", 8'hA5, slave_rx);
            $display("[TB] Slave Sent:  0x%h | Master Received: 0x%h", SLAVE_TX_DATA, master_rx);
        end
        else begin
            //--------------------------------------------
            // Display FAIL
            //--------------------------------------------
            $display("[TB] ERROR: SPI Transaction verification FAILED!");
            $display("[TB] Expected Master to send 0xA5 -> Slave got: 0x%h", slave_rx);
            $display("[TB] Expected Slave to send 0x5A  -> Master got: 0x%h", master_rx);
        end

        //------------------------------------------------
        // Wait for waveform viewing
        //------------------------------------------------
        #1000; 

        //------------------------------------------------
        // Finish simulation
        //------------------------------------------------
        $display("[TB] Simulation Finished.");
        $finish;
    end

endmodule