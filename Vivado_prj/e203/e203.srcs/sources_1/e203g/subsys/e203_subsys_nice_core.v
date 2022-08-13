/*                                                                      
 Copyright 2018-2020 Nuclei System Technology, Inc.                
                                                                         
 Licensed under the Apache License, Version 2.0 (the "License");         
 you may not use this file except in compliance with the License.        
 You may obtain a copy of the License at                                 
                                                                         
     http://www.apache.org/licenses/LICENSE-2.0                          
                                                                         
  Unless required by applicable law or agreed to in writing, software    
 distributed under the License is distributed on an "AS IS" BASIS,       
 WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 See the License for the specific language governing permissions and     
 limitations under the License.                                          
 */
/*rtl change*/
//=====================================================================
//
// Designer   : LZB
//
// Description:
//  The Module to realize a simple NICE core
//
// ====================================================================
`include "e203_defines.v"

`ifdef E203_HAS_NICE//{
`define rot0  16'h2000    //45
`define rot1  16'h12e4    //26.5651
`define rot2  16'h09fb    //14.0362
`define rot3  16'h0511    //7.1250
`define rot4  16'h028b    //3.5763
`define rot5  16'h0145    //1.7899
`define rot6  16'h00a3    //0.8952
`define rot7  16'h0051    //0.4476
`define rot8  16'h0028    //0.2238
`define rot9  16'h0014    //0.1119
`define rot10 16'h000a    //0.0560
`define rot11 16'h0005    //0.0280
`define rot12 16'h0003    //0.0140
`define rot13 16'h0001    //0.0070

