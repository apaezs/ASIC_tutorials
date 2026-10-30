# Introduction to vManager: verifying a FIFO

[![Introduction to vManager (YouTube)](https://img.youtube.com/vi/Ld6wkxAsr5Y/maxresdefault.jpg)](https://www.youtube.com/watch?v=Ld6wkxAsr5Y)

▶ [Watch on YouTube](https://www.youtube.com/watch?v=Ld6wkxAsr5Y)

A small 8-entry FIFO, a testbench with 4 tests, assertions and coverage, run
first with Xcelium directly and then as a regression in Cadence Verisium Manager
(vManager), with the results tracked against a vPlan.

## Files

| File | What it is |
| --- | --- |
| `fifo.sv` | The design: 8 entries × 8 bits, `full` / `empty` from 4-bit pointers with a wrap bit |
| `fifo_tb.sv` | Testbench, scoreboard and the tests, picked with `+TEST=`: `basic`, `fill_empty`, `overflow`, `random` |
| `fifo_assertions.sv` | 8 assertions (flags, pointer moves, no write when full / read when empty) |
| `fifo_coverage.sv` | Covergroup: fill level, operations, their cross, wrap-bit flips, full in both wrap cases |
| `run.f` | File list for `xrun` |
| `fifo.vsif` | The regression for vManager: the 4 tests, `random` × 5 seeds |
| `test.vplan.vplanx` | The vPlan: Basic, Full and Empty, Pointers, Overflow, Code Coverage; each feature mapped to its coverpoints, assertions or tests |

## Run with Xcelium

```bash
source /apps/settings
xrun -F run.f -coverage all -covoverwrite +TEST=basic                   # one test: TEST PASSED / FAILED
xrun -F run.f -coverage all -covoverwrite +TEST=basic -gui -access +rwc  # with waveforms (SimVision)
```

All four, each with its own coverage, then merged and opened in IMC:

```bash
for t in basic fill_empty overflow random; do
  xrun -F run.f -coverage all -covoverwrite -covtest $t +TEST=$t
done
imc -execcmd "merge cov_work/scope/* -out merged -overwrite"
imc -load cov_work/scope/merged
```

## Run with vManager

vManager needs a server. Set up your own once with
[RTL_DV_DD_Tools/verisium_manager_server](https://github.com/UF-Silicon-Club-Design-Team/RTL_DV_DD_Tools/tree/main/verisium_manager_server);
`~/vmgr_server/connect.sh` then opens vManager on it.

```bash
cd Verification/Introduction_To_Vmanager
~/vmgr_server/connect.sh                 # GUI
```

1. **Regression:** Regression Center → Launch → `fifo.vsif`. 8 runs; results go in `regression/`.
2. **vPlan:** Planning Center → open `test.vplan.vplanx`.
3. **Analysis:** load the session; the vPlan shows coverage and assertion results per section.

Or launch the regression from the command line:

```bash
~/vmgr_server/connect.sh -execcmd "launch -wait fifo.vsif"
```

`regression/`, `vmgr_merge_logs/`, `cov_work/`, `xcelium.d/` and logs are run
outputs, kept out of git by `.gitignore`.
