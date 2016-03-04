//
//  UUID.swift
//  BluetoothLinux
//
//  Created by Alsey Coleman Miller on 3/4/16.
//  Copyright © 2016 PureSwift. All rights reserved.
//

import struct SwiftFoundation.UUID

/// Bluetooth UUID
public enum BluetoothUUID {
    
    case Bit16(UInt16)
    case Bit128(SwiftFoundation.UUID)
}