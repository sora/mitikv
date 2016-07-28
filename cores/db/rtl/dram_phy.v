module dram_phy #(
	parameter RAM_SIZE_KB = 1,
	parameter RAM_ADDR    = 22,
	parameter RAM_DWIDTH  = 32
)(
	input   wire                  clk     ,
	input   wire                  rst     ,

	input   wire                  wr_en   ,
	input   wire [RAM_DWIDTH-1:0] wr_din  ,
	input   wire [RAM_ADDR-1:0]   addr    ,
	input   wire                  rd_en   ,
	output  wire [RAM_DWIDTH-1:0] rd_dout ,
	output  wire                  rd_valid
);

/* Parameters */
localparam RAM_SIZE = RAM_SIZE_KB * 1024;
integer i;
/* RAM */
reg [RAM_DWIDTH-1:0] RAM [RAM_SIZE-1:0];

/* Pipelined registers */
reg [RAM_DWIDTH-1:0] latency0, latency1, latency2, latency3;
reg rd_latency0, rd_latency1, rd_latency2, rd_latency3;

wire [RAM_DWIDTH-1:0] rd_data  = RAM[addr];
assign                rd_dout  = latency3;
assign                rd_valid = rd_latency3;

always @ (posedge clk) begin
	if (rst) begin	
		/* initialize RAM */
		for (i=0; i<RAM_SIZE; i=i+1) 
			RAM[i] <= 0;
		/* pipelined register */
		rd_latency0 <= 0;
		rd_latency1 <= 0;
		rd_latency2 <= 0;
		rd_latency3 <= 0;
		latency0    <= 0;
		latency1    <= 0;
		latency2    <= 0;
		latency3    <= 0;
	end else begin 
		if (wr_en)
			RAM[addr] <= wr_din;
		
		rd_latency0 <= rd_en;
		rd_latency1 <= rd_latency0;
		rd_latency2 <= rd_latency1;
		rd_latency3 <= rd_latency2;

		latency0 <= rd_data;
		latency1 <= latency0;
		latency2 <= latency1;
		latency3 <= latency2;
	end
end



endmodule
