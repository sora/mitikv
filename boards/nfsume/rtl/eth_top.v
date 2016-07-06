module eth_top #(
	parameter PL_LINK_CAP_MAX_LINK_WIDTH = 2,
	parameter C_DATA_WIDTH               = 64,
	parameter KEEP_WIDTH                 = C_DATA_WIDTH / 32
)(
	input  wire clk100,
	input  wire sys_rst,
	output wire [7:0] debug,

	input  wire SFP_CLK_P,
	input  wire SFP_CLK_N,
	output wire SFP_REC_CLK_P,
	output wire SFP_REC_CLK_N,

	input  wire ETH0_TX_P,
	input  wire ETH0_TX_N,
	output wire ETH0_RX_P,
	output wire ETH0_RX_N,

	inout  wire I2C_FPGA_SCL,
	inout  wire I2C_FPGA_SDA,

	input  wire SFP_CLK_ALARM_B,

	input  wire ETH0_TX_FAULT,
	input  wire ETH0_RX_LOS,
	output wire ETH0_TX_DISABLE
);

/*
 * Ethernet Clock Domain : Clocking
 */
wire clk156;
sfp_refclk_init sfp_refclk_init0 (
	.CLK               (clk100),
	.RST               (sys_rst),
	.SFP_REC_CLK_P     (SFP_REC_CLK_P), //: out std_logic;
	.SFP_REC_CLK_N     (SFP_REC_CLK_N), //: out std_logic;
	.SFP_CLK_ALARM_B   (SFP_CLK_ALARM_B), //: in std_logic;
	.I2C_FPGA_SCL      (I2C_FPGA_SCL), //: inout std_logic;
	.I2C_FPGA_SDA      (I2C_FPGA_SDA)  //: inout std_logic
);

/*
 *  Ethernet Clock Domain : Reset
 */
reg [13:0] cold_counter = 0; 
reg        eth_rst;
always @(posedge clk156) 
	if (cold_counter != 14'h3fff) begin
		cold_counter <= cold_counter + 14'd1;
		eth_rst      <= 1'b1;
	end else
		eth_rst <= 1'b0;


/*
 * Ethernet MAC and PCS/PMA Configuration
 */

wire [535:0] pcs_pma_configuration_vector;
pcs_pma_conf pcs_pma_conf0(
	.pcs_pma_configuration_vector(pcs_pma_configuration_vector)
);

wire [79:0] mac_tx_configuration_vector;
wire [79:0] mac_rx_configuration_vector;
eth_mac_conf eth_mac_conf0(
	.mac_tx_configuration_vector(mac_tx_configuration_vector),
	.mac_rx_configuration_vector(mac_rx_configuration_vector)
);

/*
 * AXI interface
 */
wire        m_axis_fifo_tvalid;
wire        m_axis_fifo_tready;
wire [63:0] m_axis_fifo_tdata;
wire [ 7:0] m_axis_fifo_tkeep;
wire        m_axis_fifo_tlast;
wire        m_axis_fifo_tuser;
eth_encap eth_encap0 (
	.clk156           (clk156),
	.eth_rst          (eth_rst),

	.m_axis_tvalid    (m_axis_fifo_tvalid),
	.m_axis_tready    (m_axis_fifo_tready),
	.m_axis_tdata     (m_axis_fifo_tdata),
	.m_axis_tkeep     (m_axis_fifo_tkeep),
	.m_axis_tlast     (m_axis_fifo_tlast),
	.m_axis_tuser     (m_axis_fifo_tuser)
);


/*
 * Ethernet MAC
 */
wire txusrclk_out;
wire txusrclk2_out;
wire gttxreset_out;
wire gtrxreset_out;
wire txuserrdy_out;
wire areset_datapathclk_out;
wire reset_counter_done_out;
wire qplllock_out;
wire qplloutclk_out;
wire qplloutrefclk_out;
wire [447:0] pcs_pma_status_vector;
wire [1:0] mac_status_vector;
wire [7:0] pcspma_status;
wire rx_statistics_valid;
wire tx_statistics_valid;

axi_10g_ethernet_0 axi_10g_ethernet_0_ins (
	.coreclk_out                   (clk156),
	.refclk_n                      (SFP_CLK_N),
	.refclk_p                      (SFP_CLK_P),
	.dclk                          (clk156),
	.reset                         (eth_rst),
	.rx_statistics_vector          (),
	.rxn                           (ETH0_TX_N),
	.rxp                           (ETH0_TX_P),
	.s_axis_pause_tdata            (16'b0),
	.s_axis_pause_tvalid           (1'b0),
	.signal_detect                 (!ETH0_RX_LOS),
	.tx_disable                    (ETH0_TX_DISABLE),
	.tx_fault                      (ETH0_TX_FAULT),
	.tx_ifg_delay                  (8'd8),
	.tx_statistics_vector          (),
	.txn                           (ETH0_RX_N),
	.txp                           (ETH0_RX_P),

	.rxrecclk_out                  (),
	.resetdone_out                 (),

	// eth tx
	.s_axis_tx_tready              (m_axis_fifo_tready),
	.s_axis_tx_tdata               (m_axis_fifo_tdata),
	.s_axis_tx_tkeep               (m_axis_fifo_tkeep),
	.s_axis_tx_tlast               (m_axis_fifo_tlast),
	.s_axis_tx_tvalid              (m_axis_fifo_tvalid),
	.s_axis_tx_tuser               (m_axis_fifo_tuser),
	
	// eth rx
	.m_axis_rx_tdata               (),
	.m_axis_rx_tkeep               (),
	.m_axis_rx_tlast               (),
	.m_axis_rx_tuser               (),
	.m_axis_rx_tvalid              (),

	.sim_speedup_control           (1'b0),
	.rx_axis_aresetn               (1'b1),
	.tx_axis_aresetn               (1'b1),

	.tx_statistics_valid           (tx_statistics_valid),         
	.rx_statistics_valid           (rx_statistics_valid),
	.pcspma_status                 (pcspma_status),                
	.mac_tx_configuration_vector   (mac_tx_configuration_vector),  
	.mac_rx_configuration_vector   (mac_rx_configuration_vector),  
	.mac_status_vector             (mac_status_vector),            
	.pcs_pma_configuration_vector  (pcs_pma_configuration_vector), 
	.pcs_pma_status_vector         (pcs_pma_status_vector),        
	.areset_datapathclk_out        (areset_datapathclk_out),        
	.txusrclk_out                  (txusrclk_out),                  
	.txusrclk2_out                 (txusrclk2_out),                 
	.gttxreset_out                 (gttxreset_out),                 
	.gtrxreset_out                 (gtrxreset_out),                 
	.txuserrdy_out                 (txuserrdy_out),                 
	.reset_counter_done_out        (reset_counter_done_out),        
	.qplllock_out                  (qplllock_out     ),                  
	.qplloutclk_out                (qplloutclk_out   ),                
	.qplloutrefclk_out             (qplloutrefclk_out)   
);

reg [31:0] led_cnt;
always @ (posedge clk156)
	if (eth_rst)
		led_cnt <= 32'd0;
	else 
		led_cnt <= led_cnt + 32'd1;

assign debug = led_cnt[31:24];

endmodule

