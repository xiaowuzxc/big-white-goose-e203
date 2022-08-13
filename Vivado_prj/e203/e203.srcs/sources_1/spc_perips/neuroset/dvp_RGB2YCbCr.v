/*-----------------------------------------------------------------------
								 \\\|///
							   \\  - -  //
								(  @ @  )
+-----------------------------oOOo-(_)-oOOo-----------------------------+
CONFIDENTIAL IN CONFIDENCE
This confidential and proprietary software may be only used as authorized
by a licensing agreement from CrazyBingo (Thereturnofbingo).
In the event of publication, the following notice is applicable:
Copyright (C) 2011-20xx CrazyBingo Corporation
The entire notice above must be reproduced on all authorized copies.
Author				:		CrazyBingo
Technology blogs 	: 		http://blog.chinaaet.com/crazybingo
Email Address 		: 		thereturnofbingo@gmail.com
Filename			:		VIP_Sobel_Edge_Detector.v
Data				:		2013-05-26
Description			:		Convert the RGB888 format to YCbCr444 format.
Modification History	:
Data			By			Version			Change Description
=========================================================================
13/05/26		CrazyBingo	1.0				Original
14/03/16		CrazyBingo	2.0				Modification
-------------------------------------------------------------------------
|                                     Oooo								|
+-------------------------------oooO--(   )-----------------------------+
                               (   )   ) /
                                \ (   (_/
                                 \_)
-----------------------------------------------------------------------*/ 

