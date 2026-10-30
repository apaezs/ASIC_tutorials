// alu.sv - tiny ALU with a 1-cycle registered output
//
//   op = 0 : ADD  y = a + b   carry = carry out
//   op = 1 : SUB  y = a - b   carry = borrow (1 when a < b)
//   op = 2 : AND  y = a & b   carry = 0
//   op = 3 : OR   y = a | b   carry = 0
//
//   zero = 1 when y == 0
//   Result appears one clock after valid_in, with valid_out = 1.
//
// Compile with +define+BUG to plant a bug in SUB (for the debug demo).

module alu #(parameter int W = 8) (
  input  logic         clk,
  input  logic         rst_n,
  input  logic         valid_in,
  input  logic [1:0]   op,
  input  logic [W-1:0] a,
  input  logic [W-1:0] b,
  output logic         valid_out,
  output logic [W-1:0] y,
  output logic         carry,
  output logic         zero
);

  logic [W:0] res;  // one extra bit for carry / borrow

  always_comb begin
    case (op)
      2'd0:    res = {1'b0, a} + {1'b0, b};
`ifdef BUG
      2'd1:    res = {1'b0, b} - {1'b0, a};   // planted bug: operands swapped
`else
      2'd1:    res = {1'b0, a} - {1'b0, b};
`endif
      2'd2:    res = {1'b0, a & b};
      default: res = {1'b0, a | b};
    endcase
  end

  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      valid_out <= 1'b0;
      y         <= '0;
      carry     <= 1'b0;
      zero      <= 1'b0;
    end else begin
      valid_out <= valid_in;
      if (valid_in) begin
        y     <= res[W-1:0];
        carry <= res[W];
        zero  <= (res[W-1:0] == '0);
      end
    end
  end

endmodule
