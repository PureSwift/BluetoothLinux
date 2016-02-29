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

/// Bluetooth UUID used with BlueZ.
public struct BluetoothUUID: ByteValueType {
    
    public typealias ByteValue = UUID.ByteValue
    
    public var byteValue: UUID.ByteValue
    
    public init(byteValue: UUID.ByteValue) {
        
        self.byteValue = byteValue
    }
}

/*
public extension BluetoothUUID {
    
    public init?(_ value: UInt16) {
        
        let pointer = UnsafeMutablePointer<bt_uuid_t>.alloc(1)
        
        defer { pointer.dealloc(1) }
        
        bt_uuid16_create(pointer, value)
        
        self.byteValue =
    }
    
    /*
    public init(_ value: UInt32) {
        
        var uuid = bt_uuid_t()
        
        bt_uuid32_create(&uuid, value)
        
        self.byteValue = uuid
    }*/
    
    // https://bugs.swift.org/browse/SR-847
    /*
    public init(_ value: UInt128) {
        
        var uuid = bt_uuid_t()
    
        bt_uuid128_create(&uuid, value)
    
        self = uuid
    
    }*/
}*/

public extension BluetoothUUID {
    
    /// Type of Bluetooth UUID.
    public enum UUIDType: Int {
        
        case Bit16      = 16
        case Bit32      = 32
        case Bit128     = 128
    }
}

// MARK: - Darwin Stubs

#if os(OSX) || os(iOS)
    
    let MAX_LEN_UUID_STR: CInt = 37
    
    public struct bt_uuid_t {
        
        public init() { stub() }
        
        //public var type: CInt
        
        //public var value: UInt128
    }
    
    func bt_uuid16_create(btuuid: UnsafeMutablePointer<bt_uuid_t>, _ value: UInt16) -> CInt { stub() }
    
    func bt_uuid32_create(btuuid: UnsafeMutablePointer<bt_uuid_t>, _ value: UInt32) -> CInt { stub() }
    
    //func bt_uuid128_create(btuuid: UnsafeMutablePointer<bt_uuid_t>, _ value: UInt128) -> CInt { stub() }
    
    

#endif

