# SPDX-FileCopyrightText: © 2026 Tiny Tapeout
# SPDX-License-Identifier: Apache-2.0

import cocotb
from cocotb.clock import Clock
from cocotb.triggers import ClockCycles, FallingEdge

@cocotb.test()
async def test_axis_fifo(dut):
    dut._log.info("Start AXI4-Stream FWFT FIFO Test")

    # 1. SETUP CLOCK & INITIAL STATE
    # Clock 50 MHz (20 ns period) - Diperbaiki: 'units' jadi 'unit' untuk menghilangkan warning
    clock = Clock(dut.clk, 20, unit="ns")
    cocotb.start_soon(clock.start())

    # Enable pin always high for Tiny Tapeout
    dut.ena.value = 1
    dut.ui_in.value = 0      # s_axis_tdata = 0
    dut.uio_in.value = 0     # all input control signals = 0

    # 2. RESET SEQUENCE
    dut._log.info("Resetting DUT...")
    dut.rst_n.value = 0
    await ClockCycles(dut.clk, 5)
    dut.rst_n.value = 1
    await ClockCycles(dut.clk, 2)

    # Helper function untuk baca pin uio_out (Diperbaiki: menggunakan int() untuk menghilangkan warning)
    def get_uio_out_bit(bit_index):
        val = int(dut.uio_out.value)
        return (val >> bit_index) & 1

    # 3. TEST 1: FWFT BEHAVIOR (First-Word Fall-Through)
    dut._log.info("TEST 1: FWFT Behavior")
    # Tulis 1 data (misal: 0xAA)
    dut.ui_in.value = 0xAA           # s_axis_tdata
    dut.uio_in.value = 1             # s_axis_tvalid = 1 (bit 0)
    
    await ClockCycles(dut.clk, 1)    # Tunggu 1 clock supaya data masuk
    dut.uio_in.value = 0             # s_axis_tvalid = 0 (berhenti nulis)
    await ClockCycles(dut.clk, 1)

    # --- TUNGGU GATE DELAY STABIL (PENTING UNTUK GL_TEST) ---
    await FallingEdge(dut.clk)

    # Karena ini FWFT, data 0xAA harusnya LANGSUNG ada di output (uo_out) 
    # dan m_axis_tvalid (uio_out bit 3) harusnya HIGH.
    assert dut.uo_out.value == 0xAA, f"FWFT Failed! Expected 0xAA, got {dut.uo_out.value}"
    assert get_uio_out_bit(3) == 1, "m_axis_tvalid should be HIGH!"
    assert get_uio_out_bit(5) == 0, "fifo_empty should be LOW!"
    dut._log.info("FWFT Behavior Verified! Data passed through immediately.")

    # 4. TEST 2: FILL FIFO TO FULL
    dut._log.info("TEST 2: Fill FIFO to FULL")
    # Kita udah isi 1, berarti sisa 15 slot lagi (karena depth = 16)
    dut.uio_in.value = 1             # s_axis_tvalid = 1
    for i in range(1, 16):
        dut.ui_in.value = i          # Masukin data 1, 2, 3, ... 15
        await ClockCycles(dut.clk, 1)
    
    dut.uio_in.value = 0             # Stop nulis
    await ClockCycles(dut.clk, 1)

    # --- TUNGGU GATE DELAY STABIL ---
    await FallingEdge(dut.clk)

    # Cek apakah flag FULL nyala (uio_out bit 4) dan s_tready mati (uio_out bit 1)
    assert get_uio_out_bit(4) == 1, "fifo_full flag should be HIGH!"
    assert get_uio_out_bit(1) == 0, "s_axis_tready should be LOW when full!"
    dut._log.info("FIFO successfully filled and FULL flag asserted.")

    # 5. TEST 3: READ ALL DATA UNTIL EMPTY
    dut._log.info("TEST 3: Read all data until EMPTY")
    # Set m_axis_tready = 1 (bit 2 di uio_in)
    dut.uio_in.value = 4             # Binary: 0000_0100 -> bit 2 HIGH
    
    # Baca 16 data
    for i in range(16):
        await ClockCycles(dut.clk, 1)
    
    dut.uio_in.value = 0             # Stop baca
    await ClockCycles(dut.clk, 1)

    # --- TUNGGU GATE DELAY STABIL ---
    await FallingEdge(dut.clk)

    # Cek apakah flag EMPTY nyala (uio_out bit 5)
    assert get_uio_out_bit(5) == 1, "fifo_empty flag should be HIGH!"
    assert get_uio_out_bit(3) == 0, "m_axis_tvalid should be LOW when empty!"
    dut._log.info("FIFO successfully emptied and EMPTY flag asserted.")
    
    dut._log.info("ALL TESTS PASSED! YOU ARE READY TO TAPE OUT!")