`timescale 1ns/1ns
module dvp_RGB2YCbCr
(
	//global clock
	input				cam_pclk,  				//cmos video pixel clock
	input				rst_n,				//global reset

	//CMOS rgb888 data input
	input				per_frame_vsync,	//Prepared Image data vsync valid signal
	input				per_frame_href,		//Prepared Image data href vaild  signal
	input				per_frame_clken,	//Prepared Image data output/capture enable clock	
	input		[7:0]	per_img_red,		//Prepared Image red data to be processed
	input		[7:0]	per_img_green,		//Prepared Image green data to be processed
	input		[7:0]	per_img_blue,		//Prepared Image blue data to be processed
	
	//CMOS YCbCr444 data output
	output				post_frame_vsync,	//Processed Image data vsync valid signal
	output				post_frame_href,	//Processed Image data href vaild  signal
	output				post_frame_clken,	//Processed Image data output/capture enable clock	
	output		[15:0]  cmos_mask_data,
	output		[7:0]	post_img_Y,			//Processed Image brightness output
	output		[7:0]	post_img_Cb,		//Processed Image blue shading output
	output		[7:0]	post_img_Cr			//Processed Image red shading output
);

//--------------------------------------------
/*********************************************
//Refer to <OV7725 Camera Module Software Applicaton Note> page 5
	Y 	=	(77 *R 	+ 	150*G 	+ 	29 *B)>>8
	Cb 	=	(-43*R	- 	85 *G	+ 	128*B)>>8 + 128
	Cr 	=	(128*R 	-	107*G  	-	21 *B)>>8 + 128
--->
	Y 	=	(77 *R 	+ 	150*G 	+ 	29 *B)>>8
	Cb 	=	(-43*R	- 	85 *G	+ 	128*B + 32768)>>8
	Cr 	=	(128*R 	-	107*G  	-	21 *B + 32768)>>8
**********************************************/
//Step 1
reg	[15:0]	img_red_r0,		img_red_r1,		img_red_r2;	
reg	[15:0]	img_green_r0,	img_green_r1,	img_green_r2; 
reg	[15:0]	img_blue_r0,	img_blue_r1,	img_blue_r2; 
always@(posedge cam_pclk or negedge rst_n)
begin
	if(!rst_n)
		begin
		img_red_r0		<=	0; 		
		img_red_r1		<=	0; 		
		img_red_r2		<=	0; 	
		img_green_r0	<=	0; 		
		img_green_r1	<=	0; 		
		img_green_r2	<=	0; 	
		img_blue_r0		<=	0; 		
		img_blue_r1		<=	0; 		
		img_blue_r2		<=	0; 			
		end
	else
		begin
		img_red_r0		<=	per_img_red 	* 	8'd77; 		
		img_red_r1		<=	per_img_red 	* 	8'd43; 	
		img_red_r2		<=	per_img_red 	* 	8'd128; 		
		img_green_r0	<=	per_img_green 	* 	8'd150; 		
		img_green_r1	<=	per_img_green 	* 	8'd85; 			
		img_green_r2	<=	per_img_green 	* 	8'd107; 
		img_blue_r0		<=	per_img_blue 	* 	8'd29; 		
		img_blue_r1		<=	per_img_blue 	* 	8'd128; 			
		img_blue_r2		<=	per_img_blue 	* 	8'd21; 		
		end
end

//--------------------------------------------------
//Step 2
reg	[15:0]	img_Y_r0;	
reg	[15:0]	img_Cb_r0; 
reg	[15:0]	img_Cr_r0; 
always@(posedge cam_pclk or negedge rst_n)
begin
	if(!rst_n)
		begin
		img_Y_r0	<=	0; 		
		img_Cb_r0	<=	0; 		
		img_Cr_r0	<=	0; 	
		end
	else
		begin
		img_Y_r0	<=	img_red_r0 	+ 	img_green_r0 	+ 	img_blue_r0; 		
		img_Cb_r0	<=	img_blue_r1 - 	img_red_r1 		- 	img_green_r1	+	16'd32768; 		
		img_Cr_r0	<=	img_red_r2 	+ 	img_green_r2 	+ 	img_blue_r2		+	16'd32768; 		
		end
end

//--------------------------------------------------
//Step 3
reg	[7:0]	img_Y_r1;	
reg	[7:0]	img_Cb_r1; 
reg	[7:0]	img_Cr_r1; 
always@(posedge cam_pclk or negedge rst_n)
begin
	if(!rst_n)
		begin
		img_Y_r1	<=	0; 		
		img_Cb_r1	<=	0; 		
		img_Cr_r1	<=	0; 	
		end
	else
		begin
		img_Y_r1	<=	img_Y_r0[15:8];
		img_Cb_r1	<=	img_Cb_r0[15:8];
		img_Cr_r1	<=	img_Cr_r0[15:8]; 
		end
end



//------------------------------------------
//lag 3 clocks signal sync  
reg	[2:0]	per_frame_vsync_r;
reg	[2:0]	per_frame_href_r;	
reg	[2:0]	per_frame_clken_r;
always@(posedge cam_pclk or negedge rst_n)
begin
	if(!rst_n)
		begin
		per_frame_vsync_r <= 0;
		per_frame_href_r <= 0;
		per_frame_clken_r <= 0;
		end
	else
		begin
		per_frame_vsync_r 	<= 	{per_frame_vsync_r[1:0], 	per_frame_vsync};
		per_frame_href_r 	<= 	{per_frame_href_r[1:0], 	per_frame_href};
		per_frame_clken_r 	<= 	{per_frame_clken_r[1:0], 	per_frame_clken};
		end
end
assign	post_frame_vsync 	= 	per_frame_vsync_r[2];
assign	post_frame_href 	= 	per_frame_href_r[2];
assign	post_frame_clken 	= 	per_frame_clken_r[2];
assign	post_img_Y 	= 	img_Y_r1 ;
assign	post_img_Cb =	img_Cb_r1;
assign	post_img_Cr = 	img_Cr_r1;


//cmos_frame_vsync edge
reg post_frame_vsync_r0 ;
reg post_frame_vsync_r1;
wire post_frame_vsync_nege ;

always@(posedge cam_pclk or negedge rst_n)
begin
	if(!rst_n)begin
		post_frame_vsync_r0 <= 'd0 ;
		post_frame_vsync_r1 <= 'd0 ;	
	end
	else begin
		post_frame_vsync_r0 <= post_frame_vsync ;
		post_frame_vsync_r1 <= post_frame_vsync_r0 ;			
	end
end

assign post_frame_vsync_nege = (post_frame_vsync_r1&&~post_frame_vsync_r0)?1'b1:1'b0 ;

reg mask_change ;
always@(posedge cam_pclk or negedge rst_n)
begin
	if(!rst_n)
		mask_change <= 1'b0 ;
	else if(post_frame_vsync_nege)
		mask_change <= ~ mask_change ;
	else
		mask_change <= mask_change ;
end


assign cmos_mask_data = (mask_change == 1'b0)?{8'hZ,post_img_Y}:{post_img_Y,8'hZ};


endmodule
