/*
 *
 *  Swift Bluetooth Linux Stack
 *  MIT License
 *  PureSwift
 *
 */

#include <stdint.h>
#include <stdbool.h>

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
