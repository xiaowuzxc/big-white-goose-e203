#ifndef _ADDAC_H
#define _ADDAC_H
#include <stdio.h>
#include "hbirdv2.h"
//ADDAC func
void addac_model_sel(uint32_t model_sel);
void addac_ch_sel(uint32_t ch_sel);
void addac_start();
uint32_t addac_state();
uint32_t addac_get_value();
void addac_dac_out(uint32_t dac_value);
void Yduck_CTR(uint32_t ctr);
void Yduck_prog();
//ADDAC base
#define ADDA_BASE 0xf0000000
//ADDAC offset
#define ADDA_CTR     0X00
/* [0]:AD DA模式切换, 0:AD, 1:DA
   [1]:启动转换使能，手动清零
   [2]:转换状态查询，高电平可读
   [9:8]:ADC通道选择，输出需翻转*/
#define ADDA_DAT     0X04
/* ADC输出[7:0]
   DAC输出[15:8] */
#define YDUCK         0X08



//MAP
#define ADDA_REGISTER(addr) (*((volatile uint32_t *)(ADDA_BASE+(addr))))
#endif /* _ADDAC_H */
