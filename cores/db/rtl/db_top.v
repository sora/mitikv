module db_top #(
	parameter KEY_SIZE = 96,
	parameter VAL_SIZE = 32
)(
	input  wire                clk,
	input  wire                rst, 
	/* Network Interface */
	input  wire [KEY_SIZE-1:0] in_key,
	input  wire [3:0]          in_flag,
	input  wire                in_valid,
	output wire                out_valid,
	output wire [3:0]          out_flag

	/* DRAM interace */ 
	//input wire    dram_wr_strb,
	//input wire    dram_wr_data, 
);


localparam KEY_LEN = 96; // bit size (12B)
/*
 * Tupple design, which is Key paired with value. 
 *     Source IP             : 32 bit
 *     Destination IP        : 32 bit
 *     Destination UDP port  : 16 bit
 *     Reserved              : 16 bit
 */
localparam VAL_LEN = 32; // bit size (4B)
/*
 * Value design, 
 *     Status Code           :  4 bit
 *     Flag                  :  4 bit
 *     Time (for Expired)    : 16 bit
 *     Reserved              :  8 bit
 */

/*
 * Status Code for Value Entry
 */
localparam SUSPECTION = 1,
           ARREST     = 2,
           FILTERED   = 3,
           EXPIRED    = 4;
/*
 * Hash Function for Indexing
 */

wire [31:0] hash;
crc32 u_hashf (
  .data_in    (in_key),
  .crc_en     (in_valid),
  .crc_out    (hash),
  .rst        (rst),
  .clk        (clk) 
);

db_cont #(
	.HASH_SIZE    (32),
	.KEY_SIZE     (96), // 80bit + 32bit
	.VAL_SIZE     (32),
	.FLAG_SIZE    ( 4),
	.RAM_ADDR     (22),
	.RAM_DWIDTH   (32),
	.RAM_SIZE     (1024)
) u_db_cont (
	/* System Interface */
	.clk          (clk),
	.rst          (rst),

	/* Network Interface side */
	.in_valid     (in_valid),
	.in_op        (in_flag),
	.in_hash      (hash),
	.in_key       (in_key),
	.in_value     (), 

	.out_valid    (out_valid),
	.out_flag     (out_flag),
	.out_value    (),
	/* DRAM Interface */
	.dram_wr_en   (),
	.dram_wr_din  (),
	.dram_addr    (),
	.dram_rd_en   (),
	.dram_rd_dout (),
	.dram_rd_valid()
);


/*
 * DRAM PHY Controller
 */
//dram_phy u_dram_phy #(
//	RAM_SIZE_KB  (1),
//	RAM_ADDR     (22),
//	RAM_DWIDTH   (32)
//)(
//	.clk         (clk),
//	.rst         (rst),
//
//	.wr_en       (),
//	.wr_din      (),
//	.addr        (),
//	.rd_en       (),
//	.rd_dout     (),
//	.rd_valid    ()
//);
//
endmodule
