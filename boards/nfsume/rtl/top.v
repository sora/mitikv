`timescale 1ps / 1ps

//`define SIMULATION_ILA

module top (
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

	// Ethernet (ETH0)
	input  wire ETH0_TX_P,
	input  wire ETH0_TX_N,
	output wire ETH0_RX_P,
	output wire ETH0_RX_N,
	input  wire ETH0_TX_FAULT,
	input  wire ETH0_RX_LOS,
	output wire ETH0_TX_DISABLE
);


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
reg        sys_rst;
always @(posedge clk200) 
	if (cold_counter != 14'h3fff) begin
		cold_counter <= cold_counter + 14'd1;
		sys_rst <= 1'b1;
	end else
		sys_rst <= 1'b0;
/*
 *  Ethernet Top Instance
 */
localparam KEY_SIZE = 96;
wire [KEY_SIZE-1:0] in_key;
wire [3:0]          in_flag, out_flag;
wire                in_valid, out_valid;
wire                db_clk;
eth_top eth0_top (
	.clk100             (clk100),
	.sys_rst            (sys_rst),
	.debug              (LED),
	
	/* KVS Interface */
	.db_clk           (db_clk),
	.in_key           (in_key   ),
	.in_flag          (in_flag  ),
	.in_vaild         (in_vaild ),
	.out_valid        (out_valid),
	.out_flag         (out_flag ),

	/* XGMII */
	.SFP_CLK_P          (SFP_CLK_P),
	.SFP_CLK_N          (SFP_CLK_N),
	.SFP_REC_CLK_P      (SFP_REC_CLK_P),
	.SFP_REC_CLK_N      (SFP_REC_CLK_N),

	.ETH0_TX_P          (ETH0_TX_P),
	.ETH0_TX_N          (ETH0_TX_N),
	.ETH0_RX_P          (ETH0_RX_P),
	.ETH0_RX_N          (ETH0_RX_N),

	.I2C_FPGA_SCL       (I2C_FPGA_SCL),
	.I2C_FPGA_SDA       (I2C_FPGA_SDA),

	.SFP_CLK_ALARM_B    (SFP_CLK_ALARM_B),

	.ETH0_TX_FAULT      (ETH0_TX_FAULT ),
	.ETH0_RX_LOS        (ETH0_RX_LOS   ),
	.ETH0_TX_DISABLE    (ETH0_TX_DISABLE) 
);

db_top u_db_top (
	.clk              (db_clk),
	.rst              (sys_rst), 
	/* Network Interface */
	.in_key           (in_key   ),
	.in_flag          (in_flag  ),
	.in_vaild         (in_vaild ),
	.out_valid        (out_valid),
	.out_flag         (out_flag )

	/* DRAM interace */ 
	//input wire    dram_wr_strb,
	//input wire    dram_wr_data, 
);


/*
 * Debug : Clock
 */
//reg [31:0] led_cnt;
//always @ (posedge clk100)
//	if (sys_rst)
//		led_cnt <= 32'd0;
//	else 
//		led_cnt <= led_cnt + 32'd1;
//
//assign LED = led_cnt[31:24];

endmodule

