module ram
#(
	parameter DW = 16,
	parameter AW = 13,
	parameter RAM_AW = 7
)(
	input			clk, //时钟
	input 			rst,  //同步复位，高电平有效
	input [DW-1:0]	din, //数据输入
	input [AW-1:0]	addr, //地址输入
	input			we, //高电平写使能
	output [DW-1:0] dout //数据输出
);

reg [DW-1:0] mem_r [(2**RAM_AW)-1:0];//内存定义

always @(posedge clk) begin
	if(we)
		mem_r[addr[RAM_AW-1:0]] <= din;//写入	
end

reg [RAM_AW-1:0] addr_r;//地址寄存器
always @(posedge clk) begin
	if (~we)
		addr_r <= addr[RAM_AW-1:0];//读行为同步
end
assign #0.1 dout = mem_r[addr_r[RAM_AW-1:0]];

endmodule