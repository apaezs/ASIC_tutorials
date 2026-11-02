// arbiter_props.sv - formal properties for the arbiter
// Bound into the RTL at the bottom of this file, so arbiter.sv is not edited.

module arbiter_props #(parameter int N = 4) (
  input logic         clk,
  input logic         rst_n,
  input logic [N-1:0] req,
  input logic [N-1:0] gnt
);

  // ================= assumptions: what the requesters promise =================
  for (genvar i = 0; i < N; i++) begin : g_env
    // A requester keeps asking until it is served
    M_WAIT: assume property (@(posedge clk) disable iff (!rst_n)
      req[i] && !gnt[i] |=> req[i]);

    // A transfer lasts at most 2 cycles, then the requester lets go
    M_DONE: assume property (@(posedge clk) disable iff (!rst_n)
      gnt[i] ##1 gnt[i] |=> !req[i]);
  end

`ifdef OVERCONSTRAIN
  // Too strong: only one requester at a time. Everything still proves,
  // but C_ALL becomes unreachable. That is the warning sign.
  M_ONE: assume property (@(posedge clk) disable iff (!rst_n)
    $onehot0(req));
`endif

  // ================= assertions: the spec =================
  // 1. at most one grant at a time
  A_ONEHOT: assert property (@(posedge clk) disable iff (!rst_n)
    $onehot0(gnt));

  // 2. a grant only goes to a requester
  A_VALID: assert property (@(posedge clk) disable iff (!rst_n)
    (gnt & ~req) == '0);

  for (genvar i = 0; i < N; i++) begin : g_port
    // 3. a waiting requester is served within 6 cycles
    //    (3 other owners x 2 cycles each, worst case)
    A_FAIR: assert property (@(posedge clk) disable iff (!rst_n)
      req[i] && !gnt[i] |-> ##[1:6] gnt[i]);

    // 4. the grant holds while the requester keeps req high
    A_HOLD: assert property (@(posedge clk) disable iff (!rst_n)
      gnt[i] ##1 req[i] |-> gnt[i]);
  end

  // ================= covers: these must be reachable =================
  C_ALL:   cover property (@(posedge clk) disable iff (!rst_n)
    req == '1);                                   // all four ask at once
  C_HOLD:  cover property (@(posedge clk) disable iff (!rst_n)
    gnt[0] ##1 gnt[0]);                           // a 2-cycle transfer
  C_WORST: cover property (@(posedge clk) disable iff (!rst_n)
    req[3] && !gnt[3] ##1 !gnt[3] [*5] ##1 gnt[3]); // the full 6-cycle wait

endmodule

// Attach the properties to every arbiter instance
bind arbiter arbiter_props #(.N(N)) u_props (.*);
