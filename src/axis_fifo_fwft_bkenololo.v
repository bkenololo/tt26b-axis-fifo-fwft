/*
 * Copyright (c) 2026 Benedictus Kenneth Setiadi
 * SPDX-License-Identifier: Apache-2.0
 */

`default_nettype none

module axis_fifo_fwft_bkenololo #(
    parameter DATA_WIDTH = 8,
    parameter DEPTH = 16
)(
    input  wire clk,
    input  wire rst_n,

    // AXI4-Stream Slave Interface (Write Port)
    input  wire [DATA_WIDTH-1:0] s_axis_tdata,
    input  wire                  s_axis_tvalid,
    output wire                  s_axis_tready,

    // AXI4-Stream Master Interface (Read Port)
    output wire [DATA_WIDTH-1:0] m_axis_tdata,
    output wire                  m_axis_tvalid,
    input  wire                  m_axis_tready,

    // Status Flags
    output wire fifo_full,
    output wire fifo_empty
);

    // ==========================================
    // Register File Storage
    // ==========================================
    // Implemented as a 2D array. Synthesis tools will map this to standard D-flip-flops 
    // rather than SRAM macros, which is standard for small depths in ASIC flows.
    reg [DATA_WIDTH-1:0] mem [0:DEPTH-1];

    // ==========================================
    // Pointers
    // ==========================================
    // 5-bit pointers: The lower 4 bits [3:0] are used for memory addressing, 
    // while the MSB [4] is used as a wrap-around tracker for full/empty evaluation.
    reg [4:0] wr_ptr;
    reg [4:0] rd_ptr;

    // ==========================================
    // Status Flag Combinational Logic
    // ==========================================
    // FIFO is empty when both pointers are completely identical.
    assign fifo_empty = (wr_ptr == rd_ptr);
    
    // FIFO is full when the addressing bits [3:0] match, but the MSBs differ.
    // This indicates the write pointer has wrapped around exactly one cycle ahead of the read pointer.
    assign fifo_full  = (wr_ptr[4] != rd_ptr[4]) && (wr_ptr[3:0] == rd_ptr[3:0]);

    // ==========================================
    // AXI4-Stream Handshaking & FWFT Logic
    // ==========================================
    // The slave is ready to accept data as long as the FIFO is not completely full.
    assign s_axis_tready = ~fifo_full;
    
    // Master asserts valid data immediately when the FIFO is not empty.
    // This provides the First-Word Fall-Through (FWFT) characteristic.
    assign m_axis_tvalid = ~fifo_empty;
    
    // Asynchronous read: The output data bus is combinationally tied to the memory 
    // array at the current read pointer index, bypassing the need for a read cycle latency.
    assign m_axis_tdata  = mem[rd_ptr[3:0]];

    // Internal enable signals derived from AXI handshakes
    wire write_en = s_axis_tvalid && s_axis_tready;
    wire read_en  = m_axis_tvalid && m_axis_tready;

    // ==========================================
    // Sequential Logic: Memory Write and Pointer Updates
    // ==========================================
    always @(posedge clk) begin
        if (!rst_n) begin
            wr_ptr <= 5'b0;
            rd_ptr <= 5'b0;
        end else begin
            // Execute write operation
            if (write_en) begin
                mem[wr_ptr[3:0]] <= s_axis_tdata;
                wr_ptr <= wr_ptr + 1'b1;
            end
            
            // Execute read operation (advance read pointer)
            if (read_en) begin
                rd_ptr <= rd_ptr + 1'b1;
            end
        end
    end

endmodule
