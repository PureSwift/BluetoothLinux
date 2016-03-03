//
//  BluetoothProtocol.swift
//  BluetoothLinux
//
//  Created by Alsey Coleman Miller on 3/1/16.
//  Copyright © 2016 PureSwift. All rights reserved.
//

/// BTPROTO_*
public enum BluetoothProtocol: CInt {
    
    case L2CAP      = 0
    case HCI        = 1
    case SCO        = 2
    case RFCOMM     = 3
    case BNEP       = 4
    case CMTP       = 5
    case HIDP       = 6
    case AVDTP      = 7
}