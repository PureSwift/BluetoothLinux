//
//  Address.swift
//  BlueZ
//
//  Created by Alsey Coleman Miller on 12/6/15.
//  Copyright © 2015 PureSwift. All rights reserved.
//

#if os(Linux)
    import CBlueZ
#endif

import SwiftFoundation

// MARK: - Typealias

/// Bluetooth Address type.
///
/// Typealias for `bdaddr_t` from the BlueZ C API.
public typealias BluetoothAddress = bdaddr_t

public extension Bluetooth {
    
    typealias Address = BluetoothAddress
}

// MARK: - ByteValue

extension Bluetooth.Address: ByteValueType {
    
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

extension Bluetooth.Address: RawRepresentable {
    
    public init?(rawValue: String) {
        
        let resultPointer = UnsafeMutablePointer<bdaddr_t>.alloc(1)
        defer { resultPointer.dealloc(1) }
        
        guard str2ba(rawValue, resultPointer) == 0 else { return nil }
        
        self = resultPointer.memory
    }
    
    public var rawValue: String {
        
        let stringLength = 18 // 17 characters, nil terminated string
        
        let stringPointer = UnsafeMutablePointer<CChar>.alloc(stringLength)
        defer { stringPointer.dealloc(stringLength) }
        
        var copy = self
        
        ba2str(&copy, stringPointer)
        
        return String.fromCString(stringPointer)!
    }
}

// MARK: - Equatable

extension Bluetooth.Address: Equatable { }

public func == (lhs: Bluetooth.Address, rhs: Bluetooth.Address) {
    
    var copy1 = lhs
    var copy2 = rhs
    
    memcmp(&copy1, &copy2, sizeof(bdaddr_t.self))
}

// MARK: - CustomStringConvertible

extension Bluetooth.Address: CustomStringConvertible {
    
    public var description: String { return rawValue }
}

// MARK: - Adapter Extensions

public extension Bluetooth.Address {
    
    /// Extracts the Bluetooth address from the device ID.
    public init?(deviceIdentifier: CInt) {
        
        var address = bdaddr_t()
        
        guard hci_devba(deviceIdentifier, &address) == 0 else { return nil }
        
        self = address
    }
}

public extension BluetoothAdapter {
    
    /// Attempts to get the address from the underlying Bluetooth hardware. 
    ///
    /// Fails if the Bluetooth adapter was disconnected or hardware failure.
    public var address: Bluetooth.Address? {
        
        return Bluetooth.Address(deviceIdentifier: deviceIdentifier)
    }
}

// MARK: - Darwin Stubs

#if os(OSX) || os(iOS)

    public struct bdaddr_t {
        
        var b: (UInt8, UInt8, UInt8, UInt8, UInt8, UInt8) = (0,0,0,0,0,0)
    }
    
    func str2ba(string: String, _ bytes: UnsafeMutablePointer<bdaddr_t>) -> CInt { stub() }
    
    func ba2str(bytes: UnsafePointer<bdaddr_t>, _ str: UnsafeMutablePointer<CChar>) -> CInt { stub() }
    
    func hci_devba(dev_id: CInt, _ bdaddr: UnsafeMutablePointer<bdaddr_t>) -> CInt { stub() }
    
#endif

