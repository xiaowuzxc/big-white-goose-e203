module YD_reg (
	input wire clk,  //时钟
	input wire rst,  //高电平同步复位
	input wire jpc,	//高电平可写PC
	input wire dsv, //数据总线访问指示
//输入口0
	input wire [15:0]din0,
	input wire [3:0]waddr0,
	input wire we0,
//输入口1
	input wire [15:0]din1,
	input wire [3:0]waddr1,
	input wire we1,
//输出口0
	input wire [3:0]raddr0,
	output reg [15:0]dout0,//寄存器读取，数据输出线，always@(*)只能给reg赋值
//输出口1
	input wire [3:0]raddr1,
	output reg [15:0]dout1,//寄存器读取，数据输出线，always@(*)只能给reg赋值
//PC输出
	output reg [15:0]PC,//PC值会直接输出
	output reg [15:0]DKD//直接输出DK或写入值
);
//寄存器组定义
reg [15:0]RX[12:0];
reg [15:0]DK;
//内部必要连线
reg [3:0]raddr0_r;//读地址0打一拍
reg [3:0]raddr1_r;//读地址1打一拍
reg [3:0]waddr0_r;//写地址0打一拍
reg [3:0]waddr1_r;//写地址1打一拍
reg we0_r;//写使能0打一拍
reg we1_r;//写使能1打一拍
reg [15:0]din0_r;//写数据0打一拍
reg [15:0]din1_r;//写数据1打一拍
reg [15:0]dout0_r;//寄存器读取，数据输出线，always@(*)只能给reg赋值
reg [15:0]dout1_r;//
//定义寄存器组地址
localparam ZEA=4'b0000;
localparam DKA=4'b0001;
localparam R0A=4'b0010;
//R0-RC依次排列
localparam PCA=4'b1111;

//寄存器写入
always @(posedge clk) begin
if(rst) begin//寄存器复位
	DK <= 16'h0;
	PC <= 16'h0;
	RX[0] <= 16'h0;
	RX[1] <= 16'h0;
	RX[2] <= 16'h0;
	RX[3] <= 16'h0;
	RX[4] <= 16'h0;
	RX[5] <= 16'h0;
	RX[6] <= 16'h0;
	RX[7] <= 16'h0;
	RX[8] <= 16'h0;
	RX[9] <= 16'h0;
	RX[10] <= 16'h0;
	RX[11] <= 16'h0;
	RX[12] <= 16'h0;
	end 
else begin
	if(~jpc && ~dsv)//不跳转
		PC <= PC+16'h1;
	if(we0&&we1&&(waddr0==waddr1)) begin//写地址冲突，优先写端口0
		case(waddr0)
			ZEA:;//ZE永远为0
			DKA:DK <= din0;
			PCA:if(jpc) PC <= din0;//即将跳转
			default:RX[waddr0-R0A] <= din0;
			endcase 
		end
	else begin//无冲突，正常写
		if(we0) begin//端口0写
			case(waddr0)
				ZEA:;
				DKA:DK <= din0;
				PCA:if(jpc) PC <= din0;//即将跳转
				default:RX[waddr0-R0A] <= din0;
				endcase 
			end
		if(we1) begin//端口1写
			case(waddr1)
				ZEA:;
				DKA:DK <= din1;
				PCA:if(jpc) PC <= din1;//即将跳转
				default:RX[waddr1-R0A] <= din1;
				endcase 
			end
		end
	end
end

//寄存器读取
//读地址打一拍
always @(posedge clk) begin
if(rst) begin
	raddr0_r <= 4'h0;
	raddr1_r <= 4'h0;
	waddr0_r <= 4'h0;
	waddr1_r <= 4'h0;
	din0_r <= 16'h0;
	din1_r <= 16'h0;
	we0_r <= 1'b0;
	we1_r <= 1'b0;
	end 
