//
//  LinkMode.swift
//  BluetoothLinux
//
//  Created by Alsey Coleman Miller on 1/15/16.
//  Copyright © 2016 PureSwift. All rights reserved.
//

import Foundation

public enum LinkMode: UInt16 {
    
    case accept         = 0x8000
    case master         = 0x0001
    case authenticated  = 0x0002
    case encrypted      = 0x0004
    case trusted        = 0x0008
    case reliable       = 0x0010
    case secure         = 0x0020
}
