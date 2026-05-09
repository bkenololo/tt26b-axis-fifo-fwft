/*
 * Copyright (c) 2026 Benedictus Kenneth Setiadi
 * SPDX-License-Identifier: Apache-2.0
 */

`default_nettype none

module tt_um_tt08_axis_fifo_fwft_bkenololo (
    input  wire [7:0] ui_in,    // Dedicated inputs
    output wire [7:0] uo_out,   // Dedicated outputs
    input  wire [7:0] uio_in,   // IOs: Input path
    output wire [7:0] uio_out,  // IOs: Output path
    output wire [7:0] uio_oe,   // IOs: Enable path (active high: 1=output, 0=input)
    input  wire       ena,      // always 1 when the design is powered
    input  wire       clk,      // clock
    input  wire       rst_n     // reset_n - low to reset
);

    // ==========================================
    // 1. Pin Mapping to AXI4-Stream Interface
    // ==========================================
    // Map dedicated 8-bit input/output pins directly to AXI data buses
    wire [7:0] s_axis_tdata  = ui_in;
    wire [7:0] m_axis_tdata;
    assign uo_out = m_axis_tdata;

    // Map specific bidirectional pins to AXI control signals
    wire s_axis_tvalid = uio_in[0];
    wire s_axis_tready;
    wire m_axis_tready = uio_in[2];
    wire m_axis_tvalid;
    
    // Internal wires for debug status flags
    wire fifo_full;
    wire fifo_empty;

    // ==========================================
    // 2. Bidirectional Pin Configuration (uio_oe)
    // ==========================================
    // Define which 'uio' pins are outputs (1) and which are inputs (0).
    // Bit mapping: [7:NC, 6:NC, 5:empty_out, 4:full_out, 3:m_valid_out, 2:m_ready_in, 1:s_ready_out, 0:s_valid_in]
    // Binary: 8'b0011_1010 -> Hex: 8'h3A
    assign uio_oe  = 8'h3A;

    // Assign output signals to the respective uio_out pins.
    // For pins configured as inputs, the output assignment is driven to 0.
    assign uio_out[0] = 1'b0;          // Input: s_axis_tvalid
    assign uio_out[1] = s_axis_tready; // Output: s_axis_tready
    assign uio_out[2] = 1'b0;          // Input: m_axis_tready
    assign uio_out[3] = m_axis_tvalid; // Output: m_axis_tvalid
    assign uio_out[4] = fifo_full;     // Output: Debug flag
    assign uio_out[5] = fifo_empty;    // Output: Debug flag
    assign uio_out[6] = 1'b0;          // Unused / NC
    assign uio_out[7] = 1'b0;          // Unused / NC

    // ==========================================
    // 3. Core FIFO Instantiation
    // ==========================================
    // Instantiate the main AXI4-Stream FWFT FIFO logic
    axis_fifo_fwft_bkenololo #(
        .DATA_WIDTH(8),
        .DEPTH(16) 
    ) core_inst (
        .clk            (clk),
        .rst_n          (rst_n),
        
        // Slave Interface (Write)
        .s_axis_tdata   (s_axis_tdata),
        .s_axis_tvalid  (s_axis_tvalid),
        .s_axis_tready  (s_axis_tready),
        
        // Master Interface (Read)
        .m_axis_tdata   (m_axis_tdata),
        .m_axis_tvalid  (m_axis_tvalid),
        .m_axis_tready  (m_axis_tready),
        
        // Status Flags
        .fifo_full      (fifo_full),
        .fifo_empty     (fifo_empty)
    );

    // ==========================================
    // 4. Unused Signal Handling
    // ==========================================
    // Suppress synthesis and linter warnings for unused inputs 
    // by performing a bitwise AND reduction.
    wire _unused = &{ena, uio_in[7:3], uio_in[1], 1'b0};

endmodule
