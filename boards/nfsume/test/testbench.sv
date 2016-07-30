`timescale 1ps / 1ps
`define SIMULATION

module testbench #(
	parameter PL_LINK_CAP_MAX_LINK_WIDTH = 2,
	parameter C_DATA_WIDTH               = 64,
	parameter KEEP_WIDTH                 = C_DATA_WIDTH / 32
)(
	input wire clk100,
	input wire cold_reset,
	input wire SFP_CLK_P,

	output [7:0] LED
);

wire SFP_REC_CLK_P;
wire SFP_REC_CLK_N;
wire ETH1_RX_P;
wire ETH1_RX_N;
wire ETH1_TX_DISABLE;

/*
 *  Ethernet Top Instance
 */
localparam KEY_SIZE = 96;
wire [KEY_SIZE-1:0] in_key;
wire [3:0]          in_flag, out_flag;
wire                in_valid, out_valid;

wire db_clk;

eth_top eth0_top (
	.clk100             (clk100),
	.sys_rst            (sys_rst),
	.debug              (LED),
	
	/* KVS Interface */
	.db_clk           (db_clk),
	.in_key           (in_key   ),
	.in_flag          (in_flag  ),
	.in_valid         (in_valid ),
	.out_valid        (out_valid),
	.out_flag         (out_flag ),

	/* XGMII */
	.SFP_CLK_P          (SFP_CLK_P),
	.SFP_CLK_N          (1'b0),
	.SFP_REC_CLK_P      (SFP_REC_CLK_P),
	.SFP_REC_CLK_N      (SFP_REC_CLK_N),

	.ETH0_TX_P          (1'b0),
	.ETH0_TX_N          (1'b0),
	.ETH0_RX_P          (ETH0_RX_P),
	.ETH0_RX_N          (ETH0_RX_N),

	.I2C_FPGA_SCL       (1'b0),
	.I2C_FPGA_SDA       (1'b0),

	.SFP_CLK_ALARM_B    (1'b0),

	.ETH0_TX_FAULT      (1'b0),
	.ETH0_RX_LOS        (1'b0),
	.ETH0_TX_DISABLE    (ETH0_TX_DISABLE) 
);

db_top db_top0 (
	.clk              (db_clk),
	.rst              (sys_rst), 
	/* Network Interface */
	.in_key           (in_key   ),
	.in_flag          (in_flag  ),
	.in_valid         (in_valid ),
	.out_valid        (out_valid),
	.out_flag         (out_flag )

	/* DRAM interace */ 
	//input wire    dram_wr_strb,
	//input wire    dram_wr_data, 
);


endmodule
