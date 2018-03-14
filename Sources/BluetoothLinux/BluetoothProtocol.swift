//
//  BluetoothProtocol.swift
//  BluetoothLinux
//
//  Created by Alsey Coleman Miller on 3/1/16.
//  Copyright © 2016 PureSwift. All rights reserved.
//

/// BTPROTO_*
public enum BluetoothProtocol: CInt {
    
    case l2cap      = 0
    case hci        = 1
    case sco        = 2
    case rfcomm     = 3
    case bnep       = 4
    case cmtp       = 5
    case hidp       = 6
    case avdtp      = 7
}
