# probe.tcl - dump every signal in the testbench to waves.shm, then run to the end
database -open waves -shm -default
probe -create tb -all -depth all
run
exit
