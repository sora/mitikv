sim_top = testbench

VERILATOR_SRC := sim_main.cpp

SIM_SRC := testbench.sv
RTL_SRC := utils_pkg.sv                        \
           endian_pkg.sv                       \
           ../../../cores/db/rtl/db_cont.v     \
           ../../../cores/db/rtl/crc32.v       \
           ../../../cores/db/rtl/db_top.v      \
           axis_data_fifo_0.sv                 \
           axi_10g_ethernet_0.sv               \
           sfp_refclk_init.sv                  \
           ../rtl/pcs_pma_conf.v               \
           ../rtl/eth_mac_conf.v               \
           ../rtl/eth_encap.v                  \
           ../rtl/eth_top.v

#WFLAGS = -Wall -Wno-PINCONNECTEMPTY -Wno-UNUSED -Wno-UNDRIVEN --report-unoptflat
WFLAGS = -Wall -Wno-PINCONNECTEMPTY -Wno-UNUSED -Wno-UNDRIVEN

all: sim

lint: $(SIM_SRC) $(RTL_SRC)
	verilator $(WFLAGS) -Wall --lint-only --cc --top-module $(sim_top) -sv $(SIM_SRC) $(RTL_SRC)

sim: $(VERILATOR_SRC) $(SIM_SRC) $(RTL_SRC)
	verilator $(WFLAGS) -DSIMULATION --cc --trace --top-module $(sim_top) -sv $(SIM_SRC) $(RTL_SRC) --exe $(VERILATOR_SRC)
	make -j -C obj_dir/ -f V$(sim_top).mk V$(sim_top)

run: sim obj_dir/V$(sim_top)
	obj_dir/V$(sim_top)

.PHONY: clean
clean:
	rm -f wave.vcd
	rm -rf obj_dir

