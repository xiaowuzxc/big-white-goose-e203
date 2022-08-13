module lcd1602 #(
	parameter CLK_F = 50_000_000
)(
//-----基本端口-----
	input logic clk,    //时钟输入
	input logic rst_n,  //低电平复位
//-----显示存储器-----
	input logic [4:0]addr,//显示存储器地址
	input logic [7:0]din,//显示存储器数据输入
	output logic [7:0]dout,//显示存储器数据输出
	input logic we,//显示存储器写入使能，高电平有效
//-----LCD1602-----
	inout logic [7:0]DB,
	output logic RS,//高电平数据，低电平指令
	output logic RW,//高电平读取，低电平写入
	output logic EN//高电平读出，上升沿写入
);
logic clk_en;//时钟使能，高电平有效
logic [7:0]dram[31:0];//显示存储器

//显示存储器
always @(posedge clk) begin
	if(we)
		dram[addr] <= din;//写入	
end

assign dout = dram[addr];

//写入状态机控制
logic wr_en;//写入使能，高电平有效
logic wr_rs;//命令/cmd数据选择，高电平数据，低电平指令
logic wr_rd;//写入完成，高电平有效
logic [7:0]wr_cmd;//待写入的数据

/*-------------DB连线-------------*/
logic DBo_en;//高电平输出使能
logic [7:0]DBo;//DB输出寄存器
logic BF;//DB[8]输入，仅用于判忙，0代表可写
assign DB=DBo_en?DBo:8'hz;//DB输出控制

/*-------------写操作FSM-------------*/
logic [2:0]lcd_n,lcd_p;//lcd写下一状态，lcd写当前状态
localparam idle=3'h0;//空闲状态
localparam bf_w=3'h1;//读取BF状态，设置rsrw
localparam bf_e=3'h2;//读取BF状态，EN拉高
localparam bf_r=3'h3;//读取BF状态，EN拉低
localparam cm_w=3'h4;//写入信息，设置rsrw
localparam cm_e=3'h5;//写入信息，EN拉高
localparam cm_r=3'h6;//写入信息，EN拉低
localparam wend=3'h7;//结束
//状态转移
always @(posedge clk) begin
	if(~rst_n) begin
		lcd_p <= idle;
		BF <= 0;
		end 
	else begin
		if(clk_en) begin
			lcd_p <= lcd_n;
			BF <= DB[7];
			end
		end
	end
//下一状态
always @(*) begin
	if(~rst_n) begin
		lcd_n = idle;
		end 
	else begin
		case (lcd_p)
			idle:
				if(wr_en) 
					lcd_n = bf_w;
				else
					lcd_n = idle;
			bf_w:lcd_n = bf_e;
			bf_e:lcd_n = bf_r;
			bf_r:
				if(BF)
					lcd_n = bf_w;
				else
					lcd_n = cm_w;
			cm_w:lcd_n = cm_e;
			cm_e:lcd_n = cm_r;
			cm_r:lcd_n = wend;
			wend:lcd_n = idle;
			default: lcd_n = idle;
			endcase
		end
	end
//输出
always @(*) begin
	if(~rst_n) begin
		DBo_en = 0;
		DBo = 0;
		RS = 0;
		RW = 0;
		EN = 0;
		wr_rd = 0;
		end
	else begin
		case (lcd_p)
			idle:begin
				DBo_en = 0;
				DBo = 0;
				RS = 0;
				RW = 0;
				EN = 0;
				wr_rd = 0;
				end
			bf_w:begin
				DBo_en = 0;//输入
				DBo = 0;
				RS = 0;//指令
				RW = 1;//读取
				EN = 0;
				wr_rd = 0;
				end
			bf_e:begin
				DBo_en = 0;
				DBo = 0;
				RS = 0;
				RW = 1;
				EN = 1;
				wr_rd = 0;
				end
			bf_r:begin
				DBo_en = 0;
				DBo = 0;
				RS = 0;
				RW = 1;
				EN = 0;
				wr_rd = 0;
				end
			cm_w:begin
				DBo_en = 1;//输出
				DBo = wr_cmd;
				RS = wr_rs;
				RW = 0;
				EN = 0;
				wr_rd = 0;
				end
			cm_e:begin
				DBo_en = 1;
				DBo = wr_cmd;
				RS = wr_rs;
				RW = 0;
				EN = 1;
				wr_rd = 0;
				end
			cm_r:begin
				DBo_en = 1;
				DBo = wr_cmd;
				RS = wr_rs;
				RW = 0;
				EN = 0;
				wr_rd = 0;
				end
			wend:begin
				DBo_en = 0;
				DBo = 0;
				RS = 0;
				RW = 0;
				EN = 0;
				wr_rd = 1;
				end
			default:begin
				DBo_en = 0;
				DBo = 0;
				RS = 0;
				RW = 0;
				EN = 0;
				wr_rd = 0;
				end
			endcase
		end
	end


