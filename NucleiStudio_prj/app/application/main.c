// See LICENSE for license details.
#include <stdio.h>
#include <time.h>
#include <stdlib.h>
#include "hbird_sdk_soc.h"
#include "dma.h"
#include "RVB_isa_test.h"
#include "usb.h"
#include "app_nice.h"
#include "addac.h"
#include "lcd1602.h"

int main(void)
{
	//sim
/*
	lcd1602_clear();
	lcd1602_write_char(0,0,'C');//y=0
	delay_1ms(300);
	lcd1602_write_char(1,0,'I');
	delay_1ms(300);
	lcd1602_write_char(2,0,'C');
	delay_1ms(300);
	lcd1602_write_char(3,0,'C');
	delay_1ms(300);
	lcd1602_write_char(4,0,'1');
	delay_1ms(300);
	lcd1602_write_char(5,0,'2');
	delay_1ms(300);
	lcd1602_write_char(6,0,'3');
	delay_1ms(300);
	lcd1602_write_char(7,0,'3');
	delay_1ms(300);
	lcd1602_write_char(8,0,'-');
	delay_1ms(300);
	lcd1602_write_char(9,0,'D');
	delay_1ms(300);
	lcd1602_write_char(10,0,'e');
	delay_1ms(300);
	lcd1602_write_char(11,0,'b');
	delay_1ms(300);
	lcd1602_write_char(12,0,'u');
	delay_1ms(300);
	lcd1602_write_char(13,0,'g');
	delay_1ms(300);
	lcd1602_write_char(14,0,'!');
	lcd1602_write_char(15,0,' ');
	delay_1ms(300);
	lcd1602_write_char(0,1,'R');//y=1
	delay_1ms(300);
	lcd1602_write_char(1,1,'V');
	delay_1ms(300);
	lcd1602_write_char(2,1,'3');
	delay_1ms(300);
	lcd1602_write_char(3,1,'2');
	delay_1ms(300);
	lcd1602_write_char(4,1,'I');
	delay_1ms(300);
	lcd1602_write_char(5,1,'M');
	delay_1ms(300);
	lcd1602_write_char(6,1,'A');
	delay_1ms(300);
	lcd1602_write_char(7,1,'B');
	delay_1ms(300);
	lcd1602_write_char(8,1,'C');
	delay_1ms(300);
	lcd1602_write_char(9,1,' ');
	lcd1602_write_char(10,1,' ');
	lcd1602_write_char(11,1,'E');
	delay_1ms(300);
	lcd1602_write_char(12,1,'2');
	delay_1ms(300);
	lcd1602_write_char(13,1,'0');
	delay_1ms(300);
	lcd1602_write_char(14,1,'3');
	lcd1602_write_char(15,1,' ');
	delay_1ms(300);
*/
	//delay_1ms(10000);
	gpio_iof_config(GPIOA, 0x00300000);//配置Yduck_IOF
	dma_init();
	Yduck_prog();
	Yduck_CTR(1);

	//DAC
	printf("DAC out\r\n");
	addac_model_sel(1);
	addac_dac_out(75);
	//ADC
	printf("ADC model\r\n");
	addac_model_sel(0);
	addac_ch_sel(3);
	printf("ADC Ch=3, 2.5V Voltage Reference TL431\r\n");

	printf("ADC value=%d, ADC vol=%f\r\n",addac_get_value(),(3.3*addac_get_value()/255));
	//DAC
	printf("DAC out\r\n");
	addac_model_sel(1);
	addac_dac_out(75);
	printf("DAC value=%d, DAC vol=0.97v\r\n",75);

	//nice
	nice_test();
    //isa
    Show_misa();
    //dma
    if(dma_test())
        printf("***dma test pass!***\r\n");
    else
        printf("***dma test error!***\r\n");
    //B ex
    RVB_isa_test();

    //delay
    delay_1ms(200);
    uint8_t cnn_out;
    while(1)
    {
    	cnn_out=nice_cnn();
    	printf("CNN Nub=%d  ",cnn_out);
    	if(cnn_out>=10)
    		printf("can't recognize number");
    	printf("\r\n");
    	delay_1ms(200);
    }

    return 0;
}

