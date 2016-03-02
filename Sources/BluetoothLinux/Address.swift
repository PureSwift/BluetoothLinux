//
//  Address.swift
//  BluetoothLinux
//
//  Created by Alsey Coleman Miller on 12/6/15.
//  Copyright © 2015 PureSwift. All rights reserved.
//

#if os(Linux)
    import Glibc
#elseif os(OSX) || os(iOS)
    import Darwin.C
#endif

import SwiftFoundation


/// Bluetooth Address type.
public struct Address: ByteValueType {
    
    // MARK: - ByteValueType
    
    /// Raw Bluetooth Address 6 byte (48 bit) value.
    public typealias ByteValue = (UInt8, UInt8, UInt8, UInt8, UInt8, UInt8)
    
    // MARK: - Properties
    
    public var byteValue: ByteValue
    
    // MARK: - Initialization
    
    public init(byteValue: ByteValue = (0,0,0,0,0,0)) {
        
        self.byteValue = byteValue
    }
}

// MARK: - RawRepresentable

extension Address: RawRepresentable {
    
    public init?(rawValue: String) {
        
        self.byteValue = (0,0,0,0,0,0)
        
        fatalError("Bluetooth address parsing not implemented")
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

public func == (lhs: Address, rhs: Address) -> Bool {
    
    return lhs.byteValue.0 == rhs.byteValue.0
        && lhs.byteValue.1 == rhs.byteValue.1
        && lhs.byteValue.2 == rhs.byteValue.2
        && lhs.byteValue.3 == rhs.byteValue.3
        && lhs.byteValue.4 == rhs.byteValue.4
        && lhs.byteValue.5 == rhs.byteValue.5
}

// MARK: - CustomStringConvertible

extension Address: CustomStringConvertible {
    
    public var description: String { return rawValue }
}

// MARK: - Adapter Extensions

public extension Address {
    
    /// Extracts the Bluetooth address from the device ID.
    public init(deviceIdentifier: CInt) throws {
        
        self = try HCIDeviceAddress(deviceIdentifier)
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
    
    /// Attempts to get the device address.
    func hci_devba(dev_id: CInt, _ bdaddr: UnsafeMutablePointer<bdaddr_t>) -> CInt { stub() }
    
#endif