else begin
	raddr0_r <= raddr0;//读地址0打一拍
	raddr1_r <= raddr1;//读地址1打一拍
	waddr0_r <= waddr0;//写地址0打一拍
	waddr1_r <= waddr1;//写地址1打一拍
	din0_r <= din0;//写数据0打一拍
	din1_r <= din1;//写数据1打一拍
	we0_r <= we0;
	we1_r <= we1;
	end
end

//读取寄存器
always @(*) begin
	case (raddr0_r)
		ZEA:dout0=16'h0;
		DKA:
			if ((raddr0_r==waddr0_r&&we0_r)||(raddr0_r==waddr1_r&&we1_r)) //同步写穿
				if(raddr0_r==waddr0_r&&we0_r)
					dout0=din0_r;
				else if(raddr0_r==waddr1_r&&we1_r)
					dout0=din1_r;
				else
					dout0=DK;
			else
				dout0=DK;
		PCA:
			if (((raddr0_r==waddr0_r&&we0_r)||(raddr0_r==waddr1_r&&we1_r))&&jpc) //同步写穿
				if(raddr0_r==waddr0_r&&we0_r)
					dout0=din0_r;
				else if(raddr0_r==waddr1_r&&we1_r)
					dout0=din1_r;
				else
					dout0=PC;
			else
				dout0=PC;
		default:
			if ((raddr0_r==waddr0_r&&we0_r)||(raddr0_r==waddr1_r&&we1_r))//同步写穿
				if(raddr0_r==waddr0_r&&we0_r)
					dout0=din0_r;
				else if(raddr0_r==waddr1_r&&we1_r)
					dout0=din1_r;
				else
					dout0=RX[raddr0_r-R0A];
			else
				dout0=RX[raddr0_r-R0A];
		endcase

	case (raddr1_r)
		ZEA:dout1=16'h0;
		DKA:
			if ((raddr1_r==waddr0_r&&we0_r)||(raddr1_r==waddr1_r&&we1_r)) //同步写穿
				if(raddr1_r==waddr0_r&&we0_r)
					dout1=din0_r;
				else if(raddr1_r==waddr1_r&&we1_r)
					dout1=din1_r;
				else
					dout1=DK;
			else
				dout1=DK;
		PCA:
			if (((raddr1_r==waddr0_r&&we0_r)||(raddr1_r==waddr1_r&&we1_r))&&jpc) //同步写穿
				if(raddr1_r==waddr0_r&&we0_r)
					dout1=din0_r;
				else if(raddr1_r==waddr1_r&&we1_r)
					dout1=din1_r;
				else
					dout1=PC;
			else
				dout1=PC;
		default:
			if ((raddr1_r==waddr0_r&&we0_r)||(raddr1_r==waddr1_r&&we1_r))//同步写穿
				if(raddr1_r==waddr0_r&&we0_r)
					dout1=din0_r;
				else if(raddr1_r==waddr1_r&&we1_r)
					dout1=din1_r;
				else
					dout1=RX[raddr1_r-R0A];
			else
				dout1=RX[raddr1_r-R0A];
		endcase
end

//直接输出DK
always @(*) begin
	DKD=DK;
	if(waddr0==DKA && we0 || waddr1==DKA && we1)//如果同时在写DK
		if(waddr0==DKA && we0)
			DKD=din0;
		else if(waddr1==DKA && we1)
			DKD=din1;
	else
		DKD=DK;
end

/*------- 仅仿真 -------*/
wire [15:0]R0W=RX[0];
wire [15:0]R1W=RX[1];
wire [15:0]R2W=RX[2];
wire [15:0]R3W=RX[3];
wire [15:0]R4W=RX[4];
wire [15:0]R5W=RX[5];
wire [15:0]R6W=RX[6];
wire [15:0]R7W=RX[7];
wire [15:0]R8W=RX[8];
wire [15:0]R9W=RX[9];
wire [15:0]RAW=RX[10];
wire [15:0]RBW=RX[11];
wire [15:0]RCW=RX[12];
/*------- 仅仿真 -------*/
endmodule