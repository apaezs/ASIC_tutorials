// tb.sv - testbench for the ALU
//
//   +TEST=basic   a few hand-picked cases (default)
//   +TEST=random  N random cases, N set with +N=<count> (default 200)
//
// Checks results two ways: a scoreboard (reference model) and the SVA in alu_sva.sv.
// Collects functional coverage with two covergroups.

module tb;

  localparam int W = 8;
  localparam logic [1:0] ADD = 2'd0, SUB = 2'd1, AND_ = 2'd2, OR_ = 2'd3;

  // ---------- signals ----------
  logic         clk      = 1'b0;
  logic         rst_n    = 1'b0;
  logic         valid_in = 1'b0;
  logic [1:0]   op       = '0;
  logic [W-1:0] a        = '0;
  logic [W-1:0] b        = '0;
  logic         valid_out;
  logic [W-1:0] y;
  logic         carry;
  logic         zero;

  always #5 clk = ~clk;   // 10 ns clock

  // ---------- DUT and checker ----------
  alu     #(.W(W)) dut (.*);
  alu_sva #(.W(W)) sva (.*);

  // ---------- reference model ----------
  function automatic logic [W:0] model(logic [1:0] o, logic [W-1:0] x, logic [W-1:0] z);
    case (o)
      ADD:     return {1'b0, x} + {1'b0, z};
      SUB:     return {1'b0, x} - {1'b0, z};
      AND_:    return {1'b0, x & z};
      default: return {1'b0, x | z};
    endcase
  endfunction

  // ---------- scoreboard ----------
  logic [W:0] exp_q[$];   // expected {carry, y}, oldest first
  int         errors  = 0;
  int         checked = 0;

  always @(posedge clk) begin
    if (rst_n) begin
      if (valid_out) begin
        logic [W:0] exp;
        exp = exp_q.pop_front();
        checked++;
        if ({carry, y} !== exp) begin
          errors++;
          $display("ERROR @%0t: got carry=%0b y=%0h, expected carry=%0b y=%0h",
                   $time, carry, y, exp[W], exp[W-1:0]);
        end
      end
      if (valid_in) exp_q.push_back(model(op, a, b));
    end
  end

  // ---------- functional coverage ----------
  covergroup cg_in @(posedge clk iff (rst_n && valid_in));
    cp_op: coverpoint op {
      bins add  = {ADD};
      bins sub  = {SUB};
      bins and_ = {AND_};
      bins or_  = {OR_};
    }
    cp_a: coverpoint a {
      bins zero  = {0};
      bins max   = {(2**W)-1};
      bins other = {[1:(2**W)-2]};
    }
    cp_b: coverpoint b {
      bins zero  = {0};
      bins max   = {(2**W)-1};
      bins other = {[1:(2**W)-2]};
    }
    op_x_a: cross cp_op, cp_a;
    op_x_b: cross cp_op, cp_b;
  endgroup

  covergroup cg_out @(posedge clk iff (rst_n && valid_out));
    cp_carry: coverpoint carry;
    cp_zero:  coverpoint zero;
  endgroup

  cg_in  cgi = new();
  cg_out cgo = new();

  // ---------- stimulus helpers ----------
  // Inputs change on the falling edge, so they are stable at every rising edge.
  task automatic send(logic [1:0] o, logic [W-1:0] x, logic [W-1:0] z);
    @(negedge clk);
    valid_in <= 1'b1;
    op       <= o;
    a        <= x;
    b        <= z;
  endtask

  task automatic idle(int cycles);
    repeat (cycles) begin
      @(negedge clk);
      valid_in <= 1'b0;
    end
  endtask

  // 10% zero, 10% all-ones, 80% anything: hits the corner bins quickly
  function automatic logic [W-1:0] rand_val();
    int r;
    r = $urandom_range(0, 9);
    if (r == 0) return '0;
    if (r == 1) return '1;
    return W'($urandom());
  endfunction

  // ---------- test sequence ----------
  initial begin
    string test;
    int    n;

    if (!$value$plusargs("TEST=%s", test)) test = "basic";
    if (!$value$plusargs("N=%d", n))       n    = 200;
    $display("Running test: %s", test);

    repeat (3) @(posedge clk);
    rst_n <= 1'b1;
    @(posedge clk);

    case (test)
      "basic": begin
        send(ADD,  8'd3,   8'd4);    // 7
        send(ADD,  8'hFF,  8'h01);   // 0, carry=1, zero=1
        send(SUB,  8'd9,   8'd4);    // 5
        send(SUB,  8'd5,   8'd5);    // 0, zero=1
        send(SUB,  8'd3,   8'd5);    // borrow: carry=1
        send(AND_, 8'hF0,  8'h3C);   // 30
        send(OR_,  8'hF0,  8'h0F);   // FF
      end
      "random": begin
        repeat (n) send(2'($urandom_range(0, 3)), rand_val(), rand_val());
      end
      default: $fatal(1, "Unknown test: %s", test);
    endcase

    idle(3);

    $display("Checked %0d results", checked);
    if (errors == 0) $display("TEST PASSED  errors=0");
    else             $display("TEST FAILED  errors=%0d", errors);
    $finish;
  end

endmodule
