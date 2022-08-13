module intc
#(
	parameter DW = 16,
	parameter AW = 13 
)(
	input			clk, //时钟
	input			 rst,  //同步复位，高电平有效
	input [DW-1:0]	din, //数据输入
	input [AW-1:0]	addr, //地址输入
	input			we, //高电平写使能
	output reg[DW-1:0] dout, //数据输出
	input wire[7:0]intp_i,//中断通道输入
	input wire int_rdy,//中断控制器准备好，1有效
	output reg int_vld//中断触发脉冲输出
);
/*
中断管理器
---------------------------------------
非向量中断
管理来自外部接口/外设的8个中断通道intp_i，经过处理和仲裁后送入处理器。
中断可以根据需求，配置成低电平、高电平、上升沿、下降沿触发。
来自SoC内部的外设中断通道必须配置成高电平或上升沿触发。
---------------------------------------
中断有2个优先级，优先级相同情况下，优先触发低位中断。
中断触发后，中断号送入INTC[10:8]
---------------------------------------
*/
localparam INTC_A=12'h0;//中断全局配置
localparam INT0_A=12'h1;//中断0123配置
localparam INT1_A=12'h2;//中断4567配置

reg [10:0]INTC;//中断全局配置寄存器
//INTC[0]0:全局中断关，1:全局中断开
//INTC[10:8]上一次成功中断的中断号
reg [15:0]INT0;//中断0123配置寄存器
/*配置说明
INT0[3:0]中断0配置
INT0[0]0:中断关，1:中断开
INT0[1]0:高优先级，1:低优先级
INT0[3:2]触发方式配置，00:高电平，01低电平，10上升沿，11下降沿
INT1[7:4]中断1配置
INT1[4]0:中断关，1:中断开
INT1[5]0:高优先级，1:低优先级
INT1[7:6]触发方式配置，00:高电平，01低电平，10上升沿，11下降沿
INT2[11:8]中断2配置
INT2[8]0:中断关，1:中断开
INT2[9]0:高优先级，1:低优先级
INT2[11:10]触发方式配置，00:高电平，01低电平，10上升沿，11下降沿
INT3[15:12]中断3配置
INT3[12]0:中断关，1:中断开
INT3[13]0:高优先级，1:低优先级
INT3[15:14]触发方式配置，00:高电平，01低电平，10上升沿，11下降沿
*/
reg [16:0]INT1;//中断4567配置寄存器
/*配置说明
INT4[3:0]中断4配置
INT4[0]0:中断关，1:中断开
INT4[1]0:高优先级，1:低优先级
INT4[3:2]触发方式配置，00:高电平，01低电平，10上升沿，11下降沿
INT5[7:4]中断5配置
INT5[4]0:中断关，1:中断开
INT5[5]0:高优先级，1:低优先级
INT5[7:6]触发方式配置，00:高电平，01低电平，10上升沿，11下降沿
INT6[11:8]中断6配置
INT6[8]0:中断关，1:中断开
INT6[9]0:高优先级，1:低优先级
INT6[11:10]触发方式配置，00:高电平，01低电平，10上升沿，11下降沿
INT7[15:12]中断7配置
INT7[12]0:中断关，1:中断开
INT7[13]0:高优先级，1:低优先级
INT7[15:14]触发方式配置，00:高电平，01低电平，10上升沿，11下降沿
*/
//中断配置寄存器合并
wire [31:0]INTA={INT1,INT0};

//寄存器定义
reg [7:0]intp_i_r;//中断通道打一拍
reg [7:0]intp_i_rr;//中断通道打两拍
reg [7:0]intp_c;//经过通道开关的信号
reg [7:0]intp_tg;//经过触发配置的信号
reg [7:0]intp_h;//高优先级中断通道
reg intp_ht;//高优先级中断输出
reg [2:0]intp_hn;//高优先级中断号
reg [7:0]intp_l;//低优先级中断通道
reg intp_lt;//低优先级中断输出
reg [2:0]intp_ln;//低优先级中断号

//总线对接
always @(posedge clk) begin
if(rst) begin
	INTC[7:0] <= 8'h0;
	INT0 <= 16'h0;
	INT1 <= 16'h0;
	dout <= 16'h0;
	end	
