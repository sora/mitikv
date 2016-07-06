module eth_encap 
//#(
//	parameter frame_len = 16'd80,
//	//parameter tcap_hdr_len = 48,
//	//parameter tlp_len = 32,
//
//	parameter eth_dst   = 48'h90_E2_BA_5D_8D_C9,
//	parameter eth_src   = 48'h00_11_22_33_44_55,
//	//parameter eth_proto = ETH_P_IP,
//	parameter ip_saddr  = {8'd192, 8'd168, 8'd11, 8'd1},
//	parameter ip_daddr  = {8'd192, 8'd168, 8'd11, 8'd3},
//	parameter udp_sport = 16'h3776,
//	parameter udp_dport = 16'h3776
//)
(
	input  wire        clk156,
	input  wire        eth_rst,

	input  wire        m_axis_tready,
	output wire        m_axis_tvalid,
	output reg  [63:0] m_axis_tdata,
	output reg  [ 7:0] m_axis_tkeep,
	output wire        m_axis_tlast,
	output wire        m_axis_tuser
);

localparam TX_IDLE = 2'b00,
           TX_HDR  = 2'b01,
           TX_DATA = 2'b10,
           TX_WAIT = 2'b11;

reg [15:0] tx_count, tx_count_next;
reg [ 1:0] tx_state, tx_state_next;
reg [15:0] wait_cnt, wait_cnt_next;

always @ (posedge clk156) begin
	if (eth_rst) begin
		tx_state <= TX_IDLE;
		tx_count <= 0;
		wait_cnt <= 0;
	end else begin
		tx_state <= tx_state_next;
		tx_count <= tx_count_next;
		wait_cnt <= wait_cnt_next;
	end
end

always @ (*) begin
	tx_state_next = tx_state;
	tx_count_next = tx_count;
	wait_cnt_next = wait_cnt;

	case(tx_state)
		TX_IDLE: begin
			if (m_axis_tready) begin
				tx_state_next = TX_HDR;
				tx_count_next = 0;
			end
		end
		TX_HDR: begin
			if (m_axis_tready) begin
				tx_count_next = tx_count + 1;
				if (tx_count == 5) begin
					tx_state_next = TX_DATA;
				end
			end
		end
		TX_DATA: begin
			if (m_axis_tready && m_axis_tlast) begin
				tx_state_next = TX_WAIT;
			end else if (m_axis_tready) begin
				tx_count_next = tx_count + 1;
			end
		end
		TX_WAIT: begin
			wait_cnt_next = wait_cnt + 1;
			if (wait_cnt == 16'hffff) begin
				tx_state_next = TX_IDLE;
				wait_cnt_next = 16'h0000;
			end
		end
		default: tx_state_next = TX_IDLE;
	endcase
end
reg [7:0] m_axis_tkeep_reg;
always @ (*) begin
	if (tx_state == TX_HDR) begin
		case (tx_count)
			16'h0: m_axis_tkeep_reg = 8'b1111_1111;
			16'h1: m_axis_tkeep_reg = 8'b1111_1111;
			16'h2: m_axis_tkeep_reg = 8'b1111_1111;
			16'h3: m_axis_tkeep_reg = 8'b1111_1111;
			16'h4: m_axis_tkeep_reg = 8'b1111_1111;
			16'h5: m_axis_tkeep_reg = 8'b1111_1111;
			default: m_axis_tkeep_reg = 8'b0000_0000;
		endcase
	end else if (tx_state == TX_DATA) begin
		m_axis_tkeep_reg = 8'b1111_1111;//dout[73:66];
	end
end

reg [63:0] m_axis_tdata_reg;
always @ (*) begin
	m_axis_tdata_reg = 64'd0;
	if (tx_state == TX_HDR) begin
		case (tx_count)
			16'h0: m_axis_tdata_reg = 64'h00000000_44332211;
			16'h1: m_axis_tdata_reg = 64'h00000000_ccddeeff;
			16'h2: m_axis_tdata_reg = 64'h00123456_44332211;
			16'h3: m_axis_tdata_reg = 64'h00987654_44332211;
			16'h4: m_axis_tdata_reg = 64'h00abcdef_44332211;
			16'h5: m_axis_tdata_reg = 64'h11111111_44332211;
			default: m_axis_tdata_reg = 64'h22222222_00000000;
		endcase
	end else if (tx_state == TX_DATA) begin
		m_axis_tdata_reg = 64'hf3ffffff_ffffffff;
	end
end

always @ (posedge clk156) begin
	if (eth_rst) begin
		m_axis_tdata <= 64'h0;
		m_axis_tkeep <=  8'h0;
	end else begin
		m_axis_tdata <= m_axis_tdata_reg;
		m_axis_tkeep <= m_axis_tkeep_reg;
	end
end

assign m_axis_tlast  = (tx_state == TX_DATA);
assign m_axis_tuser  = 1'b1;
assign m_axis_tvalid = (tx_state == TX_HDR || tx_state == TX_DATA);

/*
 *  ILA core instance
 */

reg        m_axis_tready_ila;
reg        m_axis_tvalid_ila;
reg [63:0] m_axis_tdata_ila;
reg [ 7:0] m_axis_tkeep_ila;
reg        m_axis_tlast_ila;
reg        m_axis_tuser_ila;
always @ (posedge clk156) begin
	m_axis_tready_ila <= m_axis_tready;
	m_axis_tvalid_ila <= m_axis_tvalid;
	m_axis_tdata_ila <= m_axis_tdata;
	m_axis_tkeep_ila <= m_axis_tkeep;
	m_axis_tlast_ila <= m_axis_tlast;
	m_axis_tuser_ila <= m_axis_tuser;
end

ila_1 inst_ila (
	.clk     (clk156), // input wire clk
	.probe0  ({
m_axis_tready_ila,
m_axis_tvalid_ila,
m_axis_tdata_ila ,
m_axis_tkeep_ila ,
m_axis_tlast_ila ,
m_axis_tuser_ila }) // input wire [75:0] probe0
);

endmodule

