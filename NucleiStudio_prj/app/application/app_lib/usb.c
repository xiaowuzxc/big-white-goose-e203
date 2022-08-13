#include "usb.h"





//可以发送，返回非0
uint32_t usb_send_check()
{
    return (USB_REGISTER(USB_STA)&0x00000002);
}

//有数据待接收，返回非0
uint32_t usb_recv_check()
{
    return (USB_REGISTER(USB_STA)&0x00000001);
}

void usb_send_data(uint32_t send_data)
{
#ifndef sim_model
	while(!usb_send_check());
#endif
	USB_REGISTER(USB_SED)=send_data;
}

uint32_t usb_recv_data()
{
    return USB_REGISTER(USB_REV);
}
