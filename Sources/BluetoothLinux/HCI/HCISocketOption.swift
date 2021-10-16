//
//  HCISocketOption.swift
//  
//
//  Created by Alsey Coleman Miller on 16/10/21.
//

import Bluetooth
import BluetoothHCI
import SystemPackage

/// Bluetooth HCI Socket Option Identifier
public enum HCISocketOption: Int32, SocketOptionID {
    
    public static var optionLevel: SocketOptionLevel { .bluetoothHCI }
    
    case dataDirection                      = 1
    case filter                             = 2
    case timeStamp                          = 3
}

public extension HCISocketOption {
    
    /// HCI Filter Socket Option
    public struct Filter: SocketOption {
        
        public static var id: HCISocketOption { .filter }
        
        internal private(set) var bytes: CInterop.HCIFilterSocketOption
        
        internal init(_ bytes: CInterop.HCIFilterSocketOption) {
            self.bytes = bytes
        }
        
        public init() {
            self.init(CInterop.HCIFilterSocketOption())
        }
        
        public mutating func setPacketType(_ type: HCIPacketType) {
            bytes.setPacketType(type)
        }
        
        public mutating func setEvent<T: HCIEvent>(_ event: T) {
            bytes.setEvent(event.rawValue)
        }
        
        public func withUnsafeBytes<Result>(_ pointer: ((UnsafeRawBufferPointer) throws -> (Result))) rethrows -> Result {
            return try Swift.withUnsafeBytes(of: bytes) { bufferPointer in
                try pointer(bufferPointer)
            }
        }
        
        public static func withUnsafeBytes(_ body: (UnsafeMutableRawBufferPointer) throws -> ()) rethrows -> Self {
            var value = CInterop.HCIFilterSocketOption()
            try Swift.withUnsafeMutableBytes(of: &value, body)
            return Self.init(value)
        }
    }
}

public extension SocketOptionLevel {
    
    /// Bluetooth HCI Socket Option Level
    @_alwaysEmitIntoClient
    static var bluetoothHCI: SocketOptionLevel { SocketOptionLevel(rawValue: 0) }
}
