`define DEBUG

module eth_encap #(
	parameter KEY_SIZE = 96,
	parameter VAL_SIZE = 32
)(
	input  wire        clk156,
	input  wire        eth_rst,
	output wire [ 7:0] debug,

	output wire [KEY_SIZE-1:0] in_key,
	output wire [3:0]          in_flag,
	output wire                in_vaild,
	input  wire                out_valid,
	input  wire [3:0]          out_flag,

	input  wire        s_axis_tvalid,
	input  wire [63:0] s_axis_tdata,
	input  wire [ 7:0] s_axis_tkeep,
	input  wire        s_axis_tlast,
	input  wire        s_axis_tuser,

	input  wire        m_axis_tready,
	output wire        m_axis_tvalid,
	output wire [63:0] m_axis_tdata,
	output wire [ 7:0] m_axis_tkeep,
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

//always @ (posedge clk156) begin
//	if (eth_rst) begin
//		tx_state <= TX_IDLE;
//		tx_count <= 0;
//		wait_cnt <= 0;
//	end else begin
//		tx_state <= tx_state_next;
//		tx_count <= tx_count_next;
//		wait_cnt <= wait_cnt_next;
//	end
//end
//
//always @ (*) begin
//	tx_state_next = tx_state;
//	tx_count_next = tx_count;
//	wait_cnt_next = wait_cnt;
//
//	case(tx_state)
//		TX_IDLE: begin
//			if (m_axis_tready) begin
//				tx_state_next = TX_HDR;
//				tx_count_next = 0;
//			end
//		end
//		TX_HDR: begin
//			if (m_axis_tready) begin
//				tx_count_next = tx_count + 1;
//				if (tx_count == 9) begin
//					tx_state_next = TX_WAIT;
//				end
//			end
//		end
//		TX_DATA: begin
//			if (m_axis_tready && m_axis_tlast) begin
//				tx_state_next = TX_WAIT;
//			end else if (m_axis_tready) begin
//				tx_count_next = tx_count + 1;
//			end
//		end
//		TX_WAIT: begin
//			wait_cnt_next = wait_cnt + 1;
//			if (wait_cnt == 16'hffff) begin
//				tx_state_next = TX_IDLE;
//				wait_cnt_next = 16'h0000;
//			end
//		end
//		default: tx_state_next = TX_IDLE;
//	endcase
//end
//
//assign m_axis_tkeep = (tx_state == TX_HDR) ? 8'b1111_1111 : 8'b0000_0000;

//always @ (*) begin
//	if (tx_state == TX_HDR) begin
//		case (tx_count)
//			default: m_axis_tkeep = 8'b1111_1111;
//		endcase
//	end else if (tx_state == TX_DATA) begin
//		m_axis_tkeep = 8'b1111_1111;//dout[73:66];
//	end
//end

//always @ (*) begin
//	m_axis_tdata = 64'd0;
//	if (tx_state == TX_HDR) begin
//		case (tx_count)
//			16'h0: m_axis_tdata = 64'h11_00_d1_91_5d_ba_e2_90;
//			16'h1: m_axis_tdata = 64'h00_45_00_08_55_44_33_22;
//			16'h2: m_axis_tdata = 64'h11_40_00_00_00_00_2e_00;
//			16'h3: m_axis_tdata = 64'ha8_c0_01_64_a8_c0_62_31;
//			16'h4: m_axis_tdata = 64'h1a_00_76_37_76_37_0b_64;
//			16'h5: m_axis_tdata = 64'h3d_00_00_00_00_20_00_00;
//			16'h6: m_axis_tdata = 64'hFF_FF_FF_FF_FF_FF_FF_FF;
//			16'h7: m_axis_tdata = 64'h00_40_00_C0_00_00_00_00;
//			16'h8: m_axis_tdata = 64'h01_08_00_00_00_00_70_00;
//			16'h9: m_axis_tdata = 64'haa_aa_aa_aa_00_00_00_00;
//			default: m_axis_tdata = 64'h22222222_00000000;
//		endcase
//	end 
//end
//
//assign m_axis_tlast  = (tx_state == TX_HDR && tx_count == 9);
//assign m_axis_tuser  = 1'b0;
//assign m_axis_tvalid = (tx_state == TX_HDR || tx_state == TX_DATA);

/*
 *  RX path
 */
localparam ETH_FTYPE_IP  = 16'h0800;
localparam IP_PROTO_UDP  = 8'h11,
           IP_PROTO_ICMP = 8'h01;
localparam ICMP_PORT_UNREACH = 8'h03;
localparam ICMP_DEST_UNREACH = 8'h03;
localparam DNS_SERV_PORT__   = 16'd53;
localparam DEBUG_SERV_PORT__ = 16'd12345;
`ifdef DEBUG
localparam DNS_SERV_PORT = DEBUG_SERV_PORT__;
`else
localparam DNS_SERV_PORT = DNS_SERV_PORT__;
`endif /* DEBUG */
localparam DNS_PARAM_RESPONSE = 1'b1,
           DNS_PARAM_REQUEST  = 1'b0;

