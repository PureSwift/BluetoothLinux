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

public struct Address: ByteValueType {
    
    // MARK: - Properties
    
    public var byteValue: bdaddr_t
    
    // MARK: - Initialization
    
    public init(bytes: bdaddr_t) {
        
        self.byteValue = bytes
    }
}

// MARK: - RawRepresentable

extension Address: RawRepresentable {
    
    public init?(rawValue: String) {
        
        let resultPointer = UnsafeMutablePointer<bdaddr_t>.alloc(1)
        defer { resultPointer.dealloc(1) }
        
        guard str2ba(rawValue, resultPointer) == 0 else { return nil }
        
        self.byteValue = resultPointer.memory
    }
    
    public var rawValue: String {
        
        let stringLength = 18 // 17 characters, nil terminated string
        
        let stringPointer = UnsafeMutablePointer<CChar>.alloc(stringLength)
        defer { stringPointer.dealloc(stringLength) }
        
        var byteValue = self.byteValue
        
        ba2str(&byteValue, stringPointer)
        
        return String.fromCString(stringPointer)!
    }
}

// MARK: - CustomStringConvertible

extension Address: CustomStringConvertible {
    
    public var description: String { return rawValue }
}

// MARK: - Adapter Extensions

public extension Address {
    
    /// Extracts the Bluetooth address from the device ID.
    public init?(deviceIdentifier: CInt) {
        
        var address = bdaddr_t()
        
        guard hci_devba(deviceIdentifier, &address) == 0 else { return nil }
        
        self.byteValue = address
    }
}

public extension Adapter {
    
    /// Attempts to get the address from the underlying Bluetooth hardware. 
    ///
    /// Fails if the Bluetooth adapter was disconnected or hardware failure.
    public var address: Address? {
        
        return Address(deviceIdentifier: deviceIdentifier)
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

