#SRC = tb_dram_phy.v ../rtl/dram_phy.v
SRC = tb_db_cont.v ../rtl/db_cont.v

tb : 
	iverilog -o tb_system ${SRC} -DSIMULATION
sim : tb_system
	vvp tb_system
wave: dump.vcd
	gtkwave dump.vcd
clean :
	rm -f tb *.vcd 