module e203_subsys_nice_core (
    // System	
    input                         nice_clk             ,
    input                         nice_rst_n	          ,
    output                        nice_active	      ,//外部悬空，忽略

    // Control cmd_req
    input                         nice_req_valid       ,
    output                        nice_req_ready       ,
    input  [`E203_XLEN-1:0]       nice_req_inst        ,
    input  [`E203_XLEN-1:0]       nice_req_rs1         ,
    input  [`E203_XLEN-1:0]       nice_req_rs2         ,//不需要
    // Control cmd_rsp	
    output reg                    nice_rsp_valid       ,
    input                         nice_rsp_ready       ,
    output wire[`E203_XLEN-1:0]   nice_rsp_rdat        ,
    output                        nice_rsp_err    	   ,//不需要
    //以下接口忽略
    // Memory lsu_req	
    output                        nice_icb_cmd_valid   ,
    input                         nice_icb_cmd_ready   ,
    output [`E203_ADDR_SIZE-1:0]  nice_icb_cmd_addr    ,
    output                        nice_icb_cmd_read    ,
    output [`E203_XLEN-1:0]       nice_icb_cmd_wdata   ,
    output [1:0]                  nice_icb_cmd_size    ,
    // Memory lsu_rsp	
    input                         nice_icb_rsp_valid   ,
    output                        nice_icb_rsp_ready   ,
    input  [`E203_XLEN-1:0]       nice_icb_rsp_rdata   ,
    input                         nice_icb_rsp_err	   ,
    output                        nice_mem_holdup	   ,
	//in
	input wire [3:0]              Nub_cnn_result

);
//custom3指令，一条，R type
/*
R type: 
+-------+-----+-----+-------+----+--------+
| func7 | rs2 | rs1 | func3 | rd | opcode |
+-------+-----+-----+-------+----+--------+
|31   25|24 20|19 15|14   12|11 7|6      0|
|0000110|00000| rs1 |  110  | rd | 1111011|
.insn r opcode, func3, func7, rd, rs1, rs2
opcode=0x7b
cordic: func3=6[xd+,xs1+,xs2-] =3'b110
Nub_NN: func3=4[xd+,xs1-,xs2-] =3'b100
cordic: func7 = 2 = 7'b0000010
Nub_NN: func7 = 4 = 7'b0000100
*/


wire [6:0] opcode      = nice_req_inst[6:0];
wire [2:0] rv32_func3  = nice_req_inst[14:12];
wire [6:0] rv32_func7  = nice_req_inst[31:25];

wire nice_cmd_hsked = nice_req_valid && nice_req_ready && (opcode==7'b1111011) 
&& ((rv32_func3==3'b110)|(rv32_func3==3'b100)) 
&& ((rv32_func7==7'b0000100) | (rv32_func7==7'b0000010)) ;//请求握手成功
wire nice_cmd_hsked_crd = nice_req_valid && (rv32_func3==3'b110) && (rv32_func7==7'b0000010);//crd请求握手
wire nice_cmd_hsked_cnn = nice_req_valid && (rv32_func3==3'b100) && (rv32_func7==7'b0000100);//cnn请求握手
wire [15:0]phase_in=nice_req_rs1[15:0];//数据输入
reg signed [16:0] sin,cos,eps;//结果输出
reg [1:0]pipe_all;//全局输出标志打拍
reg [1:0]pipe_crd;//crd输出标志打拍
reg [1:0]pipe_cnn;//cnn输出标志打拍
wire all_en;//全局结果输出
reg crd_en;//crd结果输出
reg cnn_en;//cnn结果输出
reg [31:0]output_dat;
reg [3:0]Nub_cnn_result_r,Nub_cnn_result_rr;

always @(posedge nice_clk) begin//result打两拍
	  Nub_cnn_result_r<=Nub_cnn_result;
	  Nub_cnn_result_rr<=Nub_cnn_result_r;
end

assign nice_req_ready = nice_req_valid && ~(|pipe_all);//有请求且piper没有东西

always @(posedge nice_clk or negedge nice_rst_n) begin//输出数据
  if(~nice_rst_n)
    output_dat<=0;
  else
	if(nice_rsp_valid)//有数据等待输出
		output_dat<=output_dat;
	else//没有输出
		output_dat<={cos[16:1],sin[16:1]};  
end

//选择数据
assign nice_rsp_rdat=({32{crd_en}} & output_dat) //cordic
					| ({32{cnn_en}} & {28'h0,Nub_cnn_result_rr});//cnn

always @(posedge nice_clk or negedge nice_rst_n) begin//数据有效
	if(~nice_rst_n)
		nice_rsp_valid<=0;
	else
	if(nice_rsp_valid)//数据有效
		if(nice_rsp_ready)//主机准备好
			nice_rsp_valid<=0;
		else//没准备好
			nice_rsp_valid<=nice_rsp_valid;
	else//数据无效
		if(all_en)//下一拍输出
			nice_rsp_valid<=1;
		else//没有输出
			nice_rsp_valid<=nice_rsp_valid;
end

always @(posedge nice_clk or negedge nice_rst_n) begin//数据选择
	if(~nice_rst_n) begin
		crd_en<=0;
		cnn_en<=0;
		end
	else
		if(nice_rsp_valid)//数据有效
			if(nice_rsp_ready) begin//主机准备好
				crd_en<=0;
				cnn_en<=0;
				end
			else begin//没准备好
				crd_en<=crd_en;
				cnn_en<=cnn_en;
				end
		else begin//数据无效
			if(pipe_crd[0])//crd下一拍输出
				crd_en<=1;
			else //没有输出
				crd_en<=crd_en;
			if(pipe_cnn[0])//cnn下一拍输出
				cnn_en<=1;
			else //没有输出
				cnn_en<=cnn_en;
			end
		end

always @(posedge nice_clk or negedge nice_rst_n) begin//指令信号打2拍
	if(~nice_rst_n) begin
		pipe_all=2'd0;
		pipe_crd=2'd0;
		pipe_cnn=2'd0;
		end
	else begin
		pipe_all={nice_cmd_hsked,pipe_all[1]};
		pipe_crd={nice_cmd_hsked_crd,pipe_crd[1]};
		pipe_cnn={nice_cmd_hsked_cnn,pipe_cnn[1]};
		end
end
assign all_en=pipe_all[0];//计算结果输出前一拍[1]，当前拍是[0]




always @(posedge nice_clk or negedge nice_rst_n) begin//输出握手
  if(~nice_rst_n)
    nice_rsp_valid<=0;
  else
	if(nice_rsp_valid)//数据有效
		if(nice_rsp_ready)//主机准备好
			nice_rsp_valid<=0;
		else//没准备好
			nice_rsp_valid<=nice_rsp_valid;
	else//数据无效
		if(all_en)//下一拍输出
			nice_rsp_valid<=1;
		else//没有输出
			nice_rsp_valid<=nice_rsp_valid;
end

localparam PIPELINE = 2;
localparam K = 17'h09b74;//gian k=0.607253*2^16,9b74,

reg signed [16:0] x0=0,y0=0,z0=0;
reg signed [16:0] x1=0,y1=0,z1=0;
reg signed [16:0] x2=0,y2=0,z2=0;
reg signed [16:0] x3=0,y3=0,z3=0;
reg signed [16:0] x4=0,y4=0,z4=0;
reg signed [16:0] x5=0,y5=0,z5=0;
reg signed [16:0] x6=0,y6=0,z6=0;
reg signed [16:0] x7=0,y7=0,z7=0;
reg signed [16:0] x8=0,y8=0,z8=0;
reg signed [16:0] x9=0,y9=0,z9=0;
reg signed [16:0] x10=0,y10=0,z10=0;
reg signed [16:0] x11=0,y11=0,z11=0;
reg signed [16:0] x12=0,y12=0,z12=0;
reg signed [16:0] x13=0,y13=0,z13=0;
reg signed [16:0] x14=0,y14=0,z14=0;
reg signed [16:0] x15=0,y15=0,z15=0;

reg [1:0] quadrant [PIPELINE:0];
integer i;
initial
begin
	for(i=0;i<=PIPELINE;i=i+1)
	quadrant[i] = 2'b0;
end

always @ (posedge nice_clk)//stage 0,not pipeline
begin
	x0 <= K; 
	y0 <= 17'd0;
	z0 <= {3'b0,phase_in[13:0]};
end

always @ (*)//stage 1
begin
  if(z0[16])//the diff is negative so clockwise
  begin
	  x1 = x0 + y0;
	  y1 = y0 - x0;
	  z1 = z0 + `rot0;
  end
  else
  begin
	  x1 = x0 - y0;//x1 <= x0;
	  y1 = y0 + x0;//y1 <= x0;
	  z1 = z0 - `rot0;//reversal 45
  end
end
always @ (*)//stage 2
begin
	if(z1[16])//the diff is negative so clockwise
	begin
		x2 = x1 + (y1 >>> 1);
		y2 = y1 - (x1 >>> 1);
		z2 = z1 + `rot1;//clockwise 26
	end
	else
	begin
		x2 = x1 - (y1 >>> 1);
		y2 = y1 + (x1 >>> 1);
		z2 = z1 - `rot1;//anti-clockwise 26
	end
end
always @ (*)//stage 3
begin
	if(z2[16])//the diff is negative so clockwise
	begin
		x3 = x2 + (y2 >>> 2);
		y3 = y2 - (x2 >>> 2);
		z3 = z2 + `rot2;
	end
	else
	begin
		x3 = x2 - (y2 >>> 2);
		y3 = y2 + (x2 >>> 2);
		z3 = z2 - `rot2;
	end
end
always @ (*)//stage 4
begin
	if(z3[16])
	begin
		x4 <= x3 + (y3 >>> 3);
		y4 <= y3 - (x3 >>> 3);
		z4 <= z3 + `rot3;
	end
	else
	begin
		x4 <= x3 - (y3 >>> 3);
		y4 <= y3 + (x3 >>> 3);
		z4 <= z3 - `rot3;
	end
end
always @ (*)//stage 5
begin
	if(z4[16])
	begin
		x5 = x4 + (y4 >>> 4);
		y5 = y4 - (x4 >>> 4);
		z5 = z4 + `rot4;
	end
	else
	begin
		x5 = x4 - (y4 >>> 4);
		y5 = y4 + (x4 >>> 4);
		z5 = z4 - `rot4;
	end
end
always @ (*)//STAGE 6
begin
	if(z5[16])
	begin
		x6 = x5 + (y5 >>> 5);
		y6 = y5 - (x5 >>> 5);
		z6 = z5 + `rot5;
	end
	else
	begin
		x6 = x5 - (y5 >>> 5);
		y6 = y5 + (x5 >>> 5);
		z6 = z5 - `rot5;
	end
end
always @ (*)//stage 7
begin
	if(z6[16])
	begin
		x7 = x6 + (y6 >>> 6);
		y7 = y6 - (x6 >>> 6);
		z7 = z6 + `rot6;
	end
	else
	begin
		x7 = x6 - (y6 >>> 6);
		y7 = y6 + (x6 >>> 6);
		z7 = z6 - `rot6;
	end
end
always @ (posedge nice_clk)//stage 8
begin
	if(z7[16])
	begin
		x8 <= x7 + (y7 >>> 7);
		y8 <= y7 - (x7 >>> 7);
		z8 <= z7 + `rot7;
	end
	else
	begin
		x8 <= x7 - (y7 >>> 7);
		y8 <= y7 + (x7 >>> 7);
		z8 <= z7 - `rot7;
	end
end
always @ (*)//stage 9
begin
	if(z8[16])
	begin
		x9 = x8 + (y8 >>> 8);
		y9 = y8 - (x8 >>> 8);
		z9 = z8 + `rot8;
	end
	else
	begin
		x9 = x8 - (y8 >>> 8);
		y9 = y8 + (x8 >>> 8);
		z9 = z8 - `rot8;
	end
end
always @ (*)//stage 10
begin
	if(z9[16])
	begin
		x10 <= x9 + (y9 >>> 9);
		y10 <= y9 - (x9 >>> 9);
		z10 <= z9 + `rot9;
	end
	else
	begin
		x10 <= x9 - (y9 >>> 9);
		y10 <= y9 + (x9 >>> 9);
		z10 <= z9 - `rot9;
	end
end
always @ (*)//stage 11
begin
	if(z10[16])
	begin
		x11 = x10 + (y10 >>> 10);
		y11 = y10 - (x10 >>> 10);
		z11 = z10 + `rot10;
	end
	else
	begin
		x11 = x10 - (y10 >>> 10);
		y11 = y10 + (x10 >>> 10);
		z11 = z10 - `rot10;
	end
end
always @ (*)//STAGE 12
begin
	if(z11[16])
	begin
		x12 = x11 + (y11 >>> 11);
		y12 = y11 - (x11 >>> 11);
		z12 = z11 + `rot11;
	end
	else
	begin
		x12 = x11 - (y11 >>> 11);
		y12 = y11 + (x11 >>> 11);
		z12 = z11 - `rot11;
	end
end
always @ (*)//stage 13
begin
	if(z12[16])
	begin
		x13 <= x12 + (y12 >>> 12);
		y13 <= y12 - (x12 >>> 12);
		z13 <= z12 + `rot12;
	end
	else
	begin
		x13 <= x12 - (y12 >>> 12);
		y13 <= y12 + (x12 >>> 12);
		z13 <= z12 - `rot12;
	end
end
always @ (*)//stage 14
begin
	if(z13[16])
	begin
		x14 = x13 + (y13 >>> 13);
		y14 = y13 - (x13 >>> 13);
		z14 = z13 + `rot13;
	end
	else
	begin
		x14 = x13 - (y13 >>> 13);
		y14 = y13 + (x13 >>> 13);
		z14 = z13 - `rot13;
	end
end
always @ (*)//stage 15
begin
	if(z14[16])
	begin
		x15 = x14 + (y14 >>> 14);
		y15 = y14 - (x14 >>> 14);
	end
	else
	begin
		x15 = x14 - (y14 >>> 14);
		y15 = y14 + (x14 >>> 14);
	end
end

always @ (posedge nice_clk)
begin
  quadrant[0] <= phase_in[15:14];
  quadrant[1] <= quadrant[0];
  quadrant[2] <= quadrant[1];
end
always @ (*) begin
eps <= z14;
case(quadrant[1]) //or 15
2'b00:begin //if the phase is in first quadrant,the sin(X)=sin(A),cos(X)=cos(A)
		cos <= x15;
		sin <= y15;
		end
2'b01:begin //if the phase is in second quadrant,the sin(X)=sin(A+90)=cosA,cos(X)=cos(A+90)=-sinA
		cos <= ~(y15) + 1'b1;//-sin
		sin <= x15;//cos
		end
2'b10:begin //if the phase is in third quadrant,the sin(X)=sin(A+180)=-sinA,cos(X)=cos(A+180)=-cosA
		cos <= ~(x15) + 1'b1;//-cos
		sin <= ~(y15) + 1'b1;//-sin
		end
2'b11:begin //if the phase is in forth quadrant,the sin(X)=sin(A+270)=-cosA,cos(X)=cos(A+270)=sinA
		cos <= y15;//sin
		sin <= ~(x15) + 1'b1;//-cos
		end
endcase
end

//存储器访问端口关闭
assign nice_icb_cmd_valid=0;
assign nice_icb_cmd_addr =0;
assign nice_icb_cmd_read =0;
assign nice_icb_cmd_wdata=0;
assign nice_icb_cmd_size =0;
assign nice_icb_rsp_ready=1;
assign nice_mem_holdup   =0;
assign nice_rsp_err      =0;
endmodule
`endif//}