else begin
	if(we)
		case (addr)//数据总线写入
			INTC_A: #0.1 INTC[7:0] <= din[7:0];
			INT0_A: #0.1 INT0 <= din;
			INT1_A: #0.1 INT1 <= din;
			default: ;
		endcase
	else begin
		case (addr)//数据总线读取
			INTC_A: #0.1 dout <= INTC;
			INT0_A: #0.1 dout <= INT0;
			INT1_A: #0.1 dout <= INT1;
			default: dout <= 16'h0;
		endcase
		end
	end
end

//中断通道开关，关闭的通道会恒为0
integer j;
always @(*) begin
	for(j=0;j<=7;j=j+1)
		intp_c[j]=INTA[4*j]?intp_i[j]:1'b0;
end

//中断通道打拍
always @(posedge clk) begin
if(rst) begin
	intp_i_r <= 16'h0;
	intp_i_rr <= 16'h0;
	end	
else begin
	intp_i_r <= intp_c;
	intp_i_rr <= intp_i_r;
	end
end

//中断触发方式控制
always @(*) begin
	for(j=0;j<=7;j=j+1) begin
		case ({INTA[4*j+3],INTA[4*j+2]})
			2'b00: intp_tg[j]=intp_i_r[j];
			2'b01: intp_tg[j]=~intp_i_r[j];
			2'b10: intp_tg[j]=(intp_i_r[j] && ~intp_i_rr[j])?1'b1:1'b0;
			2'b11: intp_tg[j]=(~intp_i_r[j] && intp_i_rr[j])?1'b1:1'b0;
		endcase
		end
end

//中断优先级控制
always @(*) begin
	for(j=0;j<=7;j=j+1) begin
		if(INTA[4*j+1]) begin
			intp_h[j]=1'b0;
			intp_l[j]=intp_tg[j];
			end
		else begin
			intp_h[j]=intp_tg[j];
			intp_l[j]=1'b0;
			end
		end
end

//同等优先级，按中断号由小到大触发中断
//高优先级
always @(*) begin
	if(intp_h[0]) begin
		intp_ht=1'b1;
		intp_hn=3'h0;
		end
	else if(intp_h[1]) begin
		intp_ht=1'b1;
		intp_hn=3'h1;
		end
	else if(intp_h[2]) begin
		intp_ht=1'b1;
		intp_hn=3'h2;
		end
	else if(intp_h[3]) begin
		intp_ht=1'b1;
		intp_hn=3'h3;
		end
	else if(intp_h[4]) begin
		intp_ht=1'b1;
		intp_hn=3'h4;
		end
	else if(intp_h[5]) begin
		intp_ht=1'b1;
		intp_hn=3'h5;
		end
	else if(intp_h[6]) begin
		intp_ht=1'b1;
		intp_hn=3'h6;
		end
	else if(intp_h[7]) begin
		intp_ht=1'b1;
		intp_hn=3'h7;
		end
	else begin
		intp_ht=1'b0;
		intp_hn=3'h0;
		end
end
//低优先级
always @(*) begin
	if(intp_l[0]) begin
		intp_lt=1'b1;
		intp_ln=3'h0;
		end
	else if(intp_h[1]) begin
		intp_lt=1'b1;
		intp_ln=3'h1;
		end
	else if(intp_h[2]) begin
		intp_lt=1'b1;
		intp_ln=3'h2;
		end
	else if(intp_h[3]) begin
		intp_lt=1'b1;
		intp_ln=3'h3;
		end
	else if(intp_h[4]) begin
		intp_lt=1'b1;
		intp_ln=3'h4;
		end
	else if(intp_h[5]) begin
		intp_lt=1'b1;
		intp_ln=3'h5;
		end
	else if(intp_h[6]) begin
		intp_lt=1'b1;
		intp_ln=3'h6;
		end
	else if(intp_h[7]) begin
		intp_lt=1'b1;
		intp_ln=3'h7;
		end
	else begin
		intp_lt=1'b0;
		intp_ln=3'h0;
		end
end

//向内核输出中断触发信号
always @(posedge clk) begin
	if(rst) begin
		int_vld <= 1'b0;
		INTC[10:8] <= 3'h0;
		end 
	else begin
		if(INTC[0]) begin
			if(intp_ht) begin
				int_vld <= 1'b1;
				INTC[10:8] <= intp_hn;
				end
			else if(intp_lt) begin
				int_vld <= 1'b1;
				INTC[10:8] <= intp_ln;
				end
			else begin
				int_vld <= 1'b0;
				INTC[10:8] <= 3'h0;
				end
			end
		else begin
			int_vld <= 1'b0;
			INTC[10:8] <= 3'h0;
			end
		end
end

endmodule