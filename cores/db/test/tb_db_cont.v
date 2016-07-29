`timescale 1ns / 1ps
`define simulation
module tb ();

/* ---------------------- Sim Parameters -------------------------- */
localparam FREQ      =   20; //  20 @ 50MHz

/* ------------------------ System Pins --------------------------- */

reg clk;
initial clk = 1'b0;
always #(FREQ/2) clk <= ~clk;

reg rst;
initial rst = 1'b0;

/* -------------------- Instance Top module ----------------------- */

reg         in_valid;
reg  [3 :0] in_op;
reg  [31:0] in_hash;
reg  [95:0] in_key;
reg  [31:0] in_value;

wire        out_valid;
wire [ 3:0] out_flag;
wire [31:0] out_value;

db_cont #(
	.HASH_SIZE    (32),
	.KEY_SIZE     (96), // 96bit
	.VAL_SIZE     (32),
	.FLAG_SIZE    (4),
	.RAM_ADDR     (22),
	.RAM_DWIDTH   (32),
	.RAM_SIZE     (1024)
) u_dbcont (
	/* System Interface */
	.clk          (clk),
	.rst          (rst),

	/* Network Interface side */
	.in_valid     (in_valid),
	.in_op        (in_op),
	.in_hash      (in_hash),
	.in_key       (in_key),
	.in_value     (in_value), 

	.out_valid    (out_valid),
	.out_flag     (out_flag),
	.out_value    (out_value),
	/* DRAM Interface */
	.dram_wr_en   (),
	.dram_wr_din  (),
	.dram_addr    (),
	.dram_rd_en   (),
	.dram_rd_dout (),
	.dram_rd_valid()
);

reg [31:0] counter = 0; 
always @ (posedge clk) counter <= counter + 1; 
 
task waitclk(input integer step); 
integer i; 
begin 
    for (i = 0; i < step; i = i + 1) 
        #FREQ; 
end 
endtask

task c_write(input [95:0] data_in, input [31:0] hash_addr, input [3:0] op);
begin
	in_key    = data_in;
	in_hash   = hash_addr;
	in_op     = op;
	in_valid  = 1'b1;
	waitclk(1);
	in_valid  = 1'b0;
end
endtask

task c_read(input [95:0] data_in, input [31:0] hash_addr, input [3:0] op);
begin
	in_key    = data_in;
	in_hash   = hash_addr;
	in_op     = op;
	in_valid  = 1'b1;
	waitclk(1);
	in_valid  = 1'b0;
end
endtask


always @ (posedge clk) begin
	if (out_valid)
		$display("Clk %8d\tRead Data\t[%8h]@0x%8h", counter, out_value, out_flag);
end


reg [31:0] src_ip, dst_ip;
reg [15:0] dst_p;

/* ------------------------ Senario ---------------------------*/
initial begin
	$dumpvars(0, tb);
	$dumpfile("test.vcd");
	rst = 1'b1;
	waitclk(4);
	rst = 1'b0;
	waitclk(1);

	src_ip = {8'd192, 8'd168, 8'd10, 8'd11};
	dst_ip = {8'd192, 8'd168, 8'd80, 8'd87};
	dst_p  = 16'd12345;
	c_write({src_ip, dst_ip, dst_p}, 32'h11223344, 4'b0011);
	waitclk(5);
	
	c_write({src_ip, dst_ip, dst_p}, 32'h11223344, 4'b0101);
	waitclk(5);
	c_write({src_ip, dst_ip, dst_p}, 32'h11223344, 4'b0000);
	waitclk(5);
	waitclk(100);
	$finish();
		
end

endmodule
