# Introduction to Xcelium

[![Introduction to Xcelium (YouTube)](https://img.youtube.com/vi/qam4H59jc-c/maxresdefault.jpg)](https://youtu.be/qam4H59jc-c)

▶ [Watch the tutorial](https://youtu.be/qam4H59jc-c)

A first, hands-on look at running a simulation with Cadence Xcelium, with no prior
Cadence experience assumed. You run an 8-bit ALU's tests from the command line,
replay a random seed, and track down a planted bug with waveforms in SimVision
and at the Tcl prompt.

Verified with Xcelium 24.09.

## Files

| File | What it is |
| --- | --- |
| `alu.sv` | Design under test: 8-bit ALU, result registered one clock after the inputs (with `valid_out`). `op`: 0 = ADD, 1 = SUB, 2 = AND, 3 = OR. `carry` is carry out (ADD) or borrow (SUB); `zero` is 1 when `y == 0`. `+define+BUG` makes SUB compute `b - a`. |
| `alu_sva.sv` | Assertions, instantiated as `tb.sva`: `a_add`, `a_sub`, `a_and`, `a_or`, `a_zero_flag`, `a_valid_latency`, `a_no_spurious`, `a_no_x`, plus 4 cover properties |
| `tb.sv` | Testbench: 10 ns clock, scoreboard against a reference model. `+TEST=basic` (default, 7 hand-picked cases) or `+TEST=random` (200 cases, change with `+N=`) |
| `run.f` | File list for `xrun`: `-sv`, `-timescale 1ns/1ps`, `-access +rwc`, `-top tb` and the 3 `.sv` files |
| `probe.tcl` | Records every signal to `waves.shm` and runs to the end |

Simulation outputs are kept out of git by the repo's top-level `.gitignore`.

## Setup

On a Linux machine with the Cadence tools installed:

```bash
git clone https://github.com/apaezs/ASIC_tutorials.git
cd ASIC_tutorials/Verification/Introduction_To_Xcelium
source /apps/settings     # loads xrun and simvision; run in every new terminal
```

DLCPTH warnings at start-up come from the install and are harmless; add `-nowarn DLCPTH` to hide them.

## Run the tests

```bash
xrun -f run.f +TEST=basic
```
expect: `Checked 7 results`, `TEST PASSED  errors=0`; the simulation ends at 130 ns.

```bash
xrun -f run.f +TEST=random -svseed random
```
expect: `SVSEED set randomly from command line: <seed>`, `Checked 200 results`, `TEST PASSED`.

```bash
xrun -f run.f +TEST=random -svseed <seed>
```
expect: the exact same run again, so any random failure can be reproduced.

## Debug the planted bug

```bash
xrun -f run.f +TEST=basic +define+BUG
```
expect these 4 lines, then `TEST FAILED  errors=2`:

```
ERROR @75000: got carry=1 y=fb, expected carry=0 y=5
xmsim: *E,ASRTST (./alu_sva.sv,40): (time 75 NS) Assertion tb.sva.a_sub has failed (2 cycles, starting 65 NS)
ERROR @95000: got carry=0 y=2, expected carry=1 y=fe
xmsim: *E,ASRTST (./alu_sva.sv,40): (time 95 NS) Assertion tb.sva.a_sub has failed (2 cycles, starting 85 NS)
```

The scoreboard and `a_sub` catch the bug independently (75000 ps and 75 NS are the
same instant). Only 2 of the 3 SUBs fail: `5 - 5` gives the same answer with the
operands swapped, which is why random tests matter.

### In SimVision

```bash
xrun -f run.f +TEST=basic +define+BUG -gui
```
expect: SimVision opens with the simulation paused at time 0.

1. Design Browser: expand `tb` → `dut`, select `clk valid_in op a b valid_out y carry`, click **Send to Waveform** (optionally add `tb.sva`). Click **Run**.
2. At the 65 ns edge: `op = 1` (SUB), `a = 09`, `b = 04`. Right after, `y = fb`, `carry = 1`, but 9 − 4 should be `05` with no borrow: the ALU computed `b - a`. The checks report it at 75 ns because they sample on the next edge.
3. **Windows → Tools → Assertion Browser**: `a_sub` shows 2 failures.
4. Send `y` to the Source Browser: the SUB line under `` `ifdef BUG `` has its operands swapped.

### At the Tcl prompt

```bash
xrun -f run.f +TEST=basic +define+BUG -tcl
```
expect: an `xcelium>` prompt.

```
xcelium> run 66ns                 (stops just after the 65 ns edge)
xcelium> value tb.op tb.a tb.b    -> 2'h1 8'h09 8'h04
xcelium> value tb.y tb.carry      -> 8'hfb 1'h1
xcelium> run                      (to the end; errors print)
```

### Record waves in batch, view later

```bash
xrun -f run.f +TEST=basic +define+BUG -input probe.tcl
simvision waves.shm
```
expect: the same 4 errors, then SimVision opens the recorded `waves.shm`.

## Clean up

```bash
rm -rf xcelium.d waves.shm *.log *.history *.key .simvision
```
expect: the folder is back to the source files.

## Quick reference

| Flag | Meaning |
| --- | --- |
| `-f <file>` | Read options and files from a file list |
| `-sv` | Compile as SystemVerilog |
| `-top <name>` | Top-level module |
| `-timescale 1ns/1ps` | Default time unit / precision |
| `-access +rwc` | Read/write/connectivity access for debug (waves, Tcl) |
| `-clean` | Rebuild from scratch |
| `+define+NAME` | Define a macro (e.g. `+define+BUG`) |
| `+TEST=<name>` | Pick the test (`basic`, `random`) |
| `-svseed random\|<n>` | Random seed: pick one, or replay one |
| `-gui` | Open SimVision |
| `-tcl` | Stop at the Tcl prompt |
| `-input <file>` | Run Tcl commands from a file |
| `-nowarn DLCPTH` | Hide the DLCPTH start-up warnings |

Look up an error code: `xmhelp xmsim ASRTST`. Look up a flag: `xrun -helpall`.

## Next steps

Next: [Introduction to vManager](../Introduction_To_Vmanager) ([video](https://www.youtube.com/watch?v=Ld6wkxAsr5Y)), which runs these kinds of tests as an automated regression.
