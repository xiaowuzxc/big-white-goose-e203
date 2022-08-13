#ifndef _APP_NICE_H
#define _APP_NICE_H
#include <stdio.h>
#include "hbirdv2.h"
//cordic
uint32_t nice_cordic(uint32_t phase);
//角度/度=phase/65536*360
//phase=弧度/pi*65536
//float cos(phase)=cossin[31:16]/32768
//float sin(phase)=cossin[15: 0]/32768
//cnn
uint32_t nice_cnn();
//cordic测试
void nice_test();
#endif /* _CORDIC_NICE_H */
