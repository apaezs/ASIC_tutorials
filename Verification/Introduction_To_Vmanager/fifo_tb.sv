// =============================================================
//  fifo_tb.sv  -  THE TESTBENCH AND TESTS
//
//  Pick a test when you run:  +TEST=basic
//    basic         write 4 values, read them back
//    fill_empty    fill to full, then empty it, twice
//                  (twice so both pointers wrap all the way around)
//    overflow      write when full, read when empty
//    random        random reads and writes
//
//  The scoreboard keeps its own copy of the FIFO and checks
//  every value that comes out. The test ends by printing
//  TEST PASSED or TEST FAILED.
// =============================================================
`timescale 1ns/1ps

module fifo_tb;

  // ---------- Signals ----------
  logic       clk = 0;
  logic       rst_n;
  logic       wr_en = 0;
  logic       rd_en = 0;
  logic [7:0] din = 0;
  logic [7:0] dout;
  logic       full, empty;
  logic [3:0] count;

  int errors = 0;

  // ---------- Clock: 10ns period ----------
  always #5 clk = ~clk;

  // ---------- The design ----------
  fifo dut (.*);

  // ---------- Checkers and coverage ----------
  // They also watch the design's internal pointers (dut.wptr, dut.rptr)
  fifo_assertions u_assert (.*, .wptr(dut.wptr), .rptr(dut.rptr));
  fifo_coverage   u_cov    (.*, .wptr(dut.wptr), .rptr(dut.rptr));

  // ---------- Scoreboard ----------
  // model = what SHOULD be inside the FIFO
  logic [7:0] model [$];

  always @(posedge clk) begin
    if (!rst_n) begin
      model.delete();
    end else begin
      // A read happens: check dout is the oldest value
      if (rd_en && !empty) begin
        if (dout !== model[0]) begin
          $error("SCOREBOARD: read %0h, expected %0h", dout, model[0]);
          errors++;
        end
        void'(model.pop_front());
      end
      // A write happens: remember the value
      if (wr_en && !full) begin
        model.push_back(din);
      end
    end
  end

  // ---------- Helper tasks ----------
  // Inputs change on the falling edge, the FIFO acts on the rising edge.

  task do_reset();
    rst_n = 0;
    repeat (2) @(negedge clk);
    rst_n = 1;
  endtask

  task write(input logic [7:0] data);
    @(negedge clk);
    wr_en = 1;  rd_en = 0;  din = data;
  endtask

  task read();
    @(negedge clk);
    wr_en = 0;  rd_en = 1;
  endtask

  task idle();
    @(negedge clk);
    wr_en = 0;  rd_en = 0;
  endtask

  task check(input logic condition, input string message);
    if (!condition) begin
      $error("CHECK FAILED: %s", message);
      errors++;
    end
  endtask

  // ---------- Test 1: basic ----------
  task test_basic();
    write(8'h11);
    write(8'h22);
    write(8'h33);
    write(8'h44);
    idle();
    check(count == 4, "count should be 4");
    repeat (4) read();
    idle();
    check(empty, "FIFO should be empty");
  endtask

  // ---------- Test 2: fill_empty ----------
  // Round 1: pointers go 0 -> 8   (wrap bit flips 0 -> 1)
  // Round 2: pointers go 8 -> 0   (wrap bit flips 1 -> 0)
  task test_fill_empty();
    repeat (2) begin
      for (int i = 0; i < 8; i++) write(i);
      idle();
      check(full, "FIFO should be full after 8 writes");
      repeat (8) read();
      idle();
      check(empty, "FIFO should be empty after 8 reads");
    end
  endtask

  // ---------- Test 3: overflow ----------
  task test_overflow();
    // read when empty (should be ignored)
    read();
    read();
    idle();
    check(empty, "read when empty should do nothing");

    // fill up, then write 3 more (should be ignored)
    for (int i = 0; i < 8; i++) write(8'hA0 + i);
    write(8'hFF);
    write(8'hFF);
    write(8'hFF);
    idle();
    check(count == 8, "write when full should do nothing");

    // read everything back (scoreboard checks no FF got in)
    repeat (8) read();
    idle();
    check(empty, "FIFO should be empty at the end");
  endtask

  // ---------- Test 4: random ----------
  task test_random();
    repeat (500) begin
      @(negedge clk);
      wr_en = $urandom_range(0, 1);
      rd_en = $urandom_range(0, 1);
      din   = $urandom;
    end
    // empty out whatever is left
    while (!empty) read();
    idle();
  endtask

  // ---------- Main: pick and run the test ----------
  string test_name;

  initial begin
    if (!$value$plusargs("TEST=%s", test_name))
      test_name = "basic";

    $display("===== Running test: %s =====", test_name);
    do_reset();

    case (test_name)
      "basic":      test_basic();
      "fill_empty": test_fill_empty();
      "overflow":   test_overflow();
      "random":     test_random();
      default: begin
        $error("Unknown test name: %s", test_name);
        errors++;
      end
    endcase

    repeat (3) idle();

    if (errors == 0) $display("TEST PASSED");
    else             $display("TEST FAILED with %0d errors", errors);
    $finish;
  end

endmodule