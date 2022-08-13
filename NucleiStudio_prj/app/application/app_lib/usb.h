#ifndef _USB_H
#define _USB_H
#include <stdio.h>
#include "hbirdv2.h"

#define sim_model

//USB func
uint32_t usb_send_check();
uint32_t usb_recv_check();
void usb_send_data(uint32_t send_data);
uint32_t usb_recv_data();
//USB base
#define USB_BASE 0xf0000100
//USB offset
#define USB_STA     0X00
#define USB_REV     0X04
#define USB_SED     0X08
//USB_STA 状态查询,[0]接收区有东西为1,[1]发送区未满为1
//USB_REV 接收缓冲区[7:0]只读
//USB_SED 发送缓冲器[7:0]只写

//MAP
#define USB_REGISTER(addr) (*((volatile uint32_t *)(USB_BASE+(addr))))
#endif /* _USB_H */
