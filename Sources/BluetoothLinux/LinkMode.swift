//
//  LinkMode.swift
//  BluetoothLinux
//
//  Created by Alsey Coleman Miller on 1/15/16.
//  Copyright © 2016 PureSwift. All rights reserved.
//

import SwiftFoundation

public enum LinkMode: UInt16 {
    
    case Accept         = 0x8000
    case Master         = 0x0001
    case Authenticated  = 0x0002
    case Encrypted      = 0x0004
    case Trusted        = 0x0008
    case Reliable       = 0x0010
    case Secure         = 0x0020
}