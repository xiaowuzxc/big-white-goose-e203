// -----------------------------------------------------------------------------
// 储存器建模，在FPGA上会综合成BRAM
//
// -----------------------------------------------------------------------------
// Copyright (c) 2014-2021 All rights reserved
// -----------------------------------------------------------------------------
// Author : xiaowuzxc
// File   : dbus.v
// Create : 2021-12-10 20:22:39
// Revise : 2021-12-10 20:22:39
// Editor : sublime text3, tab size (4)
// -----------------------------------------------------------------------------
module dbus
#(
	parameter RAM_AW = 7
)(
	input			clk, //时钟
	input			rst,  //同步复位，高电平有效
	input [15:0]	din, //数据输入
	input [15:0]	addr, //地址输入
	input			we, //高电平写使能
	output reg [15:0]	dout, //数据输出
	input wire [15:0]	gpio_in,//输入端口
	output wire [15:0]gpio_out,//输出端口
	output wire T0_PWM_P,//T0_PWM_P
	output wire T0_PWM_N,//T0_PWM_N
	output wire T1_PWM_P,//T1_PWM_P
	output wire T1_PWM_N,//T1_PWM_N
	input wire [3:0]intp_ext,//外部中断
	input wire int_rdy,//中断控制器准备好，1有效
	output wire int_vld//中断触发脉冲输出
);
localparam BKAW=12;
localparam DW = 16;
localparam AW = 16;
/*---------定义区块连线-----------*/
//s0,ram,addr=0000 xxxx xxxx xxxx
localparam s0_bk=4'h0;//区块编号：s<num>_bk=4'h<num>
wire [DW-1:0]s0_dout;//从->主数据通路
reg  [DW-1:0]s0_din;//主->从数据通路
reg  [AW-5:0]s0_addr;//地址通路
reg  s0_we;//高电平写使能
//s1,io,addr=0001 xxxx xxxx xxxx
localparam s1_bk=4'h1;
wire [DW-1:0]s1_dout;
reg  [DW-1:0]s1_din;
reg  [AW-5:0]s1_addr;
reg  s1_we;
//s2,timer,addr=0010 xxxx xxxx xxxx
localparam s2_bk=4'h2;
wire [DW-1:0]s2_dout;
reg  [DW-1:0]s2_din;
reg  [AW-5:0]s2_addr;
reg  s2_we;
//s3,intc,addr=0011 xxxx xxxx xxxx
localparam s3_bk=4'h3;
wire [DW-1:0]s3_dout;
reg  [DW-1:0]s3_din;
reg  [AW-5:0]s3_addr;
reg  s3_we;
/*---------定义区块连线-----------*/

/*---------中断通道配置-----------*/
wire intp_T0;
wire intp_T1;
wire [7:0]intp_i={intp_ext,2'b0,intp_T1,intp_T0};

/*---------中断通道配置-----------*/

/*---------主->从数据通路-----------*/
reg [DW-1:0]dinz;//空闲通路
reg [AW-5:0]addrz;//空闲通路
reg wez;//空闲通路
always @(*) begin
	//默认状态
	s0_din=0;
	s0_addr=0;
	s0_we=0;
	s1_din=0;
	s1_addr=0;
	s1_we=0;
	s2_din=0;
	s2_addr=0;
	s2_we=0;
	s3_din=0;
	s3_addr=0;
	s3_we=0;
	//
	case(addr[AW-1:AW-4])
		s0_bk:begin
			s0_din=din;//主->从数据通路
			s0_addr=addr[AW-5:0];//地址通路
			s0_we=we;//高电平写使能
			end
		s1_bk:begin
			s1_din=din;
			s1_addr=addr[AW-5:0];
			s1_we=we;
			end
		s2_bk:begin
			s2_din=din;
			s2_addr=addr[AW-5:0];
			s2_we=we;
			end
		s3_bk:begin
			s3_din=din;
			s3_addr=addr[AW-5:0];
			s3_we=we;
			end
		default:begin
			dinz=din;
			addrz=addr[AW-5:0];
			wez=we;
			end
	endcase
end
/*---------主->从数据通路-----------*/

/*---------从->主数据通路-----------*/
reg [3:0]bkr;//区块选择寄存器
always @(posedge clk ) begin
	if(rst)
		bkr<=4'h0;
	else
		bkr <= addr[AW-1:AW-4];
end
always @(*) begin
	case(bkr)
		s0_bk:dout=s0_dout;
		s1_bk:dout=s1_dout;
		s2_bk:dout=s2_dout;
		s3_bk:dout=s3_dout;
		default:dout=32'h0;
	endcase
end
/*---------从->主数据通路-----------*/


ram #(
	.DW(16),
	.AW(BKAW),
	.RAM_AW(RAM_AW)
)u_ram(
	.clk     (clk),
	.rst     (rst),
	.din     (s0_din),
	.addr    (s0_addr),
	.we      (s0_we),
	.dout    (s0_dout)
);

io #(
	.DW(16),
	.AW(BKAW)
)u_io(
	.clk     (clk),
	.rst     (rst),
	.din     (s1_din),
	.addr    (s1_addr),
	.we      (s1_we),
	.dout    (s1_dout),
	.gpio_in (gpio_in),
	.gpio_out(gpio_out)
);

timer #(
	.DW(16),
	.AW(BKAW)
)u_timer(
	.clk     (clk),
	.rst     (rst),
	.din     (s2_din),
	.addr    (s2_addr),
	.we      (s2_we),
	.dout    (s2_dout),
	.T0_PWM_P(T0_PWM_P),
	.T0_PWM_N(T0_PWM_N),
	.T1_PWM_P(T1_PWM_P),
	.T1_PWM_N(T1_PWM_N),
	.intp_T0 (intp_T0),
	.intp_T1 (intp_T1)
);

intc #(
	.DW(16),
	.AW(BKAW)
)u_intc (
	.clk     (clk),
	.rst     (rst),
	.din     (s3_din),
	.addr    (s3_addr),
	.we      (s3_we),
	.dout    (s3_dout),
	.intp_i  (intp_i),
	.int_rdy (int_rdy),
	.int_vld (int_vld)
);

endmodule