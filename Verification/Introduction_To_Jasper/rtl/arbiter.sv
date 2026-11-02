// arbiter.sv - 4-way round-robin arbiter
//
//   req[i] = 1 : requester i wants the bus
//   gnt[i] = 1 : requester i owns the bus this cycle (at most one bit set)
//
// Rules:
//   - The current owner keeps the grant for as long as it keeps req high.
//   - When the owner lets go, the grant moves to the next requester in
//     round-robin order, starting after the last owner (0 -> 1 -> 2 -> 3 -> 0).
//
// Compile with +define+BUG to plant a bug: the search always starts at
// requester 0 (fixed priority), so requesters 2 and 3 can starve.

module arbiter #(parameter int N = 4) (
  input  logic         clk,
  input  logic         rst_n,
  input  logic [N-1:0] req,
  output logic [N-1:0] gnt
);

  localparam int W = $clog2(N);

  logic [N-1:0] owner_q;  // who had the grant last cycle
  logic [W-1:0] last_q;   // last requester that got a grant

  // ---------- next grant (combinational) ----------
  always_comb begin
    logic [W-1:0] idx;
    idx = '0;
    gnt = '0;
    if ((owner_q & req) != '0) begin
      gnt = owner_q;                         // owner still asking: hold
    end else begin
      for (int k = 1; k <= N; k++) begin
`ifdef BUG
        idx = W'(k - 1);                     // BUG: always start at 0
`else
        idx = W'((int'(last_q) + k) % N);    // start after the last owner
`endif
        if (gnt == '0 && req[idx]) gnt[idx] = 1'b1;
      end
    end
  end

  // ---------- state ----------
  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      owner_q <= '0;
      last_q  <= W'(N - 1);                  // so requester 0 goes first
    end else begin
      owner_q <= gnt;
      for (int i = 0; i < N; i++)
        if (gnt[i]) last_q <= W'(i);
    end
  end

endmodule
