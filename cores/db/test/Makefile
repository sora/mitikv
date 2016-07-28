SRC = tb_dram_phy.v ../rtl/dram_phy.v

tb : 
	iverilog -o tb_system ${SRC}
sim : tb_system
	vvp tb_system
wave: dump.vcd
	gtkwave dump.vcd
clean :
	rm -f tb *.vcd 
