module timer
#(
	parameter DW = 16,
	parameter AW = 12 
)(
	input			clk, //时钟
	input			 rst,  //同步复位，高电平有效
	input [DW-1:0]	din, //数据输入
	input [AW-1:0]	addr, //地址输入
	input			we, //高电平写使能
	output reg[DW-1:0] dout, //数据输出
	output reg T0_PWM_P,//输入端口
	output reg T0_PWM_N,//输入端口
	output reg T1_PWM_P,//输出端口
	output reg T1_PWM_N,//输出端口
	output reg intp_T0,//定时器T0[0]溢出中断，[1]比较中断
	output reg intp_T1//定时器T1[0]溢出中断，[1]比较中断
);
/*
定时器T0/T1
---------------------------------------
向上计数模式
计数器TCNTx达到上溢值TATSx，装入影子寄存器
计数值TCNTx小于比较值TCMPx，Tx_PWM_P为初始极性
计数值TCNTx越过比较值TCMPx后，Tx_PWM发生翻转
Tx_PWM_P与Tx_PWM_N为差分信号
---------------------------------------
控制寄存器TCTR
低8位[7:0]控制T0，高8位[15:8]控制T1
[0]启动控制：置1开始计数，置0停止并复位
[1]极性控制：计数值大于比较值时，Tx_PWM_P=[1]
---------------------------------------
分频器：
				|->T0
	clk->|div|--|
				|->T1
系统时钟送入分配器，分频器输出作为T0/T1的时钟源。
分频器计算公式 Fdiv=(N+1)F
Fdiv：分配器输出频率
  N ：分频系数TDIV
  F ：系统时钟频率
---------------------------------------
影子寄存器
TDIV，TATSx，TCMPx有影子寄存器。
其作用是在分频器、定时器溢出时将设定值写入，防止计数器跑飞。
---------------------------------------
定时器中断  
定时器T0/T1发生溢出，会触发一次中断。  
---------------------------------------
*/

//地址定义
localparam TCTR_A = 12'h00;//定时器控制寄存器
localparam TDIV_A = 12'h01;//定时器分频系数寄存器
localparam TATS0_A = 12'h02;//定时器0上溢寄存器
localparam TCMP0_A = 12'h03;//定时器0比较值寄存器
localparam TCNT0_A = 12'h04;//定时器0当前值
localparam TATS1_A = 12'h05;//定时器1上溢寄存器
localparam TCMP1_A = 12'h06;//定时器1比较值寄存器
localparam TCNT1_A = 12'h07;//定时器1当前值
//寄存器定义
reg[15:0]TCTR;
reg[15:0]TDIV;
reg[15:0]TDIV_r;//影子寄存器
reg[15:0]TATS0;
reg[15:0]TATS0_r;//影子寄存器
reg[15:0]TCMP0;
reg[15:0]TCMP0_r;//影子寄存器
reg[15:0]TCNT0;
reg[15:0]TATS1;
reg[15:0]TATS1_r;//影子寄存器
reg[15:0]TCMP1;
reg[15:0]TCMP1_r;//影子寄存器
reg[15:0]TCNT1;
reg DIV_EN;//分频器输出使能
reg [15:0]DIV_CNT;//分频器计数器

//分频器
always @(posedge clk) begin
	if(rst) begin
		DIV_CNT<=16'h0;
		TDIV_r<=16'h0;
		end
	else begin
		if(DIV_CNT==TDIV_r) begin//分频器溢出
			DIV_EN<=1'b1;//输出使能信号
			DIV_CNT<=16'h0;
			if(TDIV_r!=TDIV)//写入影子寄存器
				TDIV_r<=TDIV;
			end
		else begin//分频器计数+1
			DIV_CNT<=DIV_CNT+1;//计数器+1
			DIV_EN<=1'b0;
			end
		end
end

always @(posedge clk) begin
if(rst) begin
	TCTR <= 16'h0;
	TDIV <= 16'h0;
	TATS0 <= 16'h0;
	TATS1 <= 16'h0;
	TCMP0 <= 16'h0;
	TCMP1 <= 16'h0;
	dout <= 16'h0;
end	
else
	if(we)
		case (addr)//数据总线写入
			TCTR_A: TCTR <= din;
			TDIV_A: TDIV <= din;
			TATS0_A: TATS0 <= din;
			TCMP0_A: TCMP0 <= din;
			TATS1_A: TATS1 <= din;
			TCMP1_A: TCMP1 <= din;
			default: ;
		endcase
	else begin
		case (addr)//数据总线读取
			TCTR_A: dout <= TCTR;
			TCNT0_A: dout <= TCNT0;
			TCNT1_A: dout <= TCNT1;
			default: dout <= 16'h0;
		endcase
		end
end

//计数器控制
always @(posedge clk) begin
if(rst) begin
	TCNT0 <= 16'h0;
	TCNT1 <= 16'h0;
	intp_T0 <= 1'b0;
	intp_T1 <= 1'b0;
	end	
else begin
	if(TCTR[0]) begin//T0
		if(TCNT0==TATS0_r) begin//定时器溢出
			TCNT0 <= 16'h0;//置0
			intp_T0 <= 1'b1;//T0溢出中断
			TATS0_r <= TATS0;//写影子寄存器
			TCMP0_r <= TCMP0;//写影子寄存器
			end
		else begin
			TCNT0 <= TCNT0+1;//定时器+1
			intp_T0 <= 1'b0;
			end
		end
	else begin//停止状态
		TCNT0 <= 16'h0;
		intp_T0 <= 1'b0;
		TATS0_r <= TATS0;
		TCMP0_r <= TCMP0;
		end
	if(TCTR[8]) begin//T1
		if(TCNT1==TATS1_r) begin//定时器溢出
			TCNT1 <= 16'h0;//置0
			intp_T1 <= 1'b1;//T1溢出中断
			TATS1_r <= TATS1;//写影子寄存器
			TCMP1_r <= TCMP1;//写影子寄存器
			end
		else begin
			TCNT1 <= TCNT1+1;//定时器+1
			intp_T0 <= 1'b0;
			end
		end
	else begin//停止状态
		TCNT1 <= 16'h0;
		intp_T0 <= 1'b0;
		TATS1_r <= TATS1;
		TCMP1_r <= TCMP1;
		end
	end
end

//PWM产生
always @(*) begin
if(TCNT0<=TCMP0_r) begin
	T0_PWM_P = TCTR[1];
	T0_PWM_N = ~TCTR[1];
	end
else begin
	T0_PWM_P = ~TCTR[1];
	T0_PWM_N = TCTR[1];
	end
if(TCNT1<=TCMP1_r) begin
	T1_PWM_P = TCTR[9];
	T1_PWM_N = ~TCTR[9];
	end
else begin
	T1_PWM_P = ~TCTR[9];
	T1_PWM_N = TCTR[9];
	end
end
endmodule