module db_cont #(
	parameter HASH_SIZE   =  32,
	parameter KEY_SIZE    = 112, // 80bit + 32bit
	parameter VAL_SIZE    =  32,
	parameter FLAG_SIZE   =   4,
	parameter RAM_ADDR    =  22,
	parameter RAM_DWIDTH  =  32

)(
	/* System Interface */
	input  wire  clk,
	input  wire  rst,

	/* Network Interface side */
	input  wire                  in_valid     ,
	input  wire [3:0]            in_op        ,
	input  wire [HASH_SIZE-1:0]  in_hash      ,
	input  wire [KEY_SIZE-1:0]   in_key       ,
	input  wire [VAL_SIZE-1:0]   in_value     , 

	output wire                  out_valid    ,
	output wire [3:0]            out_flag     ,
	output wire [VAL_SIZE-1:0]   out_value    ,
	/* DRAM Interface */
	output wire                  dram_wr_en   ,
	output wire [RAM_DWIDTH-1:0] dram_wr_din  ,
	output wire [RAM_ADDR-1:0]   dram_addr    ,
	output wire                  dram_rd_en   ,
	input  wire [RAM_DWIDTH-1:0] dram_rd_dout ,
	input  wire                  dram_rd_valid
);
/*
 * Flag field
 *    flag  [0] : RD / WR
 *    flag[2:1] : state
 *    flag  [3] : 
 */

localparam POS_RW_FLAG = FLAG_SIZE+HASH_SIZE+KEY_SIZE+VAL_SIZE-4;

wire [4+HASH_SIZE+KEY_SIZE+VAL_SIZE-1:0] fifo_inj0_din, fifo_inj0_dout;
wire fifo_inj0_empty, fifo_inj0_full;
wire fifo_inj1_empty, fifo_inj1_full;

wire fifo_inj0_rd_en, fifo_inj1_rd_en;

afifo #(
	.DWIDTH    (FLAG_SIZE+HASH_SIZE+KEY_SIZE+VAL_SIZE),
	.DEPTH     (4)
) u_fifo_inject0 (
	.Data      (fifo_inj0_din),
	.WrClock   (clk),
	.RdClock   (clk),
	.WrEn      (in_valid),
	.RdEn      (fifo_inj0_rd_en),
	.Reset     (rst),
	.Q         (fifo_inj0_dout),
	.Empty     (fifo_inj0_empty),
	.Full      (fifo_inj0_full) 
);

afifo #(
	.DWIDTH    (FLAG_SIZE+HASH_SIZE+KEY_SIZE+VAL_SIZE),
	.DEPTH     (4)
) u_fifo_inject1 (
	.Data      (fifo_inj1_din),
	.WrClock   (clk),
	.RdClock   (clk),
	.WrEn      (),
	.RdEn      (fifo_inj1_rd_en),
	.Reset     (rst),
	.Q         (fifo_inj1_dout),
	.Empty     (fifo_inj1_empty),
	.Full      (fifo_inj1_full) 
);

/*
 * Arb
 */
reg  [1:0] arb_c;
wire [1:0] sel_fifo = (!fifo_inj0_empty && !fifo_inj1_empty) ? arb_c :
                      (!fifo_inj0_empty)                     ? 2'b01 :
                      (!fifo_inj1_empty)                     ? 2'b10 : 0;
     
assign fifo_inj0_rd_en = (sel_fifo == 2'b01);
assign fifo_inj1_rd_en = (sel_fifo == 2'b10);

wire wr_din = (fifo_inj0_rd_en) ?  : // Key Lookup
              (fifo_inj1_rd_en) ?  : 0; // Value Lookup
wire addr   = (fifo_inj0_rd_en) ?  :
              (fifo_inj1_rd_en) ?  : 0; // Value Lookup
              

assign dram_wr_en = (fifo_inj0_rd_en) ? fifo_inj0_dout[POS_RW_FLAG] :
                    (fifo_inj1_rd_en) ? fifo_inj1_dout[POS_RW_FLAG] : 0; 
assign dram_din   = (fifo_inj0_rd_en) ?
                    (fifo_inj1_rd_en) ? : 0;
assign dram_addr  = (fifo_inj0_rd_en) ?
                    (fifo_inj1_rd_en) ? : 0;
always @ (posedge clk)
	if (rst) begin
		arb_c <= 2'b01;
	end else begin
		arb_c <= ~arb_c;
	end


/*
 * Hash Table Access Logic
 */
// HashTable 0x0000_0000--0x0000_ffff
wire [HASH_SIZE-1:0] hash = ( in_hash & 32'hFFFF ) * 14;

localparam IDLE   = 0,
           HT_ACC = 1,
           HT_AAA = 2;

reg state [1:0];


always @ (posedge clk)
	if (rst) begin
		state <= IDLE;
	end else begin
		case (state)
			IDLE    : ;
			default : ;
		endcase
	end

/*
 * Data Store Access Logic
 */

always @ (posedge clk)
	if (rst) begin

	end else begin
		if (flag == 4'h1) begin

	end



afifo #(
	.DWIDTH    (FLAG_SIZE+HASH_SIZE+KEY_SIZE+VAL_SIZE),
	.DEPTH     (16)
) u_fifo_parse (
	.Data      (),
	.WrClock   (clk),
	.RdClock   (clk),
	.WrEn      (),
	.RdEn      (rd_en),
	.Reset     (rst),
	.Q         (fifo__dout),
	.Empty     (fifo_empty),
	.Full      (fifo_full) 
);

endmodule