/*-------------刷屏FSM-------------*/
logic [5:0]read_n,read_p;//刷屏下一状态，刷屏当前状态
localparam init_38=6'd0;//复位后第一个状态
localparam init_01=6'd1;
localparam init_0c=6'd2;
localparam init_06=6'd3;//初始化完成，进入atfh_l1
localparam atfh_l1=6'd4;//设置第一行
localparam atfh_0=6'd5;
localparam atfh_1=6'd6;
localparam atfh_2=6'd7;
localparam atfh_3=6'd8;
localparam atfh_4=6'd9;
localparam atfh_5=6'd10;
localparam atfh_6=6'd11;
localparam atfh_7=6'd12;
localparam atfh_8=6'd13;
localparam atfh_9=6'd14;
localparam atfh_10=6'd15;
localparam atfh_11=6'd16;
localparam atfh_12=6'd17;
localparam atfh_13=6'd18;
localparam atfh_14=6'd19;
localparam atfh_15=6'd20;
localparam atfh_l2=6'd21;//设置第2行
localparam atfh_16=6'd22;
localparam atfh_17=6'd23;
localparam atfh_18=6'd24;
localparam atfh_19=6'd25;
localparam atfh_20=6'd26;
localparam atfh_21=6'd27;
localparam atfh_22=6'd28;
localparam atfh_23=6'd29;
localparam atfh_24=6'd30;
localparam atfh_25=6'd31;
localparam atfh_26=6'd32;
localparam atfh_27=6'd33;
localparam atfh_28=6'd34;
localparam atfh_29=6'd35;
localparam atfh_30=6'd36;
localparam atfh_31=6'd37;
//状态转移
always @(posedge clk) begin
	if(~rst_n) begin
		read_p <= init_38;
		end 
	else if(clk_en) begin
		read_p <= read_n;
		end
	end
