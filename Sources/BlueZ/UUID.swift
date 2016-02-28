//
//  UUID.swift
//  BlueZ
//
//  Created by Alsey Coleman Miller on 2/28/16.
//  Copyright © 2016 PureSwift. All rights reserved.
//

#if os(Linux)
    import CBlueZ
    import Glibc
#elseif os(OSX) || os(iOS)
    import Darwin.C
#endif

import SwiftFoundation

public typealias BluezUUID = bt_uuid_t

public extension BluezUUID {
    
    public init(_ value: UInt16) {
        
        
    }
    
    public init(_ value: UInt32) {
        
        
    }
    
    /*
    public init(_ value: _uint128_t) {
        
        
    }*/
}

/// Type of Bluetooth UUID.
public enum UUIDType: Int {
    
    case Bit16      = 16
    case Bit32      = 32
    case Bit128     = 128
}

// MARK: - Darwin Stubs

#if os(OSX) || os(iOS)
    
    public struct bt_uuid_t {
        
        public init() { stub() }
    }

#endif