localparam STATUS_SUSPECT = 2'b01,
           STATUS_ARREST  = 2'b10,
           STATUS_FILTERE = 2'b11;


/* general regs for parsering */
reg  [9:0] rx_cnt;
reg  [7:0] hit_cnt;
/* regs for parsering */
reg [15:0] rx_ftype;
reg  [7:0] rx_ip_proto;
reg [15:0] rx_dst_uport, rx_src_uport;
reg [31:0] rx_dst_ip, rx_src_ip;
reg  [7:0] rx_icmp_type, rx_icmp_code;
reg [ 7:0] filter_ip_proto;
reg [31:0] filter_src_ip, filter_dst_ip;
reg [15:0] filter_dst_udp, filter_len_udp, filter_qid_dns, filter_src_udp;
reg [15:0] filter_parm_dns, filter_qcnt_dns, filter_acnt_dns, filter_auth_dns;
reg [15:0] suspect_parm_dns, suspect_qcnt_dns, suspect_acnt_dns,suspect_auth_dns;
reg [15:0] suspect_qid_dns;
reg  [7:0] filter_iph_len;
reg [15:0] filter_ipd_len;
/* DB Request Registers */
reg [3:0] db_op;
wire filter_mode  = rx_ftype     == ETH_FTYPE_IP      && 
                    rx_ip_proto  == IP_PROTO_ICMP     &&
                    rx_icmp_type == ICMP_DEST_UNREACH &&
                    rx_icmp_code == ICMP_PORT_UNREACH;
wire suspect_mode = rx_ftype     == ETH_FTYPE_IP      &&
                    rx_ip_proto  == IP_PROTO_UDP      &&
					rx_src_uport == DNS_SERV_PORT;

