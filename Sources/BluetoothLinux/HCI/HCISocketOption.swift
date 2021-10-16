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
    
    public static var optionLevel: SocketOptionLevel { .hostControllerInterface }
    
    case dataDirection                      = 1
    case filter                             = 2
    case timeStamp                          = 3
}

public extension HCISocketOption {
    
    /// HCI Filter Socket Option
    struct Filter: SocketOption {
        
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
            var value = self.init()
            try Swift.withUnsafeMutableBytes(of: &value.bytes, body)
            return value
        }
    }
}
