/* See LICENSE of license details. */
#include <stdint.h>
#include <errno.h>
#include <unistd.h>
#include <sys/types.h>
#include <hbird_sdk_hal.h>
#include "usb.h"
__WEAK ssize_t _write(int fd, const void* ptr, size_t len)
{
    if (!isatty(fd)) {
        return -1;
    }

    const uint8_t *writebuf = (const uint8_t *)ptr;
    for (size_t i = 0; i < len; i++) {
        //uart_write(SOC_DEBUG_UART, writebuf[i]);
        usb_send_data(writebuf[i]);
    }
    return len;
}
