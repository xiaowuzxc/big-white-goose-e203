module YD_core
(
	input		wire	clk, //时钟
	input		wire	rst,  //同步复位，高电平有效
	//ibus
	output 	wire[15:0]	i_addr, //地址输入
	input 	wire[15:0]	i_dout, //数据输出
	//dbus
	output	reg[15:0]	d_din, //数据输入
	output 	reg[15:0]	d_addr, //地址输入
	output	reg 		d_we, //高电平写使能
	input 	wire[15:0]	d_dout, //数据输出
	//中断控制
	input 	wire int_vld, //中断脉冲输入，1周期高脉冲表示中断发生
	output 	wire int_rdy //数据输出，高电平可以接受中断，低电平无法响应
);
//寄存器定义
reg rst_r;//复位打一拍
reg jpc,jpc_r;//跳转指示，打一拍
reg dwi;//数据空间写指示，插入NOP
reg dsv_0;
reg dsv_1;
reg dsw;//双发射1级指示
reg dsw_r;//双发射2级指示
reg [15:0]idata;//第一阶段指令
reg [15:0]idata_r;//指令寄存
reg [15:0]din0;
reg [3:0]waddr0;
reg we0;
reg [15:0]din1;
reg [3:0]waddr1;
reg we1;
reg [3:0]raddr0;
reg [3:0]raddr1;
reg [15:0]d_addr_d0;//指令解码阶段通道0，读/写数据空间地址
reg [15:0]d_addr_d1;//指令解码阶段通道1，读/写数据空间地址
reg [15:0]d_addr_z0;//指令执行阶段通道0，读/写数据空间地址
reg [15:0]d_addr_z1;//指令执行阶段通道1，读/写数据空间地址
reg [15:0]d_din_z0;//指令执行阶段通道0，写数据空间数据
reg [15:0]d_din_z1;//指令执行阶段通道1，写数据空间数据
reg d_we_z0;//指令执行阶段通道0，写数据空间使能
reg d_we_z1;//指令执行阶段通道1，写数据空间使能

//线网定义
wire [15:0]dout0;
wire [15:0]dout1;
wire [15:0]DKD;//直接输出DK或写入值
wire inp;
wire [15:0]int_din0;
wire [3:0]int_waddr0;
wire int_we0;
wire [15:0]int_din1;
wire [3:0]int_waddr1;
wire int_we1;
//内部参数定义


//指令操作码定义
localparam NF=4'b0000;	//逻辑非	RG=~RG
localparam LD=4'b0001;	//加载	RG=[DK]
localparam SV=4'b0010;	//存储	[DK]=RG
localparam IN=4'b0011;	//寄存器+1	RG=RG+1
localparam SW=4'b0100;	//寄存器交换	RG={[7:0]RG,[15:8]RG}
localparam WR=4'b0101;	//寄存器转移	RG2=RG1
localparam CR=4'b0110;	//比较	DK=RG1>RG2 ? 1 : 0
localparam LA=4'b0111;	//逻辑与	DK=RG1&RG2
localparam LO=4'b1000;	//逻辑或	DK=RG1|RG2
localparam AD=4'b1001;	//加法	DK=DK+RG+$H
localparam SB=4'b1010;	//减法	DK=DK-RG-$H
localparam JW=4'b1011;	//非0跳转	DK!=0，则跳转到RG+$H
localparam JA=4'b1100;	//无条件跳转	跳转到RG+$H
localparam LL=4'b1101;	//逻辑左移	DK左移RG+$H次，低位补0
localparam LR=4'b1110;	//逻辑右移	DK右移RG+$H次，高位补0
localparam TL=4'b1111;	//循环左移	DK循环左移RG+$H

//定义寄存器组地址
localparam ZEA=4'b0000;
localparam DKA=4'b0001;
localparam R0A=4'b0010;
//R0-RC依次排列
localparam PCA=4'b1111;

//跳转则填充一次流水线
always @(*) begin
	if(jpc|jpc_r|dwi|inp)
		idata=16'h0;
	else
		idata=i_dout;
end

//指令打一拍
always @(posedge clk) begin
	if(rst_r)
		idata_r <= 16'h0;
	else
		idata_r <= idata;
end

always @(posedge clk) rst_r <= rst;//复位信号打一拍

