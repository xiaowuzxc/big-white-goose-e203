module NN_top (
	input 		clk,    // Clock
	input 		rst_n,  // Asynchronous reset active low
//DVP 8b 640*480
	input		cmos_frame_vsync,//帧有效信号
	input		cmos_frame_href ,//行有效信号
	input		cmos_frame_valid,//数据有效使能信号
	input  [7:0]cmos_frame_data,  //有效数据8b
//syn
	output [3:0]result_r,
	output STOP
);

/*
灰度图像
640*480 -> 28*28
0---------------> 640
|      <16>
|    (16,96) -448- (2,543)
|<96> 448
|    (463,96)     (463,543)
|      <16>
480
16*16 -> 1pix
448 -> 28
乒乓缓冲
存储器有3个独立端口
写端口avg_waddr
读平均端口avg_raddr
读端口raddr_NN

状态机
0空闲:进数据读出
1数据读出:28*28被神经网络读取，等待计数
2推理状态:使用存储器的内容推理，等待STOP=1
3等待状态:等v同步由低变高，开始新一帧
4写入状态:持续写入
5写入完成:write_end高脉冲，进空闲


*/
//Num_NN 信号
wire STOP;
reg STOP_r,STOP_rr;//STOP打一拍
reg GO;
//port b NN交互
wire [15:0]doutb;
reg wen_NN,wen_NN_r;//写NN使能
wire [10:0]dout_NN=doutb[15:5];//数据取高11位
reg [12:0]raddr_NN,raddr_NN_r;//地址
wire [7:0]doutb_NN_test=doutb[15:8];

wire [3:0]RESULT;//结果
//存储器a定义
reg [9:0]addra;
reg [16-1:0]dina;
reg wea;
wire [16-1:0]douta;

reg [9:0]avg_addr;//写端口地址
reg avg_wen;//写使能
reg [16-1:0]avg_wdin;//写数据
wire [16-1:0]avg_rdout;

reg read_end;//读取完脉冲
reg [3:0]result_r;//结果寄存器
reg mem_ready;//存储器准备好
reg write_end;//存储器写完脉冲

reg [9:0]hcnt,hcnt_r,pcnt,pcnt_r,hcntz,pcntz;//行计数，像素计数
reg cmos_frame_vsync_r;//场同步打一拍
reg cmos_frame_href_r;//场同步打一拍

reg IDLE_r; //IDLE打一拍
/*----------------状态机定义------------*/
reg [3:0]p_sta,n_sta;//当前状态，下一状态
localparam IDLE=4'h0;//空闲状态
localparam DONN=4'h1;//数据读出
localparam TLNN=4'h2;//推理状态
localparam WVPE=4'h3;//等待状态
localparam WDMM=4'h4;//写入状态
localparam WDED=4'h5;//写入完成
//状态转移
always @(posedge clk or negedge rst_n) begin
	if(~rst_n) 
		p_sta <= IDLE;
	else 
		p_sta <= n_sta;
	end

//下一状态
always @(*) begin
		case (p_sta)
			IDLE:
				if(IDLE_r)
					n_sta=DONN;//空闲，拉高GO+wen
				else
					n_sta=IDLE;
			DONN://把28*28导入NN
				if (raddr_NN<784-2)
					n_sta=DONN;
				else
					n_sta=TLNN;
			TLNN://等待NN输出结果
				if (STOP)
					n_sta=WVPE;
					//n_sta=IDLE;
				else
					n_sta=TLNN;
			WVPE://等待下一帧图像
				if (cmos_frame_vsync&&~cmos_frame_vsync_r)
					n_sta=WDMM;
				else
					n_sta=WVPE;
			WDMM://等待一帧图像结束
				if (cmos_frame_vsync_r)
					n_sta=WDMM;
				else
					n_sta=WDED;
			WDED:n_sta=IDLE;//图像结束，跳转
			default : n_sta=IDLE;
		endcase
	end



/*----------------状态机定义------------*/



