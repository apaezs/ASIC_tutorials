`timescale 1ns/1ps
// =============================================================
//  fifo_assertions.sv  -  THE CHECKERS
//  Each assertion is a rule the FIFO must always follow.
//  If a rule breaks, the simulator prints an error and the
//  test fails. These names show up in vManager.
// =============================================================
module fifo_assertions (
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

  // Rule 1: the FIFO can never be full and empty at the same time
  a_not_full_and_empty: assert property (
    @(posedge clk) disable iff (!rst_n)
      !(full && empty)
  ) else $error("FIFO is full and empty at the same time");

  // Rule 2: empty means the pointers are exactly equal
  a_empty_flag: assert property (
    @(posedge clk) disable iff (!rst_n)
      empty == (wptr == rptr)
  ) else $error("empty flag is wrong: wptr=%0d rptr=%0d", wptr, rptr);

  // Rule 3: full means same slot, different wrap bit
  a_full_flag: assert property (
    @(posedge clk) disable iff (!rst_n)
      full == ((wptr[3] != rptr[3]) && (wptr[2:0] == rptr[2:0]))
  ) else $error("full flag is wrong: wptr=%0d rptr=%0d", wptr, rptr);

  // Rule 4: the write pointer is never more than 8 ahead
  a_count_max: assert property (
    @(posedge clk) disable iff (!rst_n)
      count <= 8
  ) else $error("count is %0d, more than 8", count);

  // Rule 5: a write moves the write pointer forward by 1
  a_wptr_moves: assert property (
    @(posedge clk) disable iff (!rst_n)
      (wr_en && !full) |=> (wptr == 4'($past(wptr) + 1))
  ) else $error("write pointer did not move after a write");

  // Rule 6: a read moves the read pointer forward by 1
  a_rptr_moves: assert property (
    @(posedge clk) disable iff (!rst_n)
      (rd_en && !empty) |=> (rptr == 4'($past(rptr) + 1))
  ) else $error("read pointer did not move after a read");

  // Rule 7: writing when full does not move the write pointer
  a_no_write_when_full: assert property (
    @(posedge clk) disable iff (!rst_n)
      (wr_en && full) |=> $stable(wptr)
  ) else $error("write when full moved the write pointer");

  // Rule 8: reading when empty does not move the read pointer
  a_no_read_when_empty: assert property (
    @(posedge clk) disable iff (!rst_n)
      (rd_en && empty) |=> $stable(rptr)
  ) else $error("read when empty moved the read pointer");

endmodule