//下一状态
always @(*) begin
	if(~rst_n) begin
		read_n = init_38;
		end 
	else begin
		case(read_p)
			init_38:
				if(wr_rd)
					read_n = init_01;
				else
					read_n = init_38;
			init_01:
				if(wr_rd)
					read_n = init_0c;
				else
					read_n = init_01;
			init_0c:
				if(wr_rd)
					read_n = init_06;
				else
					read_n = init_0c;
			init_06:
				if(wr_rd)
					read_n = atfh_l1;
				else
					read_n = init_06;
			atfh_l1:
				if(wr_rd)
					read_n = atfh_0;
				else
					read_n = atfh_l1;
			atfh_0 :
				if(wr_rd)
					read_n = atfh_1;
				else
					read_n = atfh_0;
			atfh_1 :
				if(wr_rd)
					read_n = atfh_2;
				else
					read_n = atfh_1;
			atfh_2 :
				if(wr_rd)
					read_n = atfh_3;
				else
					read_n = atfh_2;
			atfh_3 :
				if(wr_rd)
					read_n = atfh_4;
				else
					read_n = atfh_3;
			atfh_4 :
				if(wr_rd)
					read_n = atfh_5;
				else
					read_n = atfh_4;
			atfh_5 :
				if(wr_rd)
					read_n = atfh_6;
				else
					read_n = atfh_5;
			atfh_6 :
				if(wr_rd)
					read_n = atfh_7;
				else
					read_n = atfh_6;
			atfh_7 :
				if(wr_rd)
					read_n = atfh_8;
				else
					read_n = atfh_7;
			atfh_8 :
				if(wr_rd)
					read_n = atfh_9;
				else
					read_n = atfh_8;
			atfh_9 :
				if(wr_rd)
					read_n = atfh_10;
				else
					read_n = atfh_9;
			atfh_10:
				if(wr_rd)
					read_n = atfh_11;
				else
					read_n = atfh_10;
			atfh_11:
				if(wr_rd)
					read_n = atfh_12;
				else
					read_n = atfh_11;
			atfh_12:
				if(wr_rd)
					read_n = atfh_13;
				else
					read_n = atfh_12;
			atfh_13:
				if(wr_rd)
					read_n = atfh_14;
				else
					read_n = atfh_13;
			atfh_14:
				if(wr_rd)
					read_n = atfh_15;
				else
					read_n = atfh_14;
			atfh_15:
				if(wr_rd)
					read_n = atfh_l2;
				else
					read_n = atfh_15;
			atfh_l2:
				if(wr_rd)
					read_n = atfh_16;
				else
					read_n = atfh_l2;
			atfh_16:
				if(wr_rd)
					read_n = atfh_17;
				else
					read_n = atfh_16;
			atfh_17:
				if(wr_rd)
					read_n = atfh_18;
				else
					read_n = atfh_17;
			atfh_18:
				if(wr_rd)
					read_n = atfh_19;
				else
					read_n = atfh_18;
			atfh_19:
				if(wr_rd)
					read_n = atfh_20;
				else
					read_n = atfh_19;
			atfh_20:
				if(wr_rd)
					read_n = atfh_21;
				else
					read_n = atfh_20;
			atfh_21:
				if(wr_rd)
					read_n = atfh_22;
				else
					read_n = atfh_21;
			atfh_22:
				if(wr_rd)
					read_n = atfh_23;
				else
					read_n = atfh_22;
			atfh_23:
				if(wr_rd)
					read_n = atfh_24;
				else
					read_n = atfh_23;
			atfh_24:
				if(wr_rd)
					read_n = atfh_25;
				else
					read_n = atfh_24;
			atfh_25:
				if(wr_rd)
					read_n = atfh_26;
				else
					read_n = atfh_25;
			atfh_26:
				if(wr_rd)
					read_n = atfh_27;
				else
					read_n = atfh_26;
			atfh_27:
				if(wr_rd)
					read_n = atfh_28;
				else
					read_n = atfh_27;
			atfh_28:
				if(wr_rd)
					read_n = atfh_29;
				else
					read_n = atfh_28;
			atfh_29:
				if(wr_rd)
					read_n = atfh_30;
				else
					read_n = atfh_29;
			atfh_30:
				if(wr_rd)
					read_n = atfh_31;
				else
					read_n = atfh_30;
			atfh_31:
				if(wr_rd)
					read_n = atfh_l1;
				else
					read_n = atfh_31;
			default: read_n = init_38;//复位
			endcase
		end
	end
