`timescale 1ns / 1ps

module tb_uart;

    reg clk;
    reg rst_n;
    reg start;
    reg [7:0] tx_data;

    wire tx_line;
    wire tx_busy;
    wire tx_done;

    wire rx_valid;
    wire framing_error;
    wire [7:0] rx_data;

    wire tx_tick;
    wire rx_tick;

    // NEXYS A7 board clock is 100 MHz
    localparam integer CLOCK_FREQ_HZ = 100_000_000;

    // Same baud rate used in PuTTY
    localparam integer BAUD_RATE = 9600;

    // 100 MHz clock generation
    // Time period = 10 ns
    initial clk = 1'b0;
    always #5 clk = ~clk;

    // Baud tick for UART transmitter
    baud_rate_generator #(
        .CLOCK_FREQ_HZ(CLOCK_FREQ_HZ),
        .TICK_RATE_HZ(BAUD_RATE)
    ) baud_tx_inst (
        .clk(clk),
        .rst_n(rst_n),
        .tick(tx_tick)
    );

    // 16x oversampling tick for UART receiver
    baud_rate_generator #(
        .CLOCK_FREQ_HZ(CLOCK_FREQ_HZ),
        .TICK_RATE_HZ(BAUD_RATE * 16)
    ) baud_rx_inst (
        .clk(clk),
        .rst_n(rst_n),
        .tick(rx_tick)
    );

    // UART transmitter
    uart_tx tx_inst (
        .clk(clk),
        .rst_n(rst_n),
        .baud_tick(tx_tick),
        .start(start),
        .data_in(tx_data),
        .tx(tx_line),
        .busy(tx_busy),
        .done(tx_done)
    );

    // UART receiver
    // TX line is directly connected to RX input for loopback simulation
    uart_rx rx_inst (
        .clk(clk),
        .rst_n(rst_n),
        .sample_tick(rx_tick),
        .rx(tx_line),
        .data_out(rx_data),
        .data_valid(rx_valid),
        .framing_error(framing_error)
    );

    // Task to transmit one byte and check received byte
    task send_and_check;
        input [7:0] data_byte;
        begin
            wait(tx_busy == 1'b0);//

            @(posedge clk);
            tx_data <= data_byte;
            start   <= 1'b1;

            @(posedge clk);
            start   <= 1'b0;

            // Wait until receiver receives complete byte
            wait(rx_valid == 1'b1);

            @(posedge clk);

            if (rx_data == data_byte && framing_error == 1'b0) begin
                $display("PASS: Sent = %h, Received = %h", data_byte, rx_data);
            end else begin
                $display("FAIL: Sent = %h, Received = %h, Framing Error = %b",
                         data_byte, rx_data, framing_error);
                $stop;
            end

            // Small delay before next byte
            repeat(20) @(posedge clk);
        end
    endtask

    initial begin
        // Initial values
        rst_n   = 1'b0;
        start   = 1'b0;
        tx_data = 8'h00;

        // Hold reset for some clock cycles
        repeat(20) @(posedge clk);
        rst_n = 1'b1;

        // Wait a little after reset
        repeat(20) @(posedge clk);

        // Test different bytes
        send_and_check(8'h55); // 01010101
        send_and_check(8'hA5); // 10100101
        send_and_check(8'h41); // ASCII 'A'
        send_and_check(8'h42); // ASCII 'B'
        send_and_check(8'hFF);
        send_and_check(8'h00);

        $display("UART simulation completed successfully.");
        $finish;
    end

endmodule