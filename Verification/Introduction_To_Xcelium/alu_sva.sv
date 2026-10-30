// alu_sva.sv - assertions and cover properties for the ALU
// Instantiated in tb as "sva", so names show up as tb.sva.a_sub etc.

module alu_sva #(parameter int W = 8) (
  input logic         clk,
  input logic         rst_n,
  input logic         valid_in,
  input logic [1:0]   op,
  input logic [W-1:0] a,
  input logic [W-1:0] b,
  input logic         valid_out,
  input logic [W-1:0] y,
  input logic         carry,
  input logic         zero
);

  // Every property below is checked on the rising clock edge and
  // switched off while reset is low.
  default clocking cb @(posedge clk); endclocking

  // ---------- assertions: these must always hold ----------

  // Every input produces an output exactly one cycle later
  a_valid_latency: assert property (disable iff (!rst_n)
           valid_in |=> valid_out);

  // No output without an input the cycle before
  a_no_spurious:   assert property (disable iff (!rst_n)
           !valid_in |=> !valid_out);

  // zero flag always matches the result
  a_zero_flag:     assert property (disable iff (!rst_n)
           valid_out |-> (zero == (y == '0)));

  // Each operation gives the right answer one cycle later
  a_add: assert property (disable iff (!rst_n)
           valid_in && op == 2'd0 |=>
           {carry, y} == ({1'b0, $past(a)} + {1'b0, $past(b)}));

  a_sub: assert property (disable iff (!rst_n)
           valid_in && op == 2'd1 |=>
           {carry, y} == ({1'b0, $past(a)} - {1'b0, $past(b)}));

  a_and: assert property (disable iff (!rst_n)
           valid_in && op == 2'd2 |=>
           y == ($past(a) & $past(b)) && !carry);

  a_or:  assert property (disable iff (!rst_n)
           valid_in && op == 2'd3 |=>
           y == ($past(a) | $past(b)) && !carry);

  // Outputs are never X/Z when valid
  a_no_x: assert property (disable iff (!rst_n)
           valid_out |-> !$isunknown({y, carry, zero}));

  // ---------- cover properties: did we ever see this happen? ----------

  c_add_carry:  cover property (valid_in && op == 2'd0 ##1 carry);
  c_sub_borrow: cover property (valid_in && op == 2'd1 ##1 carry);
  c_zero:       cover property (valid_out && zero);
  c_back2back:  cover property (valid_in ##1 valid_in ##1 valid_in);

endmodule
