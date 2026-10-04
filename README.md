# Serial Communication Protocols in Verilog: UART · SPI · I²C

RTL implementations of the three most common on-board serial protocols, each with a testbench and a **Nexys A7 (Artix-7)** top level. These are from the Digital Systems Design module of the Digital IC Design & Verification training at GIKI (USTP INSPIRE).

| Protocol | Blocks | Settings | Testbench |
|---|---|---|---|
| **UART** | `baud_rate_generator`, `uart_tx`, `uart_rx` (16× oversampling), `uart_top` | 8-N-1, 9600 baud @ 100 MHz | TX→RX loopback of 0x55, 0xA5, 0x41, 0x42, 0xFF, 0x00, with PASS/FAIL per byte and a framing-error check |
| **SPI** | `spi_master`, `spi_slave`, `spi_top` | Mode 0 (CPOL=0, CPHA=0), 8-bit full duplex, programmable SCLK divider | Master sends 0xA5 while the slave sends 0x5A, and both directions are checked |
| **I²C** | `i2c_master`, `i2c_slave`, `i2c_top` | 7-bit address (slave 0x50), 100 kHz standard mode, open-drain SDA | Single-byte write. The testbench checks for an ACK and confirms the slave received 0x3C |

## Repository layout

```
uart/  baud_rate_generator.v  uart_tx.v  uart_rx.v  uart_top.v  tb_uart.v  uart_nexys_a7.xdc
spi/   spi_master.v  spi_slave.v  spi_top.v  tb_spi.v  spi_nexys_a7.xdc
i2c/   i2c_master.v  i2c_slave.v  i2c_top.v  tb_i2c.v
docs/  simulation waveforms, PuTTY capture, board photo
```

## Design notes

### UART
- A single baud generator makes two ticks:
  - a 1× tick for the transmitter
  - a 16× tick for the receiver
- **TX FSM:** IDLE → START → 8 DATA bits (LSB first) → STOP, with `busy` and a one-cycle `done` pulse.
- **RX:** detects the falling start edge and re-checks the start bit at its midpoint. It then samples each data bit every 16 ticks, so each sample lands mid-bit, and flags `framing_error` when the stop bit is low.
- **On the board:** the switches set the byte, BTNC sends it, and the received byte appears on LED[7:0], with the status flags on LED[8:11]. Bytes were sent from the board to a PC over USB-UART and shown in PuTTY.

### SPI
- The master divides the 100 MHz clock to make SCLK.
- It drives MOSI on the falling edge and samples MISO on the rising edge (Mode 0).
- CS_n stays low for the whole 8-bit frame.
- The slave shifts in step with SCLK, so one frame is a full-duplex byte exchange.

### I²C
- The master runs on a quarter-period tick (`CLOCK_FREQ / (I2C_FREQ × 4)`). This lets it place SDA changes in the SCL-low phase and generate START/STOP while SCL is high.
- **FSM:** START → address + R/W → ACK → WRITE/READ byte → ACK/NACK → STOP. A missing ACK sets `ack_error`.
- SDA is open-drain on both sides (`1'bz` when releasing), and the testbench models the pull-up with `tri1`.

## Running

Each folder is self-contained. Add the `.v` files of one protocol to a Vivado project. Then either:
- simulate it with its `tb_*.v` as the top, or
- set `*_top.v` as the top and add the matching `.xdc` (UART and SPI) to build a bitstream for the Nexys A7.

The I²C top has no `.xdc` in this repo.

## Tools

Verilog · Xilinx Vivado 2025.1 · Nexys A7-100T · PuTTY
