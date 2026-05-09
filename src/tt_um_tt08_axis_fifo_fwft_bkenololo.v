/*
 * Copyright (c) 2024 Your Name
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
    // 1. PIN MAPPING 
    // ==========================================
    wire [7:0] s_axis_tdata  = ui_in;
    wire [7:0] m_axis_tdata;
    assign uo_out = m_axis_tdata;

    wire s_axis_tvalid = uio_in[0];
    wire s_axis_tready;
    wire m_axis_tready = uio_in[2];
    wire m_axis_tvalid;
    
    wire fifo_full;
    wire fifo_empty;

    // ==========================================
    // 2. CONFIGURASI BIDIRECTIONAL PIN
    // ==========================================
    assign uio_oe  = 8'h3A; // 8'b0011_1010

    assign uio_out[0] = 1'b0; 
    assign uio_out[1] = s_axis_tready;
    assign uio_out[2] = 1'b0; 
    assign uio_out[3] = m_axis_tvalid;
    assign uio_out[4] = fifo_full;
    assign uio_out[5] = fifo_empty;
    assign uio_out[6] = 1'b0; 
    assign uio_out[7] = 1'b0; 

    // ==========================================
    // 3. INSTANTIASI MODUL FIFO LU
    // ==========================================
    axis_fifo_fwft_bkenololo #(
        .DATA_WIDTH(8),
        .DEPTH(16) 
    ) core_inst (
        .clk            (clk),
        .rst_n          (rst_n),
        
        .s_axis_tdata   (s_axis_tdata),
        .s_axis_tvalid  (s_axis_tvalid),
        .s_axis_tready  (s_axis_tready),
        
        .m_axis_tdata   (m_axis_tdata),
        .m_axis_tvalid  (m_axis_tvalid),
        .m_axis_tready  (m_axis_tready),
        
        .fifo_full      (fifo_full),
        .fifo_empty     (fifo_empty)
    );

    wire _unused = &{ena, uio_in[7:3], uio_in[1], 1'b0};

endmodule
