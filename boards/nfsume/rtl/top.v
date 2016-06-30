`timescale 1ps / 1ps

module top #(
	parameter PL_LINK_CAP_MAX_LINK_WIDTH = 2,
	parameter C_DATA_WIDTH               = 64,
	parameter KEEP_WIDTH                 = C_DATA_WIDTH / 32
)(
	input  wire FPGA_SYSCLK_P,
	input  wire FPGA_SYSCLK_N,
	inout  wire I2C_FPGA_SCL,
	inout  wire I2C_FPGA_SDA,
	output wire [7:0] LED,

	// Ethernet
	input  wire SFP_CLK_P,
	input  wire SFP_CLK_N,
	output wire SFP_REC_CLK_P,
	output wire SFP_REC_CLK_N,
	input  wire SFP_CLK_ALARM_B,

	// Ethernet (ETH1)
	input  wire ETH1_TX_P,
	input  wire ETH1_TX_N,
	output wire ETH1_RX_P,
	output wire ETH1_RX_N,
	input  wire ETH1_TX_FAULT,
	input  wire ETH1_RX_LOS,
	output wire ETH1_TX_DISABLE
);

assign LED = 8'd0;

/*
 *  Core Clocking 
 */
wire clk200;
IBUFDS IBUFDS_clk200 (
	.I   (FPGA_SYSCLK_P),
	.IB  (FPGA_SYSCLK_N),
	.O   (clk200)
);

wire clk100;
reg clock_divide = 1'b0;
always @(posedge clk200)
	clock_divide <= ~clock_divide;

BUFG buffer_clk100 (
	.I  (clock_divide),
	.O  (clk100)
);

/*
 *  Core Reset 
 *  ***FPGA specified logic
 */
reg [13:0] cold_counter = 14'd0;
wire       sys_rst   = cold_counter != 14'h3fff;
always @(posedge clk200) 
	if (cold_counter != 14'h3fff) 
		cold_counter <= cold_counter + 14'd1;

/*
 *  Ethernet Top Instance
 */

eth_top eth0_top (
	.clk100             (clk100),
	.sys_rst            (sys_rst),

	.SFP_CLK_P          (SFP_CLK_P),
	.SFP_CLK_N          (SFP_CLK_N),
	.SFP_REC_CLK_P      (SFP_REC_CLK_P),
	.SFP_REC_CLK_N      (SFP_REC_CLK_N),

	.ETH1_TX_P          (ETH1_TX_P),
	.ETH1_TX_N          (ETH1_TX_N),
	.ETH1_RX_P          (ETH1_RX_P),
	.ETH1_RX_N          (ETH1_RX_N),

	.I2C_FPGA_SCL       (I2C_FPGA_SCL),
	.I2C_FPGA_SDA       (I2C_FPGA_SDA),

	.SFP_CLK_ALARM_B    (SFP_CLK_ALARM_B),

	.ETH1_TX_FAULT      (ETH1_TX_FAULT ),
	.ETH1_RX_LOS        (ETH1_RX_LOS   ),
	.ETH1_TX_DISABLE    (ETH1_TX_DISABLE) 
);

endmodule