//DONN
always @(posedge clk or negedge rst_n) begin//交互
	if(~rst_n) begin
		GO <= 0;
		wen_NN<=0;
		wen_NN_r<=0;
		raddr_NN<=0;
		raddr_NN_r<=0;
		IDLE_r<=0;
		end 
	else begin
		wen_NN_r<=wen_NN;
		raddr_NN_r<=raddr_NN;
		//GO<=wen_NN_r;
		if(p_sta==IDLE || p_sta==DONN) begin//IDLE
			IDLE_r<=1;
			wen_NN<=1;
			//GO<=1;
			end
		else begin
			IDLE_r<=0;
			//GO <=0;
			wen_NN<=0;
			end
		if (p_sta==DONN) begin//GO=1且地址位于区间
			raddr_NN<=raddr_NN+1'b1;
			end
		else begin
			raddr_NN<=0;
			end
		end
	end



//TLNN
always @(posedge clk or negedge rst_n) begin
	if(~rst_n) begin
		result_r <= 4'hf;
		STOP_r <= 0;
		end
	else begin
		STOP_r <= STOP;//打一拍
		STOP_rr <= STOP_r;
		if(STOP_r && ~STOP_rr)
			result_r <= RESULT;
		else
			result_r <= result_r;
		end
	end

//场vsync行href同步打一拍
always @(posedge clk or negedge rst_n) begin
	if(~rst_n) begin
		cmos_frame_vsync_r <= 1'b0;
		cmos_frame_href_r <= 1'b0;
		end 
	else begin
		cmos_frame_vsync_r <= cmos_frame_vsync;
		cmos_frame_href_r <= cmos_frame_href;
		end
	end

//行h、列p计数cnt
always @(posedge clk or negedge rst_n) begin
	if(~rst_n) begin
		hcnt<=0;//读存储器
		pcnt<=0;
		hcnt_r<=0;//平均计算
		pcnt_r<=0;
		end 
	else begin
		if(cmos_frame_valid) begin//数据有效
			hcnt_r<=hcnt;
			pcnt_r<=pcnt;
			end
		else begin 
			hcnt_r<=hcnt_r;
			pcnt_r<=pcnt_r;
		end
		if (~cmos_frame_vsync) begin//一帧结束
			hcnt<=0;
			pcnt<=0;
			end
		else begin//一帧中
			if(cmos_frame_href) begin//行有效
				if(cmos_frame_valid)//数据有效
					pcnt<=pcnt+1;
				else
					pcnt<=pcnt;
				end
			else begin//行无效
				pcnt<=0;
				end
			if (~cmos_frame_href&&cmos_frame_href_r)//发生一行结束
				hcnt<=hcnt+1;
			else
				hcnt<=hcnt;
			end
		end
	end

always @(*) begin//控制a口写使能
	if(~rst_n) begin
		wea=0;
		addra=0;
		end
	else begin
		addra=((hcnt-16)>>4)*28 + ((pcnt-96)>>4);
		if(pcnt>=96&&pcnt<=543&&hcnt>=16&&hcnt<=463&&p_sta==WDMM&&cmos_frame_valid)//wea使能控制
			wea=1;
		else
			wea=0;
		end
	end

always @(*) begin//写数据分配
	hcntz=hcnt_r-16;//去除边缘的行计数
	pcntz=pcnt_r-96;//去除边缘的像素计数
	if(hcntz[3:0]==4'h0 && pcntz[3:0]==4'h0)//每个区块第一个数据
		dina={8'h0,cmos_frame_data};
	else//求平均累加
		dina=douta+{8'h0,cmos_frame_data};
end
/*
96-111 112-127
0---------------> 640
|      <16>
|    (16,96) -448- (2,543)
|<96> 448
|    (463,96)     (463,543)
|      <16>
*/
Num_NN u_Num_NN (
	.clk                (clk),
	.GO                 (wen_NN_r),//(GO),
	.RESULT             (RESULT),
	.we_database        (wen_NN_r),
	.dp_database        (dout_NN-11'd1023),
	.address_p_database (raddr_NN_r),
	.STOP               (STOP)
);

IMG_DPR #(
		.RAM_WIDTH(16),
		.RAM_DEPTH(28*28)
	) inst_IMG_DPR (
		.clka   (clk),
		.rsta   (1'b0),
		.rstb   (1'b0),
//压缩

		.addra  (addra),
		.dina   (dina),
		.wea    (wea),
		.ena    (1'b1),
		.regcea (1'b1),
		.douta  (douta),

//NN
		.addrb  (raddr_NN[9:0]),
		.web    (1'b0),
		.enb    (1'b1),
		.regceb (1'b1),
		.doutb  (doutb)
	);



endmodule