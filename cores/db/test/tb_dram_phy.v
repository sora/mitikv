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

reg         wr_en;
reg  [31:0] din;
reg  [21:0] addr_p;
reg         rd_en;
wire [31:0] rd_dout;
wire        rd_valid;

dram_phy #(
	.RAM_SIZE_KB  (1),
	.RAM_ADDR     (22),
	.RAM_DWIDTH   (32)
) u_dram_phy (
	.clk       (clk),
	.rst       (rst),

	.wr_en     (wr_en),
	.wr_din    (din),
	.addr      (addr_p),
	.rd_en     (rd_en),
	.rd_dout   (rd_dout),
	.rd_valid  (rd_valid)
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

task c_write(input [31:0] data_in, input [21:0] addr);
begin
	din    = data_in;
	addr_p = addr;
	wr_en  = 1'b1;
	waitclk(1);
	wr_en  = 1'b0;
end
endtask

task c_read(input [21:0] addr);
begin
	addr_p = addr;
	rd_en  = 1'b1;
	waitclk(1);
	rd_en  = 1'b0;
end
endtask


always @ (posedge clk) begin
	if (rd_valid)
		$display("Clk %8d\tRead Data\t[%8h]@0x%8h", counter, rd_dout, addr_p);
end

/* ------------------------ Senario ---------------------------*/
initial begin
	$dumpvars(0, tb);
	$dumpfile("test.vcd");
	rst = 1'b1;
	waitclk(4);
	rst = 1'b0;
	waitclk(1);

	c_write(32'h11223344, 22'h000001);
	c_write(32'habcdef12, 22'h000002);
	c_write(32'h01234567, 22'h000003);
	c_read(22'h000001);
	c_read(22'h000002);
	c_read(22'h000003);
	
	waitclk(100);
	$finish();
		
end

endmodule
