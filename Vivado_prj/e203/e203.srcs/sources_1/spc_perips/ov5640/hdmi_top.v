//****************************************Copyright (c)***********************************//
//ԭ�Ӹ����߽�ѧƽ̨��www.yuanzige.com
//����֧�֣�www.openedv.com
//�Ա����̣�http://openedv.taobao.com
//��ע΢�Ź���ƽ̨΢�źţ�"����ԭ��"����ѻ�ȡZYNQ & FPGA & STM32 & LINUX���ϡ�
//��Ȩ���У�����ؾ���
//Copyright(C) ����ԭ�� 2018-2028
//All rights reserved
//----------------------------------------------------------------------------------------
// File name:           hdmi_top
// Last modified Date:  2020/05/04 9:19:08
// Last Version:        V1.0
// Descriptions:        HDMI��ʾ����ģ��
//                      
//----------------------------------------------------------------------------------------
// Created by:          ����ԭ��
// Created date:        2019/05/04 9:19:08
// Version:             V1.0
// Descriptions:        The original version
//
//----------------------------------------------------------------------------------------
//****************************************************************************************//

module  hdmi_top(
    input           pixel_clk,
    input           pixel_clk_5x,    
    input           sys_rst_n,
   //hdmi�ӿ�   
    output          tmds_clk_p,     // TMDS ʱ��ͨ��
    output          tmds_clk_n,
    output [2:0]    tmds_data_p,    // TMDS ����ͨ��
    output [2:0]    tmds_data_n,
    output          tmds_oen ,      // TMDS ���ʹ��
   //�û��ӿ� 
    output          video_vs,       //HDMI���ź�      
    output  [10:0]  h_disp,         //HDMI��ˮƽ�ֱ���
    output  [10:0]  v_disp,         //HDMI����ֱ�ֱ��� 
    output  [10:0]  pixel_xpos,     //���ص������
    output  [10:0]  pixel_ypos,     //���ص�������      
    input   [15:0]  data_in,        //��������
    output          data_req        //������������   
);

//wire define
wire          pixel_clk;
wire          pixel_clk_5x;
wire          clk_locked;
wire   [2:0]  tmds_data_p;   
wire   [2:0]  tmds_data_n;
wire  [10:0]  pixel_xpos;
wire  [10:0]  pixel_ypos;
wire  [10:0]  h_disp;
wire  [10:0]  v_disp;
wire          video_hs;
wire          video_vs;
wire          video_de;
wire  [23:0]  video_rgb;
wire  [23:0]  video_rgb_565;

//*****************************************************
//**                    main code
//*****************************************************


//������ͷ16bit����ת��Ϊ24bit��hdmi����
assign video_rgb = {video_rgb_565[15:11],3'b000,video_rgb_565[10:5],2'b00,
                    video_rgb_565[4:0],3'b000};  

//������Ƶ��ʾ����ģ��
video_driver u_video_driver(
    .pixel_clk      (pixel_clk),
    .sys_rst_n      (sys_rst_n),

    .video_hs       (video_hs),
    .video_vs       (video_vs),
    .video_de       (video_de),
    .video_rgb      (video_rgb_565),
   
    .data_req       (data_req),
    .h_disp         (h_disp),
    .v_disp         (v_disp), 
    .pixel_xpos     (pixel_xpos),
    .pixel_ypos     (pixel_ypos),
    .pixel_data     (data_in)
    );
       
//����HDMI����ģ��
dvi_transmitter_top u_rgb2dvi_0(
    .pclk           (pixel_clk),
    .pclk_x5        (pixel_clk_5x),
    .reset_n        (sys_rst_n),
                
    .video_din      (video_rgb),
    .video_hsync    (video_hs), 
    .video_vsync    (video_vs),
    .video_de       (video_de),
                
    .tmds_clk_p     (tmds_clk_p),
    .tmds_clk_n     (tmds_clk_n),
    .tmds_data_p    (tmds_data_p),
    .tmds_data_n    (tmds_data_n), 
    .tmds_oen       (tmds_oen)
    );

endmodule 