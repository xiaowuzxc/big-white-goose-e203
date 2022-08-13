//****************************************Copyright (c)***********************************//
//ԭ�Ӹ����߽�ѧƽ̨��www.yuanzige.com
//����֧�֣�www.openedv.com
//�Ա����̣�http://openedv.taobao.com
//��ע΢�Ź���ƽ̨΢�źţ�"����ԭ��"����ѻ�ȡZYNQ & FPGA & STM32 & LINUX���ϡ�
//��Ȩ���У�����ؾ���
//Copyright(C) ����ԭ�� 2018-2028
//All rights reserved
//----------------------------------------------------------------------------------------
// File name:           ddr3_fifo_ctrl
// Last modified Date:  2020/05/04 9:19:08
// Last Version:        V1.0
// Descriptions:        ddr3������fifo����ģ��
//                      
//----------------------------------------------------------------------------------------
// Created by:          ����ԭ��
// Created date:        2019/05/04 9:19:08
// Version:             V1.0
// Descriptions:        The original version
//
//----------------------------------------------------------------------------------------
//****************************************************************************************//

`timescale 1ns / 1ps
module ddr3_fifo_ctrl(
    input           rst_n            ,  //��λ�ź�
    input           wr_clk           ,  //wfifoʱ��
    input           rd_clk           ,  //rfifoʱ��
    input           clk_100          ,  //�û�ʱ��
    input           datain_valid     ,  //������Чʹ���ź�
    input  [15:0]   datain           ,  //��Ч����
    input  [127:0]  rfifo_din        ,  //�û�������
    input           rdata_req        ,  //�������ص���ɫ�������� 
    input           rfifo_wren       ,  //��ddr3�������ݵ���Чʹ��
    input           wfifo_rden       ,  //wfifo��ʹ��
    input           rd_load          ,  //���Դ���ź�
    input           wr_load          ,  //����Դ���ź�          

    output [127:0]  wfifo_dout       ,  //�û�д����
    output [10:0]   wfifo_rcount     ,  //rfifoʣ�����ݼ���
    output [10:0]   rfifo_wcount     ,  //wfifoд�����ݼ���
    output [15:0]   pic_data            //��Ч����     	
    );
           
//reg define
reg  [127:0] datain_t          ;  //��16bit����Դ������λƴ�ӵõ�
reg  [7:0]   cam_data_d0       ; 
reg  [4:0]   i_d0              ;
reg  [15:0]  rd_load_d         ;  //�����Դ���ź���λƴ�ӵõ�           
reg  [6:0]   byte_cnt          ;  //д������λ������
reg  [127:0] data              ;  //rfifo������ݴ��ĵõ�
reg  [15:0]  pic_data          ;  //��Ч���� 
reg  [4:0]   i                 ;  //��������λ������
reg  [15:0]  wr_load_d         ;  //������Դ���ź���λƴ�ӵõ� 
reg  [3:0]   cmos_ps_cnt       ;  //�ȴ�֡���ȶ�������
reg          cam_href_d0       ;
reg          cam_href_d1       ;
reg          wr_load_d0        ;
reg          rd_load_d0        ;
reg          rdfifo_rst_h      ;  //rfifo��λ�źţ�����Ч
reg          wr_load_d1        ;
reg          wfifo_rst_h       ;  //wfifo��λ�źţ�����Ч
reg          wfifo_wren        ;  //wfifoдʹ���ź�

//wire define 
wire [127:0] rfifo_dout        ;  //rfifo�������    
wire [127:0] wfifo_din         ;  //wfifoд����
wire [15:0]  dataout[0:15]     ;  //����������ݵĶ�ά����
wire         rfifo_rden        ;  //rfifo�Ķ�ʹ��

//*****************************************************
//**                    main code
//*****************************************************  

//rfifo��������ݴ浽��ά����
assign dataout[0] = data[127:112];
assign dataout[1] = data[111:96];
assign dataout[2] = data[95:80];
assign dataout[3] = data[79:64];
assign dataout[4] = data[63:48];
assign dataout[5] = data[47:32];
assign dataout[6] = data[31:16];
assign dataout[7] = data[15:0];

assign wfifo_din = datain_t ;

//��λ�Ĵ�������ʱ����rfifo����һ������
assign rfifo_rden = (rdata_req && (i==7)) ? 1'b1  :  1'b0; 

//16λ����ת128λRGB565����        
always @(posedge wr_clk or negedge rst_n) begin
    if(!rst_n) begin
        datain_t <= 0;
        byte_cnt <= 0;
    end
    else if(datain_valid) begin
        if(byte_cnt == 7)begin
            byte_cnt <= 0;
            datain_t <= {datain_t[111:0],datain};
        end
        else begin
            byte_cnt <= byte_cnt + 1;
            datain_t <= {datain_t[111:0],datain};
        end
    end
    else begin
        byte_cnt <= byte_cnt;
        datain_t <= datain_t;
    end    
end 

//wfifoдʹ�ܲ���
always @(posedge wr_clk or negedge rst_n) begin
    if(!rst_n) 
        wfifo_wren <= 0;
    else if(wfifo_wren == 1)
        wfifo_wren <= 0;
    else if(byte_cnt == 7 && datain_valid )  //����Դ���ݴ���8�Σ�дʹ������һ��
        wfifo_wren <= 1;
    else 
        wfifo_wren <= 0;
 end
     
always @(posedge rd_clk or negedge rst_n) begin
    if(!rst_n)
        data <= 127'b0;
    else 
        data <= rfifo_dout; 
end     

//��rfifo������128bit���ݲ���16��16bit����
always @(posedge rd_clk or negedge rst_n) begin
    if(!rst_n) begin
        pic_data <= 16'b0;
        i <=0;
        i_d0 <= 0;
    end
    else if(rdata_req) begin
        if(i == 7)begin
            pic_data <= dataout[i_d0];
            i <= 0;
            i_d0 <= i;
        end
        else begin
            pic_data <= dataout[i_d0];
            i <= i + 1;
            i_d0 <= i;
        end
    end 
    else begin
        pic_data <= pic_data;
        i <=0;
        i_d0 <= 0;
    end
end  

always @(posedge clk_100 or negedge rst_n) begin
    if(!rst_n)
        rd_load_d0 <= 1'b0;
    else
        rd_load_d0 <= rd_load;      
end 

//�����Դ���źŽ�����λ�Ĵ�
always @(posedge clk_100 or negedge rst_n) begin
    if(!rst_n)
        rd_load_d <= 1'b0;
    else
        rd_load_d <= {rd_load_d[14:0],rd_load_d0};       
end 

//����һ�θ�λ��ƽ������fifo��λʱ��  
always @(posedge clk_100 or negedge rst_n) begin
    if(!rst_n)
        rdfifo_rst_h <= 1'b0;
    else if(rd_load_d[0] && !rd_load_d[14])
        rdfifo_rst_h <= 1'b1;   
    else
        rdfifo_rst_h <= 1'b0;              
end  

//������Դ���źŽ�����λ�Ĵ�
 always @(posedge wr_clk or negedge rst_n) begin
    if(!rst_n)begin
        wr_load_d0 <= 1'b0;
        wr_load_d  <= 16'b0;        
    end     
    else begin
        wr_load_d0 <= wr_load;
        wr_load_d <= {wr_load_d[14:0],wr_load_d0};      
    end                 
end  

//����һ�θ�λ��ƽ������fifo��λʱ�� 
 always @(posedge wr_clk or negedge rst_n) begin
    if(!rst_n)
      wfifo_rst_h <= 1'b0;          
    else if(wr_load_d[0] && !wr_load_d[15])
      wfifo_rst_h <= 1'b1;       
    else
      wfifo_rst_h <= 1'b0;                      
end   

rd_fifo u_rd_fifo (
  .rst               (~rst_n|rdfifo_rst_h),                    
  .wr_clk            (clk_100),   
  .rd_clk            (rd_clk),    
  .din               (rfifo_din), 
  .wr_en             (rfifo_wren),
  .rd_en             (rfifo_rden),
  .dout              (rfifo_dout),
  .full              (),          
  .empty             (),          
  .rd_data_count     (),  
  .wr_data_count     (rfifo_wcount),  
  .wr_rst_busy       (),      
  .rd_rst_busy       ()      
);

wr_fifo u_wr_fifo (
  .rst               (~rst_n|wfifo_rst_h),
  .wr_clk            (wr_clk),            
  .rd_clk            (clk_100),           
  .din               (wfifo_din),         
  .wr_en             (wfifo_wren),        
  .rd_en             (wfifo_rden),        
  .dout              (wfifo_dout ),       
  .full              (),                  
  .empty             (),                  
  .rd_data_count     (wfifo_rcount),  
  .wr_data_count     (),  
  .wr_rst_busy       (),      
  .rd_rst_busy       ()    
);

endmodule 

