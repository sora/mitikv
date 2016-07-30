module axis_data_fifo_0 (
	input s_axis_aresetn,
	input s_axis_aclk,

	input  logic        s_axis_tvalid,
	output logic        s_axis_tready,
	input  logic [63:0] s_axis_tdata,
	input  logic [ 7:0] s_axis_tkeep,
	input  logic        s_axis_tlast,
	input  logic [ 0:0] s_axis_tuser,

	output logic        m_axis_tvalid,
	input  logic        m_axis_tready,
	output logic [63:0] m_axis_tdata,
	output logic [ 7:0] m_axis_tkeep,
	output logic        m_axis_tlast,
	output logic [ 0:0] m_axis_tuser,

	output logic [31:0] axis_data_count,
	output logic [31:0] axis_wr_data_count,
	output logic [31:0] axis_rd_data_count
);

logic        tmp_tvalid;
logic        tmp_tready;
logic [63:0] tmp_tdata;
logic [ 7:0] tmp_tkeep;
logic        tmp_tlast;
logic [ 0:0] tmp_tuser;
always_ff @(posedge s_axis_aclk) begin
	if (!eth_rst) begin
		s_axis_tready <= 0;
		m_axis_tvalid <= 0;
		m_axis_tdata  <= 0;
		m_axis_tkeep  <= 0;
		m_axis_tlast  <= 0;
		m_axis_tuser  <= 0;
	end else begin
		tmp_tready <= m_axis_tready;
		tmp_tvalid <= s_axis_tvalid;
		tmp_tready <= s_axis_tready;
		tmp_tdata  <= s_axis_tdata;
		tmp_tkeep  <= s_axis_tkeep;
		tmp_tlast  <= s_axis_tlast;
		tmp_tuser  <= s_axis_tuser;

		s_axis_tready <= tmp_tready;
		m_axis_tvalid <= tmp_tvalid;
		m_axis_tdata  <= tmp_tdata;
		m_axis_tkeep  <= tmp_tkeep;
		m_axis_tlast  <= tmp_tlast;
		m_axis_tuser  <= tmp_tuser;
	end
end

endmodule

