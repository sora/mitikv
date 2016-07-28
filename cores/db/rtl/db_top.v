module db_top (
	input wire    clk,
	input wire    rst, 
	/* Network Interface */

	/* DRAM interace */ 
	input wire    dram_wr_strb,
	input wire    dram_wr_data, 
);


localparam KEY_LEN = 80; // bit size (10B)
/*
 * Tupple design, which is Key paired with value. 
 *     Source IP             : 32 bit
 *     Destination IP        : 32 bit
 *     Destination UDP port  : 16 bit
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
localparam DNS_REPLY_DETECT    = 1,
           PORT_UNREACH_DETECT = 2,
           FILTERED            = 3,
           EXPIRED             = 4;


/*
 * Memory Layout: 
 * 0x0000000 +------------+
 *           |            |
 *           | Hash Table |
 *           |            |
 * 0x0000xxx +------------+
 *           |            |
 *           | Data Store |
 *           |            |
 *           +------------+
 *
 *
 *
 *
 */

/*
 * Hash Function for Indexing
 */

crc32 u_hashf (
  .data_in    (),
  .crc_en     (),
  .crc_out    (),
  .rst        (rst),
  .clk        (clk) 
);

/*
 * DRAM PHY Controller
 */
dram_phy u_dram_phy #(
	RAM_SIZE_KB  (1),
	RAM_ADDR     (22),
	RAM_DWIDTH   (32)
)(
	.clk         (clk),
	.rst         (rst),

	.wr_en       (),
	.wr_din      (),
	.addr        (),
	.rd_en       (),
	.rd_dout     (),
	.rd_valid    ()
);

endmodule