//指令译码0，生成读地址
always @(*) begin
	raddr0=4'h0;
	d_addr_d0=16'h0;
	dsv_0=1'b0;
	dsv_1=1'b0;
	raddr1=4'h0;
	d_addr_d1=16'h0;
	case (idata[15:12])
		NF:begin//RG=~RG
			dsw=1'b1;//当前为8b指令
			raddr0=idata[11:8];
			end
		LD:begin//RG=[DK]
			dsw=1'b1;
			d_addr_d0=DKD;//数据空间没有动作
			end
		SV:begin//[DK]=RG
			dsw=1'b1;
			raddr0=idata[11:8];
			dsv_0=1'b1;//数据写指示
			end
		IN:begin//RG=RG+1
			dsw=1'b1;
			raddr0=idata[11:8];
			end
		SW:begin//RG={RG[7:0],RG[15:8]}
			dsw=1'b1;
			raddr0=idata[11:8];
			end
		WR:begin//RG2=RG1
			dsw=1'b0;//当前为16b指令
			raddr0=idata[11:8];
			raddr1=idata[7:4];
			end
		CR:begin//DK=RG1>RG2?1:0
			dsw=1'b0;
			raddr0=idata[11:8];
			raddr1=idata[7:4];
			end
		LA:begin//DK=RG1 & RG2
			dsw=1'b0;
			raddr0=idata[11:8];
			raddr1=idata[7:4];
			end
		LO:begin//DK=RG1 | RG2
			dsw=1'b0;
			raddr0=idata[11:8];
			raddr1=idata[7:4];
			end
		AD:begin//DK=DK+RG+$H
			dsw=1'b0;
			raddr0=idata[11:8];
			raddr1=DKA;
			end
		SB:begin//DK=DK-RG-$H
			dsw=1'b0;
			raddr0=idata[11:8];
			raddr1=DKA;
			end
		JW:begin//DK!=0?跳转到RG+$H:顺序
			dsw=1'b0;
			raddr0=idata[11:8];
			raddr1=DKA;
			end
		JA:begin//跳转到RG+$H
			dsw=1'b0;
			raddr0=idata[11:8];
			end
		LL:begin//DK逻辑左移RG+$H次
			dsw=1'b0;
			raddr0=idata[11:8];
			raddr1=DKA;
			end
		LR:begin//DK逻辑右移RG+$H次
			dsw=1'b0;
			raddr0=idata[11:8];
			raddr1=DKA;
			end
		TL:begin//DK循环左RG=0/右RG!=0移1次
			dsw=1'b0;
			raddr0=idata[11:8];
			raddr1=DKA;
			end
	endcase
//指令译码1，生成读地址
	if(dsw) begin
		case (idata[7:4])
			NF:raddr1=idata[3:0];
			LD:d_addr_d1=DKD;
			SV: begin raddr1=idata[3:0]; dsv_1=1'b1; end//数据写指示
			IN:raddr1=idata[3:0];
			SW:raddr1=idata[3:0];
		endcase
		end
end

