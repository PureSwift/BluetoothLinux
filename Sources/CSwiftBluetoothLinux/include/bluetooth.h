/*
 *
 *  Swift Bluetooth Linux Stack
 *  MIT License
 *  PureSwift
 *
 */

#include <stdint.h>
#include <stdbool.h>
#include <sys/ioctl.h>
#include <sys/types.h>
#include <sys/select.h>

/**
 @brief Manipulates the underlying device parameters of special files.
 @discussion @c int ioctl(int d, int request, ...);
 @param fd An open file descriptor.
 @param request Device-dependent request code.
 @param pointer Untyped pointer to memory.
 */
static inline int swift_bluetooth_ioctl_raw(int fd, unsigned long int request, void *pointer)
__attribute__((swift_name("IOControl(_:_:_:)")))
{
    return ioctl(fd, request, pointer);
}

/**
 @brief Manipulates the underlying device parameters of special files.
 @discussion @c int ioctl(int d, int request, ...);
 @param fd An open file descriptor.
 @param request Device-dependent request code.
 @param dev Device identifier.
 */
static inline int swift_bluetooth_ioctl_dev(int fd, unsigned long int request, int dev)
__attribute__((swift_name("IOControl(_:_:_:)")))
{
    return ioctl(fd, request, dev);
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

/**
 A set of file descriptors.
 */
typedef fd_set FileDescriptorSet __attribute__((swift_name("FileDescriptorSet")));

/**
 Initializes a file descriptor set on the stack.
 */
static inline FileDescriptorSet* swift_bluetooth_fd_set_zero(FileDescriptorSet* set)
__attribute__((swift_name("FileDescriptorSet.zero(self:)")))
{
    FD_ZERO(set);
    return set;
}

/**
 Add a given file descriptor to a set.
 @param fd The file descriptor to add to the set.
 @param set The file descriptor set.
 */
static inline void swift_bluetooth_fd_set_add(FileDescriptorSet* set, int fileDescriptor)
__attribute__((swift_name("FileDescriptorSet.add(self:_:)")))
{
    FD_SET(fileDescriptor, set);
}

/**
 Removed a given file descriptor from a set.
 @param fd The file descriptor to add to the set.
 @param set The file descriptor set.
 */
static inline void swift_bluetooth_fd_set_remove(FileDescriptorSet* set, int fileDescriptor)
__attribute__((swift_name("FileDescriptorSet.remove(self:_:)")))
{
    FD_CLR(fileDescriptor, set);
}

/**
 Checks if a file descriptor is part of the set.
 @param fd The file descriptor to to check for membership.
 @param set The targeted value.
 */
static inline bool swift_bluetooth_fd_set_contains(FileDescriptorSet* set, int fileDescriptor)
__attribute__((swift_name("FileDescriptorSet.contains(self:_:)")))
{
    return FD_ISSET(fileDescriptor, set);
}