//输出
always @(*) begin
	if(~rst_n) begin
		wr_cmd=0;
		wr_rs=0;
		wr_en=0;
		end 
	else begin
		case(read_p)
			init_38:begin
				wr_cmd=8'h38;
				wr_rs=0;
				wr_en=1;
				end
			init_01:begin
				wr_cmd=8'h01;
				wr_rs=0;
				wr_en=1;
				end
			init_0c:begin
				wr_cmd=8'h0c;
				wr_rs=0;
				wr_en=1;
				end
			init_06:begin
				wr_cmd=8'h06;
				wr_rs=0;
				wr_en=1;
				end
			atfh_l1:begin
				wr_cmd=8'h80;
				wr_rs=0;
				wr_en=1;
				end
			atfh_0 :begin
				wr_cmd=dram[0];
				wr_rs=1;
				wr_en=1;
				end
			atfh_1 :begin
				wr_cmd=dram[1];
				wr_rs=1;
				wr_en=1;
				end
			atfh_2 :begin
				wr_cmd=dram[2];
				wr_rs=1;
				wr_en=1;
				end
			atfh_3 :begin
				wr_cmd=dram[3];
				wr_rs=1;
				wr_en=1;
				end
			atfh_4 :begin
				wr_cmd=dram[4];
				wr_rs=1;
				wr_en=1;
				end
			atfh_5 :begin
				wr_cmd=dram[5];
				wr_rs=1;
				wr_en=1;
				end
			atfh_6 :begin
				wr_cmd=dram[6];
				wr_rs=1;
				wr_en=1;
				end
			atfh_7 :begin
				wr_cmd=dram[7];
				wr_rs=1;
				wr_en=1;
				end
			atfh_8 :begin
				wr_cmd=dram[8];
				wr_rs=1;
				wr_en=1;
				end
			atfh_9 :begin
				wr_cmd=dram[9];
				wr_rs=1;
				wr_en=1;
				end
			atfh_10:begin
				wr_cmd=dram[10];
				wr_rs=1;
				wr_en=1;
				end
			atfh_11:begin
				wr_cmd=dram[11];
				wr_rs=1;
				wr_en=1;
				end
			atfh_12:begin
				wr_cmd=dram[12];
				wr_rs=1;
				wr_en=1;
				end
			atfh_13:begin
				wr_cmd=dram[13];
				wr_rs=1;
				wr_en=1;
				end
			atfh_14:begin
				wr_cmd=dram[14];
				wr_rs=1;
				wr_en=1;
				end
			atfh_15:begin
				wr_cmd=dram[15];
				wr_rs=1;
				wr_en=1;
				end
			atfh_l2:begin
				wr_cmd=8'hc0;
				wr_rs=0;
				wr_en=1;
				end
			atfh_16:begin
				wr_cmd=dram[16];
				wr_rs=1;
				wr_en=1;
				end
			atfh_17:begin
				wr_cmd=dram[17];
				wr_rs=1;
				wr_en=1;
				end
			atfh_18:begin
				wr_cmd=dram[18];
				wr_rs=1;
				wr_en=1;
				end
			atfh_19:begin
				wr_cmd=dram[19];
				wr_rs=1;
				wr_en=1;
				end
			atfh_20:begin
				wr_cmd=dram[20];
				wr_rs=1;
				wr_en=1;
				end
			atfh_21:begin
				wr_cmd=dram[21];
				wr_rs=1;
				wr_en=1;
				end
			atfh_22:begin
				wr_cmd=dram[22];
				wr_rs=1;
				wr_en=1;
				end
			atfh_23:begin
				wr_cmd=dram[23];
				wr_rs=1;
				wr_en=1;
				end
			atfh_24:begin
				wr_cmd=dram[24];
				wr_rs=1;
				wr_en=1;
				end
			atfh_25:begin
				wr_cmd=dram[25];
				wr_rs=1;
				wr_en=1;
				end
			atfh_26:begin
				wr_cmd=dram[26];
				wr_rs=1;
				wr_en=1;
				end
			atfh_27:begin
				wr_cmd=dram[27];
				wr_rs=1;
				wr_en=1;
				end
			atfh_28:begin
				wr_cmd=dram[28];
				wr_rs=1;
				wr_en=1;
				end
			atfh_29:begin
				wr_cmd=dram[29];
				wr_rs=1;
				wr_en=1;
				end
			atfh_30:begin
				wr_cmd=dram[30];
				wr_rs=1;
				wr_en=1;
				end
			atfh_31:begin
				wr_cmd=dram[31];
				wr_rs=1;
				wr_en=1;
				end
			default:begin
				wr_cmd=0;
				wr_rs=0;
				wr_en=0;
				end
			endcase
		end
	end



//时钟分频器
clk_gen #(
	.CLK_F(CLK_F)
)inst_clk_gen
(	
	.clk(clk), 
	.rst_n(rst_n), 
	.clk_en(clk_en)
);

endmodule