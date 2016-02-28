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

/*
public extension BluezUUID {
    
    public init(_ value: UInt16) {
        
        var uuid = bt_uuid_t()
        
        bt_uuid16_create(&uuid, value)
        
        self = uuid
    }
    
    public init(_ value: UInt32) {
        
        var uuid = bt_uuid_t()
        
        bt_uuid32_create(&uuid, value)
        
        self = uuid
    }
    
    // https://bugs.swift.org/browse/SR-847
    /*
    public init(_ value: UInt128) {
        
        var uuid = bt_uuid_t()
    
        bt_uuid128_create(&uuid, value)
    
        self = uuid
    
    }*/
}
*/

/// Type of Bluetooth UUID.
public enum UUIDType: Int {
    
    case Bit16      = 16
    case Bit32      = 32
    case Bit128     = 128
}

// MARK: - Darwin Stubs

#if os(OSX) || os(iOS)
    
    let MAX_LEN_UUID_STR: CInt = 37
    
    public struct bt_uuid_t {
        
        public init() { stub() }
    }
    
    func bt_uuid16_create(btuuid: UnsafeMutablePointer<bt_uuid_t>, _ value: UInt16) -> CInt { stub() }
    
    func bt_uuid32_create(btuuid: UnsafeMutablePointer<bt_uuid_t>, _ value: UInt32) -> CInt { stub() }
    
    //func bt_uuid128_create(btuuid: UnsafeMutablePointer<bt_uuid_t>, _ value: UInt128) -> CInt { stub() }
    
    

#endif

