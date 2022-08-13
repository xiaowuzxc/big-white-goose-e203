`include "e203_defines.v"
module Yduck_SoC (
	input wire clk,    // 时钟输入
	input wire rst,  // 同步复位，高电平有效
	//IO
	input wire [15:0]gpio_in,//输入端口
	output wire [15:0]gpio_out,//输出端口
	//PWM
	output wire T0_PWM_P,//T0_PWM_P
	output wire T0_PWM_N,//T0_PWM_N
	output wire T1_PWM_P,//T1_PWM_P
	output wire T1_PWM_N,//T1_PWM_N
	//中断
	input wire [3:0]intp_ext,//外部中断
	input wire intp_s //强制中断

);
parameter RAM_AW=7;
parameter ROM_AW=7;

//连接E203 SRAM
wire [`E203_DTCM_RAM_AW-2:0]e203_addr;
wire [32-1:0]e203_dout;
reg addr_r;//最低位打一拍
always @(posedge clk) begin
	if(rst)
		addr_r<=0;
	else
		addr_r<=i_addr[0];
end
assign e203_addr=i_addr[15:1];
assign i_dout=addr_r?e203_dout[31:16]:e203_dout[15:0];
//
wire [15:0]i_addr,i_dout,d_din,d_addr,d_dout;
wire d_we;
wire int_rdy,int_vld;
YD_core u_YD_core
(
	.clk    (clk),
	.rst    (rst),
	.i_addr (i_addr),
	.i_dout (i_dout),
	.d_din  (d_din),
	.d_addr (d_addr),
	.d_we   (d_we),
	.d_dout (d_dout),
	.int_vld(int_vld|intp_s),
	.int_rdy(int_rdy)
);
dbus #(
	.RAM_AW(RAM_AW)
) u_dbus (
	.clk      (clk),
	.rst      (rst),
	.din      (d_din),
	.addr     (d_addr),
	.we       (d_we),
	.dout     (d_dout),
	.gpio_in  (gpio_in),
	.gpio_out (gpio_out),
	.T0_PWM_P(T0_PWM_P),//T0_PWM_P
	.T0_PWM_N(T0_PWM_N),//T0_PWM_N
	.T1_PWM_P(T1_PWM_P),//T1_PWM_P
	.T1_PWM_N(T1_PWM_N),//T1_PWM_N
	.intp_ext(intp_ext),
	.int_rdy (int_rdy),
	.int_vld (int_vld)
);
/*
ibus #(
	.ROM_AW(ROM_AW)
) u_ibus (
	.clk(clk), 
	.addr(i_addr), 
	.dout(i_dout)
);
*/
endmodule