always @ (posedge clk156) begin
	if (eth_rst) begin
		rx_cnt          <= 0;
		hit_cnt         <= 0;
		rx_ip_proto     <= 0;
		rx_src_ip       <= 0;
		rx_dst_ip       <= 0;
		rx_src_uport    <= 0;
		rx_dst_uport    <= 0;
		rx_ftype        <= 0;
		rx_icmp_type    <= 0;
		rx_icmp_code    <= 0;
		filter_ip_proto <= 0;
		filter_src_ip   <= 0; 
		filter_dst_ip   <= 0; 
		filter_dst_udp  <= 0; 
		filter_len_udp  <= 0; 
		filter_qid_dns  <= 0; 
		filter_src_udp  <= 0;
		filter_parm_dns <= 0; 
		filter_qcnt_dns <= 0; 
		filter_acnt_dns <= 0; 
		filter_auth_dns <= 0;
		suspect_qid_dns  <= 0; 
		suspect_parm_dns <= 0; 
		suspect_qcnt_dns <= 0; 
		suspect_acnt_dns <= 0; 
		suspect_auth_dns <= 0;
		db_op            <= 0;
	end else begin
		if (s_axis_tvalid) begin
			if (s_axis_tlast)
				rx_cnt <= 0;
			else
				rx_cnt <= rx_cnt + 1;
			case (rx_cnt)
				0: begin // Reset all registers
					rx_ip_proto     <= 0;
					rx_src_ip       <= 0;
					rx_dst_ip       <= 0;
					rx_src_uport    <= 0;
					rx_dst_uport    <= 0;
					rx_ftype        <= 0;
					rx_icmp_type    <= 0;
					rx_icmp_code    <= 0;
					filter_ip_proto <= 0;
					filter_src_ip   <= 0; 
					filter_dst_ip   <= 0; 
					filter_dst_udp  <= 0; 
					filter_len_udp  <= 0; 
					filter_qid_dns  <= 0; 
					filter_src_udp  <= 0;
					filter_parm_dns <= 0; 
					filter_qcnt_dns <= 0; 
					filter_acnt_dns <= 0; 
					filter_auth_dns <= 0;
					suspect_qid_dns  <= 0; 
					suspect_parm_dns <= 0; 
					suspect_qcnt_dns <= 0; 
					suspect_acnt_dns <= 0; 
					suspect_auth_dns <= 0;
					db_op            <= 0;
				end
				1: rx_ftype <= {s_axis_tdata[39:32], s_axis_tdata[47:40]};
				2: rx_ip_proto <= s_axis_tdata[63:56];
				3: begin
					rx_src_ip <= {s_axis_tdata[23:16],
                                  s_axis_tdata[31:24],
                                  s_axis_tdata[39:32],
                                  s_axis_tdata[47:40]};
					rx_dst_ip <= {s_axis_tdata[55:48],
                                  s_axis_tdata[63:56]};
				end
				4: begin
					rx_dst_ip <= {s_axis_tdata[ 7: 0],
                                  s_axis_tdata[15: 8]};
					if (rx_ftype == ETH_FTYPE_IP && 
							rx_ip_proto == IP_PROTO_UDP) begin
							rx_src_uport <= {s_axis_tdata[23:16], 
							                 s_axis_tdata[31:24]};
							rx_dst_uport <= {s_axis_tdata[39:32], 
							                 s_axis_tdata[47:40]};
					end else if (rx_ftype == ETH_FTYPE_IP 
						&& rx_ip_proto == IP_PROTO_ICMP) begin
							rx_icmp_type <= s_axis_tdata[23:16];
							rx_icmp_code <= s_axis_tdata[31:24];
					end
				end
				5: if (filter_mode) begin
					filter_iph_len <= s_axis_tdata[23:16];
					filter_ipd_len <= {s_axis_tdata[39:32],
                                       s_axis_tdata[47:40]};
				end else if (suspect_mode) begin
					suspect_qid_dns <= {s_axis_tdata[23:16],
					                    s_axis_tdata[31:24]};
					suspect_parm_dns <= {s_axis_tdata[39:32],
                                         s_axis_tdata[47:40]};
                    suspect_qcnt_dns <= {s_axis_tdata[55:48],
                                         s_axis_tdata[63:56]};
				end                          
				6: if (filter_mode) begin
					filter_ip_proto      <= s_axis_tdata[32:23];
					filter_src_ip[31:16] <= {s_axis_tdata[55:48],
					                         s_axis_tdata[63:56]};
				end else if (suspect_mode) begin
                    suspect_acnt_dns <= {s_axis_tdata[ 7: 0],
                                         s_axis_tdata[15: 8]};
                    suspect_auth_dns <= {s_axis_tdata[23:16],
					                     s_axis_tdata[31:24]};
				end
				7: if (filter_mode) begin
					filter_src_ip[15:0] <= {s_axis_tdata[ 7: 0],
					                        s_axis_tdata[15: 8]};
					filter_dst_ip       <= {s_axis_tdata[23:16],
					                        s_axis_tdata[31:24],
					                        s_axis_tdata[39:32],
					                        s_axis_tdata[47:40]};
					filter_src_udp      <= {s_axis_tdata[55:48],
					                        s_axis_tdata[63:56]};
				end
				8: if (filter_mode) begin
					filter_dst_udp      <= {s_axis_tdata[ 7: 0],
					                        s_axis_tdata[15: 8]};
					filter_len_udp      <= {s_axis_tdata[23:16],
					                        s_axis_tdata[31:24]};
					filter_qid_dns      <= {s_axis_tdata[55:48],
					                        s_axis_tdata[63:56]};
				end
				9: if (filter_mode) begin
					filter_parm_dns      <= {s_axis_tdata[ 7: 0],
					                         s_axis_tdata[15: 8]};
					filter_qcnt_dns      <= {s_axis_tdata[23:16],
					                         s_axis_tdata[31:24]};
					filter_acnt_dns      <= {s_axis_tdata[39:32],
					                         s_axis_tdata[47:40]};
					filter_auth_dns      <= {s_axis_tdata[55:48],
					                         s_axis_tdata[63:56]};
				end
				default : ;
			endcase
			if (rx_ftype == ETH_FTYPE_IP && 
					rx_ip_proto  == IP_PROTO_UDP  &&
					rx_dst_uport == DNS_SERV_PORT &&
					s_axis_tlast)
				hit_cnt <= hit_cnt + 1;
			if (suspect_mode && suspect_parm_dns[0] == DNS_PARAM_RESPONSE &&
				rx_cnt == 10'd6)
				db_op <= 4'b0011;
			if (filter_mode && filter_parm_dns[0] == DNS_PARAM_RESPONSE &&
				rx_cnt == 10'd10)
				db_op <= 4'b0101;
		end
	end
end

wire [1:0] status = db_op[2:1];
assign in_flag = db_op;
assign in_valid = (suspect_mode && rx_cnt == 10'd7) || 
                  (filter_mode  && rx_cnt == 10'd11);

assign in_key = (status == STATUS_SUSPECT) ? {rx_src_ip, rx_dst_ip, 
                                              rx_dst_uport , 16'd0}  :
                (status == STATUS_ARREST)  ? {filter_src_ip, filter_dst_ip, 
                                              filter_dst_udp, 16'd0} : 0;

assign debug = hit_cnt;

/*
 * Loopback FIFO for packet mode
 */
axis_data_fifo_0 u_axis_data_fifo (
  .s_axis_aresetn      (!eth_rst),     // input wire s_axis_aresetn
  .s_axis_aclk         (clk156),       // input wire s_axis_aclk

  .s_axis_tvalid       (s_axis_tvalid),// input wire s_axis_tvalid
  .s_axis_tready       (),             // te s_axis_tready
  .s_axis_tdata        (s_axis_tdata), // input wire [63 : 0] s_axis_tdata
  .s_axis_tkeep        (s_axis_tkeep), // input wire [7 : 0] s_axis_tkeep
  .s_axis_tlast        (s_axis_tlast), // input wire s_axis_tlast
  .s_axis_tuser        (1'b0), // input wire [0 : 0] s_axis_tuser

  .m_axis_tvalid       (m_axis_tvalid),// output wire m_axis_tvalid
  .m_axis_tready       (m_axis_tready),// input wire m_axis_tready
  .m_axis_tdata        (m_axis_tdata), // output wire [63 : 0] m_axis_tdata
  .m_axis_tkeep        (m_axis_tkeep), // output wire [7 : 0] m_axis_tkeep
  .m_axis_tlast        (m_axis_tlast), // output wire m_axis_tlast
  .m_axis_tuser        (m_axis_tuser), // output wire [0 : 0] m_axis_tuser
  .axis_data_count     (),        // output wire [31 : 0] axis_data_count
  .axis_wr_data_count  (),  // output wire [31 : 0] axis_wr_data_count
  .axis_rd_data_count  ()  // output wire [31 : 0] axis_rd_data_count
);
`ifdef SIMULATION_ILA
/*
 *  ILA core instance
 */

reg        tready_ila;
reg        tvalid_ila;
reg [63:0] tdata_ila;
reg [ 7:0] tkeep_ila;
reg        tlast_ila;
reg        tuser_ila;
always @ (posedge clk156) begin
	tready_ila <= m_axis_tready;
	tvalid_ila <= s_axis_tvalid;
	tdata_ila <= s_axis_tdata;
	tkeep_ila <= s_axis_tkeep;
	tlast_ila <= s_axis_tlast;
	tuser_ila <= s_axis_tuser;
end

ila_1 inst_ila (
	.clk     (clk156), // input wire clk
	.probe0  ({
		tready_ila,
		tvalid_ila,
		tdata_ila ,
		tkeep_ila ,
		tlast_ila ,
		tuser_ila 
	}) // input wire [75:0] probe0
);

`endif /* SIMULATION_ILA */

endmodule

