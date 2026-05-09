# 8-bit AXI4-Stream FWFT FIFO

[![GDS](../../workflows/gds/badge.svg)](../../actions/workflows/gds.yaml) [![Docs](../../workflows/docs/badge.svg)](../../actions/workflows/docs.yaml) [![Test](../../workflows/test/badge.svg)](../../actions/workflows/test.yaml)

Implementation of a high-performance **First-Word Fall-Through (FWFT)** FIFO with an AXI4-Stream interface, designed for the Tiny Tapeout SKY130 shuttle.

## Project Overview

This project implements a synchronous FIFO with a depth of 16 and a data width of 8 bits. Unlike standard FIFOs that require a 1-cycle latency to read data, this **FWFT** architecture ensures that the first data written to an empty FIFO is immediately available on the output bus.

### Key Features
*   **Zero-latency (FWFT):** Data is available on `m_axis_tdata` as soon as it is written.
*   **AXI4-Stream Protocol:** Uses standard `tvalid` and `tready` handshaking for both Master and Slave interfaces.
*   **Resource Efficient:** Optimized for 130nm ASIC standard cell libraries, utilizing a Register File (DFF) based storage.
*   **Full Verification:** Passed RTL and Gate-Level simulations (GLS) using `cocotb`.

---

## Architecture

The FIFO uses a dual-pointer (read/write) ring buffer logic with 5-bit pointers to accurately track empty and full conditions for a 16-slot array. The FWFT behavior is achieved by using combinational read logic from the internal register file.

### Pin Mapping
| Pin | Name | Direction | Description |
|---|---|---|---|
| `ui_in[7:0]` | `s_axis_tdata` | Input | Slave Data Input |
| `uio_in[0]` | `s_axis_tvalid` | Input | Slave Valid Signal |
| `uio_out[1]` | `s_axis_tready` | Output | Slave Ready Signal |
| `uo_out[7:0]` | `m_axis_tdata` | Output | Master Data Output |
| `uio_out[3]` | `m_axis_tvalid` | Output | Master Valid Signal |
| `uio_in[2]` | `m_axis_tready` | Input | Master Ready Signal |
| `uio_out[4]` | `fifo_full` | Output | Debug: FIFO Full Flag |
| `uio_out[5]` | `fifo_empty` | Output | Debug: FIFO Empty Flag |

---

## How to Test

1.  **Environment:** Ensure you have the Tiny Tapeout environment and `cocotb` installed.
2.  **Run Simulation:**
    ```bash
    cd test
    make
