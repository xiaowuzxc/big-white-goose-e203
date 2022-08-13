`timescale 10ns/1ns
module tb_NN ();
reg clk;
reg rst_n;
wire [3:0]result_r;
wire STOP;
//仿真640*480时序
/*
H场时�?8-640*2-2(P)
V行时�?4-480-2(H)
*/
reg cmos_frame_vsync,cmos_frame_href,cmos_frame_valid;//帧有效信�?,行有效信�?,数据有效使能信号
reg	[7:0]cmos_frame_data;  //有效数据8b
reg cmos_frame_href_r,cmos_frame_vsync_r;
reg cmos_frame_href_c;
reg [15:0]hcnt,pcnt;

reg [7:0]img[640*480-1:0];

reg chk_reg;//结果�?�?
initial begin
	chk_reg=0;
	clk=0;
	rst_n=0;
	#10;
	rst_n=1;
	@(posedge STOP);
	$readmemh("C:/Users/wu/Desktop/gitee/jichuangsai-e203/img2hex640/obj0.txt",img);
	@(posedge STOP);
	$readmemh("C:/Users/wu/Desktop/gitee/jichuangsai-e203/img2hex640/obj1.txt",img);
	#10;
	if(result_r==4'h0)
		chk_reg=chk_reg;
	else
		chk_reg=1;
	@(posedge STOP);
	$readmemh("C:/Users/wu/Desktop/gitee/jichuangsai-e203/img2hex640/obj2.txt",img);
	#10;
	if(result_r==4'h1)
		chk_reg=chk_reg;
	else
		chk_reg=1;
	@(posedge STOP);
	$readmemh("C:/Users/wu/Desktop/gitee/jichuangsai-e203/img2hex640/obj3.txt",img);
	#10;
	if(result_r==4'h2)
		chk_reg=chk_reg;
	else
		chk_reg=1;
	@(posedge STOP);
	$readmemh("C:/Users/wu/Desktop/gitee/jichuangsai-e203/img2hex640/obj4.txt",img);
	#10;
	if(result_r==4'h3)
		chk_reg=chk_reg;
	else
		chk_reg=1;
	@(posedge STOP);
	$readmemh("C:/Users/wu/Desktop/gitee/jichuangsai-e203/img2hex640/obj5.txt",img);
	#10;
	if(result_r==4'h4)
		chk_reg=chk_reg;
	else
		chk_reg=1;
	@(posedge STOP);
	$readmemh("C:/Users/wu/Desktop/gitee/jichuangsai-e203/img2hex640/obj6.txt",img);
	#10;
	if(result_r==4'h5)
		chk_reg=chk_reg;
	else
		chk_reg=1;
	@(posedge STOP);
	$readmemh("C:/Users/wu/Desktop/gitee/jichuangsai-e203/img2hex640/obj7.txt",img);
	#10;
	if(result_r==4'h6)
		chk_reg=chk_reg;
	else
		chk_reg=1;
	@(posedge STOP);
	$readmemh("C:/Users/wu/Desktop/gitee/jichuangsai-e203/img2hex640/obj8.txt",img);
	#10;
	if(result_r==4'h7)
		chk_reg=chk_reg;
	else
		chk_reg=1;
	@(posedge STOP);
	$readmemh("C:/Users/wu/Desktop/gitee/jichuangsai-e203/img2hex640/obj9.txt",img);
	#10;
	if(result_r==4'h8)
		chk_reg=chk_reg;
	else
		chk_reg=1;
	@(posedge STOP);
	#10;
	if(result_r==4'h9)
		chk_reg=chk_reg;
	else
		chk_reg=1;
	#100;
	if (chk_reg) 
		$display("Test NN Error");
	else
		$display("Test NN Pass");
	$stop;
end

always #(1) clk=~clk;
reg cmos_frame_valid_r;

//生成DVP内部时序
always @(posedge clk)begin//生成高低位切�?
	if(cmos_frame_href)
		cmos_frame_valid_r<=~cmos_frame_valid_r;
	else
		cmos_frame_valid_r<=0;
end
always @(*)begin//生成高低位切�?
	if(cmos_frame_href)
		cmos_frame_valid=~cmos_frame_valid_r;
	else
		cmos_frame_valid=0;
end
always @(posedge clk or negedge rst_n) begin
	if(~rst_n)begin
		hcnt=0;
		pcnt=0;
		end
	else begin
		cmos_frame_href_r <= cmos_frame_href_c;//h打一�?
		cmos_frame_vsync_r <= cmos_frame_vsync;//v打一�?
		//pcnt
		if(pcnt<640*2+10)
			pcnt <= pcnt+1;
		else
			pcnt <= 0;
		//hcnt
		if(hcnt<486) begin
			if(cmos_frame_href_r && ~cmos_frame_href_c)
				hcnt <= hcnt+1;
			else
				hcnt <= hcnt;
			end
		else
			hcnt <= 0;
		end
	end
always @(*) begin
	//hc
	if(pcnt>=8 && pcnt <640*2+8)
		cmos_frame_href_c = 1;
	else
		cmos_frame_href_c = 0;
	//h
	if(pcnt>=8 && pcnt<640*2+8 && hcnt>=4 && hcnt<484)
		cmos_frame_href = 1;
	else
		cmos_frame_href = 0;
	if(hcnt>=4 && hcnt<484)
		cmos_frame_vsync = 1;
	else
		cmos_frame_vsync = 0;
end
wire [31:0]img_addr=640*(hcnt-4)+(pcnt-9)/2;//生成地址
always@(*) begin
	if(cmos_frame_vsync && cmos_frame_href)
		if(cmos_frame_valid)
			cmos_frame_data=img[img_addr];
		else
			cmos_frame_data=0;
	else
		cmos_frame_data=0;
end

reg [9:0]pcnt_sh,hcnt_sh;
always @(posedge clk or negedge rst_n) begin : proc_
	if(~rst_n) begin
		pcnt_sh <= 0;
		hcnt_sh <= 0;
		end 
	else begin
		if(cmos_frame_vsync) begin //场有�?
			if(cmos_frame_href) begin //行有�?
				if (cmos_frame_valid) begin//像素有效
					pcnt_sh <= pcnt_sh+1;
					end
				else begin //像素无效
					pcnt_sh <= pcnt_sh;
					end
				end
			else begin //行无�?
				pcnt_sh <= 0;
				end
			if(cmos_frame_href_r && ~cmos_frame_href_c)//行结�?
				hcnt_sh <= hcnt_sh+1;
			else
				hcnt_sh <= hcnt_sh;
			end
		else begin
			hcnt_sh <= 0;
			end
		end
	end
NN_top inst_NN_top
(
	.clk              (clk),
	.rst_n            (rst_n),
	.cmos_frame_vsync (cmos_frame_vsync),
	.cmos_frame_href  (cmos_frame_href),
	.cmos_frame_valid (cmos_frame_valid),
	.cmos_frame_data  (cmos_frame_data),
	.result_r         (result_r),
	.STOP (STOP)
);
endmodule