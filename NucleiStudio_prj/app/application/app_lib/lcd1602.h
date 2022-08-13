#ifndef _LCD1602_H
#define _LCD1602_H
#include <stdio.h>
#include "hbirdv2.h"
//LCD1602 func
uint32_t lcd1602_write_char(uint8_t x,uint8_t y,uint8_t char_ascii);
uint32_t lcd1602_read_char(uint8_t x,uint8_t y);
void lcd1602_clear();
//LCD1602 base
#define LCD_BASE 0xf0000300

//MAP
#define LCD_REGISTER(addr) (*((volatile uint32_t *)(LCD_BASE+(addr))))
#endif /* _LCD1602_H */
