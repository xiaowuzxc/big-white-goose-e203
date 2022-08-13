// -----------------------------------------------------------------------------
// 储存器建模，在FPGA上会综合成BRAM
// 指令存储器，只读
// -----------------------------------------------------------------------------
// Copyright (c) 2014-2021 All rights reserved
// -----------------------------------------------------------------------------
// Author : xiaowuzxc
// File   : ibus.v
// Create : 2021-12-10 20:13:36
// Revise : 2021-12-10 20:13:36
// Editor : sublime text3, tab size (4)
// -----------------------------------------------------------------------------
module ibus
#(

	parameter ROM_AW = 7
)(
	input			clk, //时钟
	input [15:0]	addr, //地址输入
	output wire [15:0] dout //数据输出
    );
localparam DW = 16;
localparam AW = 16;

reg [DW-1:0] mem_r [(2**ROM_AW)-1:0];//内存定义

wire [DW-1:0] dout_pre;
reg [AW-1:0] addr_r;//地址寄存器


always @(posedge clk) begin
		addr_r <= addr;//读行为同步
end

assign #0.1 dout = mem_r[addr_r];//读取

initial begin
    $readmemb("../../tools/asm/obj.txt",mem_r,0,(2**ROM_AW)-1);//可以被综合
end

endmodule