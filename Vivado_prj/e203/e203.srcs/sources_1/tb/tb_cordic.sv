`timescale 1ns/100ps
module tb_cordic(); /* this is automatically generated */

//测试用信?
logic clk;
logic [15:0]phase_in;
logic signed [16:0]sin,cos,eps;
logic start,valid,rsp;
real phan,sinn,cosn;

always@(*) begin
	phan=real'(phase_in)*360/65536;
	sinn=real'(sin)/65536;
	cosn=real'(cos)/65536;
end
// clk
initial begin
	clk = '0;
	forever #(25) clk = ~clk;
end

//启动测试
initial begin
	#10;
	valid=0;
	@(posedge clk);
	#5 phase_in=0;
	valid=1;
	@(posedge clk);
	#5 phase_in=65535/4;
	@(posedge clk);
	#5 phase_in=65535/6;
	@(posedge clk);
	#5 phase_in=65535/8;
	@(posedge clk);
	#5 phase_in=65535*3/8;
	@(posedge clk);
	#5 phase_in=65535*2/3;
	@(posedge clk);
	#5 phase_in=65535*7/8;
	@(posedge clk);
	#1;
	valid=0;
	#300;
	$stop;
end

//例化
cordic inst_cordic (
	.clk      (clk),
	.phase_in (phase_in),
	.sin      (sin),
	.cos      (cos),
	.eps      (eps),
	.valid(valid),
	.rsp(rsp)
);


endmodule
