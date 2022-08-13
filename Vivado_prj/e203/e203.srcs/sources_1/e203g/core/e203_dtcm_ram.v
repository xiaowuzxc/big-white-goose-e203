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
																																				 
																																				 
																																				 
//=====================================================================
//
// Designer   : Bob Hu
//
// Description:
//  The DTCM-SRAM module to implement DTCM SRAM
//
// ====================================================================
`include "e203_defines.v"

`ifdef E203_HAS_DTCM //{


module e203_dtcm_ram(

	input                              sd,
	input                              ds,
	input                              ls,

	input                              cs,  
	input                              we,  
	input  [`E203_DTCM_RAM_AW-1:0]     addr, 
	input  [`E203_DTCM_RAM_MW-1:0]     wem,
	input  [`E203_DTCM_RAM_DW-1:0]     din,          
	output [`E203_DTCM_RAM_DW-1:0]     dout,
	input                              rst_n,
	input                              clk

);

//wire [`E203_DTCM_RAM_AW-1+2:0]addr_sim={addr,2'h0};
/*
sd ds ls悬空
DP存储器的个数
AW地址线宽度
MW字节掩码
DW数据宽度
*/
//存储器选择，0使能DTCM，1使能Yduck
wire ram_sel=addr[`E203_DTCM_RAM_AW-1];//存储器选择
reg  ram_sel_r;//存储器选择打一拍

wire [`E203_DTCM_RAM_AW-2:0]addrb;
wire [`E203_DTCM_RAM_DW-1:0]doutb;

reg [`E203_DTCM_RAM_DW-1:0]din0,din1;
reg [`E203_DTCM_RAM_MW-1:0]wem0,wem1;
reg [`E203_DTCM_RAM_AW-2:0]addr0,addr1;
reg cs0,cs1;
reg we0,we1;
wire [`E203_DTCM_RAM_DW-1:0]dout0,dout1;

always @(posedge clk) 
    ram_sel_r<=ram_sel;

always @(*) begin
	if(ram_sel==1'b0) begin
		cs0  =cs;
		we0  =we;
		wem0 =wem;
		addr0=addr[`E203_DTCM_RAM_AW-2:0];
		din0 =din;

		cs1  =0;
		we1  =0;
		wem1 =0;
		addr1=0;
		din1 =0;
		end
	else begin//sel=1
		cs1  =cs;
		we1  =we;
		wem1 =wem;
		addr1=addr[`E203_DTCM_RAM_AW-2:0];
		din1 =din;

		cs0  =0;
		we0  =0;
		wem0 =0;
		addr0=0;
		din0 =0;
		end
end

assign dout=ram_sel_r?dout1:dout0;//输出

sirv_gnrl_ram #(
	.FORCE_X2ZERO(1),//Always force X to zeros
	.DP(`E203_DTCM_RAM_DP/2),//减半
	.DW(`E203_DTCM_RAM_DW),
	.MW(`E203_DTCM_RAM_MW),
	.AW(`E203_DTCM_RAM_AW-1) //地址线-1
) u_e203_dtcm_gnrl_ram(
	.sd  (sd  ),
	.ds  (ds  ),
	.ls  (ls  ),

	.rst_n (rst_n ),
	.clk (clk ),
	.cs  (cs0  ),
	.we  (we0  ),
	.addr(addr0),
	.din (din0 ),
	.wem (wem0 ),
	.dout(dout0)
);

sirv_dp_ram #(
	.DP(`E203_DTCM_RAM_DP/2),
	.DW(`E203_DTCM_RAM_DW),
	.MW(`E203_DTCM_RAM_MW),
	.AW(`E203_DTCM_RAM_AW-1) 
) u_sirv_dp_ram (
	.clk   (clk),
	.dina  (din1),
	.addra (addr1),
	.csa   (cs1),
	.wea   (we1),
	.wema  (wem1),
	.douta (dout1),

	.addrb (addrb),
	.doutb (doutb)
);


endmodule
`endif//}
