module YD_int
(
	input		wire	clk, //时钟
	input		wire	rst,  //同步复位，高电平有效
	//int
	input 	wire int_vld, //中断脉冲输入，1周期高脉冲表示中断发生
	output 	reg int_rdy, //数据输出，高电平可以接受中断，低电平无法响应
	//
	input wire[15:0]PC, //下一条指令的地址
	input wire jpc, //跳转指示
	output reg int_jpc, //输出的跳转指示
	output reg inp,//插入NOP指示，异步作用
	//接管寄存器组写端口
	//输入口0
	input wire [15:0]din0,
	input wire [3:0]waddr0,
	input wire we0,
	//输入口1
	input wire [15:0]din1,
	input wire [3:0]waddr1,
	input wire we1,
	//输入口0
	output reg [15:0]int_din0,
	output reg [3:0]int_waddr0,
	output reg int_we0,
	//输入口1
	output reg [15:0]int_din1,
	output reg [3:0]int_waddr1,
	output reg int_we1
);
/*
非向量中断控制器
无中断，int_rdy=1,寄存器端口旁路
发生中断
0：int_vld=1，PC暂存，int_rdy=0
1：inp=1，插入NOP
2：接管寄存器端口，PC-r->RC，16'h0004->PC
3：NOP
4：inp=0，int_rdy=1
*/
//有限序列机
reg [2:0]state;//状态寄存器
reg sen;//序列机工作使能
localparam IDLE=3'h0;//等待状态
localparam CPL=3'h1;//清空流水线
localparam WBK=3'h2;//写返回地址，PC跳转
localparam RIN=3'h3;//指令读出前，插NOP
localparam IED=3'h4;//结束，复位控制器
//寄存器
reg [15:0]PC_r;
//状态转移控制
always @(posedge clk) begin
	if(rst) begin
		sen <= 1'b0;
		state <= 3'h0;
		end 
	else begin
		if(int_vld) begin//中断脉冲
			sen <= 1'b1;//启动序列机
			state <= CPL;//直接转移到CPL
			PC_r <= PC;
			end
		if(sen)//中断启动
			if(state<IED)//到达结束状态前
				state <= state+1;//进入下一个状态
			else begin//到达最终状态
				state <= IDLE;//复位
				sen <= 1'b0;
				end
		else//多余状态复位
			if(state!=IDLE)
				state <= IDLE;
		end
end

//输出控制，组合逻辑部分
always @(*) begin
	if(rst) begin
		//寄存器端口旁路
		int_din0=din0;
		int_waddr0=waddr0;
		int_we0=we0;
		int_din1=din1;
		int_waddr1=waddr1;
		int_we1=we1;
		//可中断
		int_rdy=1;
		//插入空指令
		inp=0;
		//jpc
		int_jpc=jpc;
		end 
	else begin
		case (state)
			IDLE: begin//等待状态
				//寄存器端口旁路
				int_din0=din0;
				int_waddr0=waddr0;
				int_we0=we0;
				int_din1=din1;
				int_waddr1=waddr1;
				int_we1=we1;
				//可中断
				int_rdy=1;
				//插入空指令
				inp=0;
				//jpc
				int_jpc=jpc;
				end
			CPL: begin//清空流水线
				//寄存器端口旁路
				int_din0=din0;
				int_waddr0=waddr0;
				int_we0=we0;
				int_din1=din1;
				int_waddr1=waddr1;
				int_we1=we1;
				//中断进行中
				int_rdy=0;
				//插入空指令
				inp=1;
				//jpc
				int_jpc=jpc;
				end
			WBK: begin//写返回地址，PC跳转
				//寄存器端口旁路
				int_din0=PC_r;//写返回地址
				int_waddr0=4'b1110;
				int_we0=1;
				int_din1=16'h0004;//PC跳转
				int_waddr1=4'b1111;
				int_we1=1;
				//中断进行中
				int_rdy=0;
				//插入空指令
				inp=1;
				//jpc
				int_jpc=1;
				end
			RIN: begin//指令读出前，插NOP
				//寄存器端口旁路
				int_din0=din0;
				int_waddr0=waddr0;
				int_we0=we0;
				int_din1=din1;
				int_waddr1=waddr1;
				int_we1=we1;
				//中断进行中
				int_rdy=0;
				//插入空指令
				inp=1;
				//jpc
				int_jpc=jpc;
				end
			IED: begin//结束，复位控制器
				//寄存器端口旁路
				int_din0=din0;
				int_waddr0=waddr0;
				int_we0=we0;
				int_din1=din1;
				int_waddr1=waddr1;
				int_we1=we1;
				//中断进行中
				int_rdy=0;
				//插入空指令
				inp=0;
				//jpc
				int_jpc=jpc;
				end
			default: begin
				//寄存器端口旁路
				int_din0=din0;
				int_waddr0=waddr0;
				int_we0=we0;
				int_din1=din1;
				int_waddr1=waddr1;
				int_we1=we1;
				//可中断
				int_rdy=1;
				//插入空指令
				inp=0;
				//jpc
				int_jpc=jpc;
				end
		endcase
		end
end


endmodule