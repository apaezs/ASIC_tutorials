`timescale 1ns/1ps
// =============================================================
//  fifo.sv  -  THE DESIGN
//  A simple 8-entry FIFO. Each entry is 8 bits.
//
//  write: set wr_en=1 and put data on din
//  read : set rd_en=1, the data is on dout (dout always shows
//         the oldest entry, so read it in the same cycle)
//  Writes when full are ignored. Reads when empty are ignored.
//
//  HOW FULL / EMPTY WORK (no counter needed)
//  The FIFO has 8 slots, so a slot address needs 3 bits.
//  The pointers are 4 bits: the low 3 bits pick the slot, and
//  the extra top bit (the "wrap bit") flips every time a
//  pointer goes all the way around.
//
//    empty : pointers are exactly equal
//            (same slot, same lap)
//    full  : same slot, but the wrap bits are different
//            (the write pointer is one full lap ahead)
// =============================================================
module fifo (
  input  logic       clk,
  input  logic       rst_n,    // reset, active low
  input  logic       wr_en,
  input  logic [7:0] din,
  input  logic       rd_en,
  output logic [7:0] dout,
  output logic       full,
  output logic       empty,
  output logic [3:0] count     // entries stored (0 to 8), = wptr - rptr
);

  logic [7:0] mem [0:7];       // the 8 storage slots
  logic [3:0] wptr;            // [3] = wrap bit, [2:0] = slot to write
  logic [3:0] rptr;            // [3] = wrap bit, [2:0] = slot to read

  logic do_write, do_read;
  assign do_write = wr_en && !full;
  assign do_read  = rd_en && !empty;

  // Full and empty come straight from the pointers
  assign empty = (wptr == rptr);
  assign full  = (wptr[3] != rptr[3]) && (wptr[2:0] == rptr[2:0]);

  // How many entries are stored (just a subtraction, no register)
  assign count = wptr - rptr;

  // The oldest entry is always on dout
  assign dout = mem[rptr[2:0]];

  // Store the data
  always_ff @(posedge clk) begin
    if (do_write) mem[wptr[2:0]] <= din;
  end

  // Move the pointers. Going past 15 rolls back to 0, which
  // flips the wrap bit automatically.
  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      wptr <= 0;
      rptr <= 0;
    end else begin
      if (do_write) wptr <= wptr + 1;
      if (do_read)  rptr <= rptr + 1;
    end
  end

endmodule