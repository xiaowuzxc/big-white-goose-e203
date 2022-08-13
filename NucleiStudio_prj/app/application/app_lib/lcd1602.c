#include "lcd1602.h"

/*
   lcd1602_write_char
   向LCD1602指定位置写入指定字符
   参数：
   x ：从左往右数，写入位置的列数，有效范围[0,15]
   y ：从上往下数，写入位置的行数，有效范围[0, 1]
   char_ascii ：写入的字符，传入对应的ASCII码
   返回值：
   0 ：输入地址无效
   1 ：写入成功
*/
uint32_t lcd1602_write_char(uint8_t x,uint8_t y,uint8_t char_ascii)
{
	volatile uint32_t lcd_addr;
    if (x>15 || y>1)
    {
        return 0;
    }
    else
    {
        lcd_addr=x|(y<<4);
        lcd_addr=lcd_addr<<2;
        LCD_REGISTER(lcd_addr)=char_ascii;
        return 1;
    }
}

/*
   lcd1602_read_char
   读取LCD1602指定位置的字符
   参数：
   x ：从左往右数，读取位置的列数，有效范围[0,15]
   y ：从上往下数，读取位置的行数，有效范围[0, 1]
   返回值：
   指定位置的字符
*/
uint32_t lcd1602_read_char(uint8_t x,uint8_t y)
{
    volatile uint32_t lcd_addr;
    lcd_addr=x|(y<<4);
    lcd_addr=lcd_addr<<2;
    return LCD_REGISTER(lcd_addr); 
}

/*
   lcd1602_clear
   全部清屏
*/
void lcd1602_clear()
{
	lcd1602_write_char(0,0,' ');//y=0
	lcd1602_write_char(1,0,' ');
	lcd1602_write_char(2,0,' ');
	lcd1602_write_char(3,0,' ');
	lcd1602_write_char(4,0,' ');
	lcd1602_write_char(5,0,' ');
	lcd1602_write_char(6,0,' ');
	lcd1602_write_char(7,0,' ');
	lcd1602_write_char(8,0,' ');
	lcd1602_write_char(9,0,' ');
	lcd1602_write_char(10,0,' ');
	lcd1602_write_char(11,0,' ');
	lcd1602_write_char(12,0,' ');
	lcd1602_write_char(13,0,' ');
	lcd1602_write_char(14,0,' ');
	lcd1602_write_char(15,0,' ');
	lcd1602_write_char(0,1,' ');//y=1
	lcd1602_write_char(1,1,' ');
	lcd1602_write_char(2,1,' ');
	lcd1602_write_char(3,1,' ');
	lcd1602_write_char(4,1,' ');
	lcd1602_write_char(5,1,' ');
	lcd1602_write_char(6,1,' ');
	lcd1602_write_char(7,1,' ');
	lcd1602_write_char(8,1,' ');
	lcd1602_write_char(9,1,' ');
	lcd1602_write_char(10,1,' ');
	lcd1602_write_char(11,1,' ');
	lcd1602_write_char(12,1,' ');
	lcd1602_write_char(13,1,' ');
	lcd1602_write_char(14,1,' ');
	lcd1602_write_char(15,1,' ');
}
