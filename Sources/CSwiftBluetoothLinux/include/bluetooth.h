/*
 *
 *  Swift Bluetooth Linux Stack
 *  MIT License
 *  PureSwift
 *
 */

#include <stdint.h>
#include <sys/ioctl.h>

/**
 @brief Manipulates the underlying device parameters of special files.
 @discussion @c int ioctl(int d, int request, ...);
 @param fd An open file descriptor.
 @param request Device-dependent request code.
 @param pointer Untyped pointer to memory.
 */
static inline int swift_bluetooth_ioctl(int fd, unsigned long int request, void *pointer)
__attribute__((swift_name("InputOutputControl(_:_:_:)")))
{
    return ioctl(fd, request, pointer);
}

/**
 Sets the HCI bit.
 @param bit The bit to set.
 @param destination The targeted value.
 */
static inline void swift_bluetooth_hci_set_bit(int bit, void *destination)
__attribute__((swift_name("HCISetBit(_:_:)")))
{
    *((uint32_t *) destination + (bit >> 5)) |= (1 << (bit & 31));
}
