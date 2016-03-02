//
//  Address.swift
//  BlueZ
//
//  Created by Alsey Coleman Miller on 12/6/15.
//  Copyright © 2015 PureSwift. All rights reserved.
//

#if os(Linux)
    import CBlueZ
    import Glibc
#elseif os(OSX) || os(iOS)
    import Darwin.C
#endif

import SwiftFoundation

// MARK: - Typealias

/// Bluetooth Address type.
///
/// Typealias for `bdaddr_t` from the BlueZ C API.
public typealias Address = bdaddr_t

// MARK: - ByteValue

extension Address: ByteValueType {
    
    /// Raw Bluetooth Address 6 byte (48 bit) value.
    public typealias ByteValue = (UInt8, UInt8, UInt8, UInt8, UInt8, UInt8)
    
    // MARK: - Properties
    
    public var byteValue: ByteValue {
        
        get { return b }
        
        set { self.b = newValue }
    }
    
    // MARK: - Initialization
    
    public init(byteValue: ByteValue) {
        
        self.b = byteValue
    }
}

// MARK: - RawRepresentable

extension Address: RawRepresentable {
    
    public init?(rawValue: String) {
        
        var address = bdaddr_t()
        
        guard str2ba(rawValue, &address) == 0 else { return nil }
        
        self = address
    }
    
    public var rawValue: String {
        
        let bytes = [byteValue.5, byteValue.4, byteValue.3, byteValue.2, byteValue.1, byteValue.0]
        
        var string = ""
        
        for (index, byte) in bytes.enumerate() {
            
            string += byte.toHexadecimal()
            
            if index != bytes.count - 1 {
                
                string += ":"
            }
        }
        
        assert(string.utf8.count == 17)
        
        return string
    }
}

// MARK: - Equatable

extension Address: Equatable { }

public func == (lhs: Address, rhs: Address) {
    
    var copy1 = lhs
    var copy2 = rhs
    
    memcmp(&copy1, &copy2, sizeof(bdaddr_t.self))
}

// MARK: - CustomStringConvertible

extension Address: CustomStringConvertible {
    
    public var description: String { return rawValue }
}

// MARK: - Adapter Extensions

public extension Address {
    
    /// Extracts the Bluetooth address from the device ID.
    public init(deviceIdentifier: CInt) throws {
        
        var address = bdaddr_t()
        
        guard hci_devba(deviceIdentifier, &address) == 0
            else { throw POSIXError.fromErrorNumber! }
        
        self = address
    }
}

public extension Adapter {
    
    /// Attempts to get the address from the underlying Bluetooth hardware. 
    ///
    /// Fails if the Bluetooth adapter was disconnected or hardware failure.
    public var address: Address? {
        
        return try? Address(deviceIdentifier: identifier)
    }
}

// MARK: - Darwin Stubs

#if os(OSX) || os(iOS)

    public struct bdaddr_t {
        
        var b: (UInt8, UInt8, UInt8, UInt8, UInt8, UInt8) = (0,0,0,0,0,0)
        
        init() { }
    }
    
    func str2ba(string: String, _ bytes: UnsafeMutablePointer<bdaddr_t>) -> CInt { stub() }
    
    /// Attempts to get the device address.
    func hci_devba(dev_id: CInt, _ bdaddr: UnsafeMutablePointer<bdaddr_t>) -> CInt { stub() }
    
#endif