//指令执行1，生成写地址数据
always @(*) begin
	d_din_z0=16'h0;
	d_addr_z0=16'h0;
	d_we_z0=1'b0;
	d_din_z1=16'h0;
	d_addr_z1=16'h0;
	d_we_z1=1'b0;
	din0=16'h0;
	waddr0=4'h0;
	we0=1'b0;
	din1=16'h0;
	waddr1=4'h0;
	we1=1'b0;
	case (idata_r[15:12])
		NF:begin//RG=~RG
			dsw_r=1'b1;//当前为8b指令
			din0=~dout0;
			waddr0=idata_r[11:8];
			we0=1'b1;
			end
		LD:begin//RG=[DK]
			dsw_r=1'b1;
			din0=d_dout;
			waddr0=idata_r[11:8];
			we0=1'b1;
			end
		SV:begin//[DK]=RG
			dsw_r=1'b1;
			d_din_z0=dout0;
			d_addr_z0=DKD;
			d_we_z0=1'b1;
			end
		IN:begin//RG=RG+1
			dsw_r=1'b1;
			din0=dout0+1;
			waddr0=idata_r[11:8];
			we0=1'b1;
			end
		SW:begin//RG={RG[7:0],RG[15:8]}
			dsw_r=1'b1;
			din0={dout0[7:0],dout0[15:8]};
			waddr0=idata_r[11:8];
			we0=1'b1;
			end
		WR:begin//RG2=RG1
			dsw_r=1'b0;//当前为16b指令
			din0=dout0;
			waddr0=idata_r[7:4];
			we0=1'b1;
			end
		CR:begin//DK=RG1>RG2?1:0
			dsw_r=1'b0;
			din0=dout0>dout1?16'h1:16'h0;
			waddr0=DKA;
			we0=1'b1;
			end
		LA:begin//DK=RG1 & RG2
			dsw_r=1'b0;
			din0=dout0&dout1;
			waddr0=DKA;
			we0=1'b1;
			end
		LO:begin//DK=RG1 | RG2
			dsw_r=1'b0;
			din0=dout0|dout1;
			waddr0=DKA;
			we0=1'b1;
			end
		AD:begin//DK=DK+RG+$H
			dsw_r=1'b0;
			din0=dout1+dout0+{8'h0,idata_r[7:0]};
			waddr0=DKA;
			we0=1'b1;
			end
		SB:begin//DK=DK-RG-$H
			dsw_r=1'b0;
			din0=dout1-dout0-{8'h0,idata_r[7:0]};
			waddr0=DKA;
			we0=1'b1;
			end
		JW:begin//DK!=0?跳转到RG+$H:顺序
			dsw_r=1'b0;
			din0=(dout1!=16'h0)?dout0+{8'h0,idata_r[7:0]}:16'h0;
			waddr0=(dout1!=16'h0)?PCA:4'h0;
			we0=(dout1!=16'h0)?1'b1:1'b0;
			end
		JA:begin//跳转到RG+$H
			dsw_r=1'b0;
			din0=dout0+{8'h0,idata_r[7:0]};
			waddr0=PCA;
			we0=1'b1;
			end
		LL:begin//DK逻辑左移RG+$H次
			dsw_r=1'b0;
			din0=dout1<<(dout0[3:0]+idata_r[3:0]);
			waddr0=DKA;
			we0=1'b1;
			end
		LR:begin//DK逻辑右移RG+$H次
			dsw_r=1'b0;
			din0=dout1>>(dout0[3:0]+idata_r[3:0]);
			waddr0=DKA;
			we0=1'b1;
			end
		TL:begin//DK循环左RG=0/右RG!=0移1次
			dsw_r=1'b0;
			if(idata_r[0])
				if(idata_r[1]==1'b0)
					din0={dout1[14:0],dout1[15]};
				else
					din0={dout1[0],dout1[15:1]};
			else
				if(dout0==16'h0)
					din0={dout1[14:0],dout1[15]};
				else
					din0={dout1[0],dout1[15:1]};
			waddr0=DKA;
			we0=1'b1;
			end
	endcase
//指令执行1，生成写地址数据
	if(dsw_r) begin
		case (idata[7:4])
			NF:begin//RG=~RG
				din1=~dout1;
				waddr1=idata_r[3:0];
				we1=1'b1;
				end
			LD:begin//RG=[DK]
				din1=d_dout;
				waddr1=idata_r[3:0];
				we0=1'b1;
				end
			SV:begin//[DK]=RG
				d_din_z1=dout1;
				d_addr_z1=DKD;
				d_we_z1=1'b1;
				end
			IN:begin//RG=RG+1
				din1=dout1+1;
				waddr1=idata_r[3:0];
				we1=1'b1;
				end
			SW:begin//RG={RG[7:0],RG[15:8]}
				din1={dout1[7:0],dout1[15:8]};
				waddr1=idata_r[3:0];
				we1=1'b1;
				end
		endcase
	end
end

//内部数据寄存
always @(posedge clk) begin
	if(rst_r) begin
		dwi <= 1'b0;
		jpc <= 1'b0;
		jpc_r <= 1'b0;
		end 
	else begin
		jpc_r <= jpc;
		if(idata[15:12]==JA || idata[15:12]==JW)
			jpc <= 1'b1;
		else
			jpc <= 1'b0;
		if((idata[15:12]==SV || idata[7:4]==SV) && dsw)
			dwi <= 1'b1;
		else
			dwi <= 1'b0;
		end
end

//数据总线仲裁
always @(*) begin
	if(rst) begin
		d_din = 16'h0;
		d_addr = 16'h0;
		d_we = 1'b0;
		end
	else begin
		if(dwi) begin
			d_addr = d_addr_z1 | d_addr_z0;
			d_din = d_din_z1 | d_din_z0;
			d_we = d_we_z1 | d_we_z0;
			end
		else begin
			d_din = 16'h0;
			d_addr = d_addr_d0 | d_addr_d1;
			d_we =1'b0;
			end
		end
end

wire [15:0]PC;
assign i_addr=PC;//地址指示
YD_reg u_YD_reg//寄存器组
(
	.clk    (clk),
	.rst    (rst),
	.jpc    (int_jpc),
	.dsv	(dsv_0 | dsv_1),
	.din0   (int_din0),
	.waddr0 (int_waddr0),
	.we0    (int_we0),
	.din1   (int_din1),
	.waddr1 (int_waddr1),
	.we1    (int_we1),
	.raddr0 (raddr0),
	.dout0  (dout0),
	.raddr1 (raddr1),
	.dout1  (dout1),
	.PC     (PC),
	.DKD	(DKD)
);



YD_int u_YD_int//中断控制器
(
	.clk        (clk),
	.rst        (rst),
	.int_vld    (int_vld),
	.int_rdy    (int_rdy),
	.PC         (PC),
	.jpc        (jpc),
	.int_jpc    (int_jpc),
	.inp        (inp),
	.din0       (din0),
	.waddr0     (waddr0),
	.we0        (we0),
	.din1       (din1),
	.waddr1     (waddr1),
	.we1        (we1),
	.int_din0   (int_din0),
	.int_waddr0 (int_waddr0),
	.int_we0    (int_we0),
	.int_din1   (int_din1),
	.int_waddr1 (int_waddr1),
	.int_we1    (int_we1)
);

endmodule