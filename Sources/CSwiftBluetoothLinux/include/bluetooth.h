/*
 *
 *  Swift Bluetooth Linux Stack
 *  MIT License
 *  PureSwift
 *
 */

#include <stdint.h>
#include <sys/ioctl.h>

static inline int swift_bluetooth_ioctl(int fd, unsigned long int request, void *pointer)
{
    return ioctl(fd, request, pointer);
}

static inline void swift_bluetooth_hci_set_bit(int nr, void *addr)
{
    *((uint32_t *) addr + (nr >> 5)) |= (1 << (nr & 31));
}
