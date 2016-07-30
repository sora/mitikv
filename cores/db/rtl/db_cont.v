module db_cont #(
	parameter HASH_SIZE   = 32,
	parameter KEY_SIZE    = 96, // 80bit + 32bit
	parameter VAL_SIZE    = 32,
	parameter FLAG_SIZE   =  4,
	parameter RAM_ADDR    = 22,
	parameter RAM_DWIDTH  = 32,
	parameter RAM_SIZE    = 1024
	

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

	output reg                   out_valid    ,
	output reg  [3:0]            out_flag     ,
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
 * Free Running Counter
 *
 */
wire div_clk;
reg [23:0] div_cnt;
always @ (posedge clk)
	if (rst)
		div_cnt <= 0;
	else
		div_cnt <= div_cnt + 1;

reg [15:0] sys_cnt = 0;
always @ (posedge div_clk)
	sys_cnt <= sys_cnt + 1;

`ifdef SIMULATION
assign div_clk = div_cnt[3];
`else
BUFG u_bufg_sys_clk (.I(div_cnt[23]), .O(div_clk));
`endif  /* SIMULATION */

/*
 * Flag field
 *    flag  [0] : RD / WR
 *    flag[3:1] : state
 *                3'b000 : IDLE
 *                3'b001 : SUSPECTION
 *                3'b010 : ARREST
 *                3'b011 : FILTERED
 */


/*
 * Hash Table Access Logic
 */
// HashTable 0x0000_0000--0x0000_ffff
wire [HASH_SIZE-1:0] hash = ( in_hash & 32'h3FF );

localparam IDLE   = 0,
           CHECK  = 1,
           MISS   = 2,
           UPDATE = 3;
integer i;
reg [1:0]          state;
reg [KEY_SIZE-1:0] fetched_key;
reg [VAL_SIZE-1:0] fetched_val, get_val;
reg                judge;
/* Hash Table & Data Store */
reg [KEY_SIZE-1:0] KEY [RAM_SIZE-1:0];
reg [KEY_SIZE-1:0] VAL [RAM_SIZE-1:0];

wire [1:0] fetched_flag = fetched_val[23:21];

always @ (posedge clk)
	if (rst) begin
		judge       <=    0;
		state       <= IDLE;
		fetched_key <=    0;
		fetched_val <=    0;
		out_valid   <=    0;
		out_flag    <=    0;

`ifndef SIMULATION
		for (i = 0; i < RAM_SIZE; i = i + 1) begin
			KEY[i] <= 0;
			VAL[i] <= 0;
		end
`endif
	end else begin
		case (state)
			IDLE  : begin
				judge <= 0;
				out_valid <= 0;
				out_flag  <= 0;
				if (in_valid) begin
					fetched_key <= KEY[hash];
					fetched_val <= VAL[hash];
					if (in_key == KEY[hash]) 
						state <= CHECK;
					else
						state <= MISS;
				end
			end
			CHECK : if (fetched_val[15:0] > sys_cnt[15:0]) begin
				// Okay?
				judge <= 0;
				if (in_op[0] == 1)
					state <= UPDATE;
				else
					state <= IDLE;
			end else begin
				if (in_op[0] == 1) begin
					state <= UPDATE;
					case (in_op[2:1])
						2'b00: state <= IDLE;
						2'b01: begin
							if (fetched_flag[1] == 0)
								state <= UPDATE;
							else
								state <= IDLE;
						end
						2'b10: begin
							if (fetched_flag == 2'b01)
								state <= UPDATE;
							else
								state <= IDLE;
						end
						2'b11: state <= IDLE;
					endcase
				end else begin // GET request
					state     <= IDLE;
					judge     <= 1;
				end
				out_valid <= 1;
				out_flag  <= fetched_val[23:20];
			end
			MISS  : if (in_op[0] == 1)
				state <= UPDATE;
			else // in_op == GET
				state <= IDLE;
			UPDATE: begin
				KEY[hash] <= in_key;
				VAL[hash] <= {in_op, 4'd0, sys_cnt[15:0]};
				state <= IDLE;
			end
			default : state <= IDLE;
		endcase
	end

endmodule
