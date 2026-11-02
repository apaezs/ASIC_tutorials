# jg.tcl - Jasper FPV setup for the arbiter
#   GUI:   jg jg.tcl
#   batch: jg -batch jg.tcl -command exit
# Variants: jg_bug.tcl (planted bug), jg_over.tcl (over-constrained)

clear -all

if {![info exists DEFINES]} { set DEFINES "" }

# 1. read in the RTL and the property files
analyze -sv {*}$DEFINES rtl/arbiter.sv
analyze -sv {*}$DEFINES props/arbiter_props.sv

# 2. pick the top module
elaborate -top arbiter

# 3. declare the clock and reset
clock clk
reset -expr {!rst_n}

# 4. run the proofs (asserts and covers)
prove -all

# 5. summary in the console
report
