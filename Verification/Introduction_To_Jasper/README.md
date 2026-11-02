# Formal verification demo: 4-way arbiter in Jasper

This kit goes with the arbiter example in "12 - Formal Verification". You prove the arbiter's spec with Cadence Jasper (FPV), find a planted fairness bug from a short counterexample, and see what over-constraining looks like.

| File | What it is |
|---|---|
| `rtl/arbiter.sv` | The design: 4-way round-robin arbiter. The owner keeps the grant while it holds `req`. `+define+BUG` makes it fixed-priority. |
| `props/arbiter_props.sv` | 2 assumptions per port, 10 assertions, 3 covers. Bound into the RTL with `bind`, so the RTL isn't edited. |
| `jg.tcl` | The Jasper run: analyze, elaborate, clock, reset, prove, report. |
| `jg_bug.tcl` | Same run with `+define+BUG`. |
| `jg_over.tcl` | Same run with `+define+OVERCONSTRAIN`, which adds one assumption that is too strong. |

## The properties

| Name | Kind | Meaning |
|---|---|---|
| `g_env[i].M_WAIT` | assume | A requester keeps `req` high until it is granted. |
| `g_env[i].M_DONE` | assume | A transfer lasts at most 2 cycles, then the requester drops `req`. |
| `A_ONEHOT` | assert | At most one grant at a time. |
| `A_VALID` | assert | A grant only goes to a requester. |
| `g_port[i].A_FAIR` | assert | A waiting requester is granted within 6 cycles (3 other owners x 2 cycles). |
| `g_port[i].A_HOLD` | assert | The grant holds while the requester keeps `req` high. |
| `C_ALL` | cover | All 4 request at once. |
| `C_HOLD` | cover | A 2-cycle transfer happens. |
| `C_WORST` | cover | Requester 3 waits the full 6 cycles. This shows the bound of 6 is tight. |

## Setup

```bash
cd <this folder>
source /apps/settings      # loads the Cadence tools; check that `which jg` finds Jasper
```

## Run it

```bash
jg jg.tcl                              # GUI: runs the script, then leaves the window open
jg -batch jg.tcl -command exit         # batch: prints the report and exits
```

| Run | Command | Expected result |
|---|---|---|
| Clean | `jg jg.tcl` | All 10 assertions **proven**. All 3 covers **covered**. |
| Planted bug | `jg jg_bug.tcl` | `g_port[2].A_FAIR` and `g_port[3].A_FAIR` show a **CEX**, about 8 cycles long. The other 8 assertions are proven and the covers are covered. |
| Over-constrained | `jg jg_over.tcl` | All 10 assertions are **proven**, but `C_ALL` and `C_WORST` are **unreachable**. The green results are not trustworthy. |

## Debug the bug in the GUI

1. Run `jg jg_bug.tcl`. In the **Property Table**, the two `A_FAIR` rows for ports 2 and 3 are red (CEX).
2. Double-click `g_port[3].A_FAIR`, or right-click it and choose **Visualize**. The counterexample waveform opens.
3. Read the trace: `req[3]` goes high and stays high. Meanwhile `gnt` keeps going to 0, 1 and 2, and never to 3. Requester 3 starves.
4. Open `rtl/arbiter.sv` and find the `ifdef BUG` line. The search always starts at index 0 instead of after the last owner.
5. Close Jasper and run `jg jg.tcl` again. Everything is proven.

To see a cover trace, double-click a covered row such as `C_WORST`. It shows requester 3 waiting exactly 6 cycles.

## Clean up

```bash
rm -rf jgproject
```

> These files were checked with an open-source formal flow (SymbiYosys), using equivalent checks for the same properties: the clean design proves, the bug fails only `A_FAIR` for ports 2 and 3 in about 8 cycles, and the over-constrained run proves everything with `C_ALL` and `C_WORST` unreachable. I couldn't run Jasper itself. GUI menu names, property naming such as `arbiter.u_props.g_port[3].A_FAIR`, and report formatting may differ by version, so do one dry run first.
