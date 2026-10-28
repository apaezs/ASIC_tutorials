`timescale 1ns/1ps
// =============================================================
//  fifo_coverage.sv  -  THE COVERAGE
//  Coverage answers: "did my tests actually try this?"
//  Each bin below must be hit at least once to reach 100%.
//  These names show up in vManager and you link them to
//  the vPlan.
// =============================================================
module fifo_coverage (
  input logic       clk,
  input logic       rst_n,
  input logic       wr_en,
  input logic       rd_en,
  input logic       full,
  input logic       empty,
  input logic [3:0] count,
  input logic [3:0] wptr,      // the design's internal pointers
  input logic [3:0] rptr
);

  covergroup cg @(posedge clk iff rst_n);

    // How full was the FIFO?
    cp_count: coverpoint count {
      bins empty  = {0};
      bins partly = {[1:7]};
      bins full   = {8};
    }

    // What was the test doing this cycle?
    cp_ops: coverpoint {wr_en, rd_en} {
      bins idle       = {2'b00};
      bins read_only  = {2'b01};
      bins write_only = {2'b10};
      bins both       = {2'b11};
    }

    // Every operation at every fill level (4 x 3 = 12 bins)
    cx_ops_count: cross cp_ops, cp_count;

    // Did we try writing when full?
    cp_write_when_full: coverpoint (wr_en && full) {
      bins yes = {1};
    }

    // Did we try reading when empty?
    cp_read_when_empty: coverpoint (rd_en && empty) {
      bins yes = {1};
    }

    // Did each pointer's wrap bit flip both ways?
    // (0 -> 1 after 8 moves, 1 -> 0 after 16 moves)
    cp_wptr_wrap: coverpoint wptr[3] {
      bins first_lap  = (0 => 1);
      bins second_lap = (1 => 0);
    }
    cp_rptr_wrap: coverpoint rptr[3] {
      bins first_lap  = (0 => 1);
      bins second_lap = (1 => 0);
    }

    // Was the FIFO full in BOTH wrap-bit cases?
    //   wptr wrap=1, rptr wrap=0  (writer on lap 2, reader on lap 1)
    //   wptr wrap=0, rptr wrap=1  (writer rolled past 15 back to 0)
    cp_full_wrap_bits: coverpoint {wptr[3], rptr[3]} iff (full) {
      bins writer_ahead  = {2'b10};
      bins writer_rolled = {2'b01};
    }

  endgroup

  cg cov = new();

endmodule