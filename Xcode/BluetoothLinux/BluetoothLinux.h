//
//  BluetoothLinux.h
//  BluetoothLinux
//
//  Created by Alsey Coleman Miller on 12/6/15.
//  Copyright © 2015 PureSwift. All rights reserved.
//

#import <Foundation/Foundation.h>

//! Project version number for BluetoothLinux.
FOUNDATION_EXPORT double BluetoothLinuxVersionNumber;

//! Project version string for BluetoothLinux.
FOUNDATION_EXPORT const unsigned char BluetoothLinuxVersionString[];

static inline void hci_set_bit(int nr, void *addr)
{
    *((uint32_t *) addr + (nr >> 5)) |= (1 << (nr & 31));
}
