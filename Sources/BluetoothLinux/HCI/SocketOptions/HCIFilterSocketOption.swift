//
//  HCIFilterSocketOption.swift
//  
//
//  Created by Alsey Coleman Miller on 16/10/21.
//

import Bluetooth
import BluetoothHCI
import SystemPackage
import Socket

public extension HCISocketOption {
    
    /// HCI Filter Socket Option
    struct Filter: SocketOption {
        
        @_alwaysEmitIntoClient
        public static var id: HCISocketOption { .filter }
        
        @usableFromInline
        internal var bytes: CInterop.HCIFilterSocketOption
        
        @usableFromInline
        internal init(_ bytes: CInterop.HCIFilterSocketOption) {
            self.bytes = bytes
        }
        
        @_alwaysEmitIntoClient
        public init() {
            self.init(CInterop.HCIFilterSocketOption())
        }
        
        @_alwaysEmitIntoClient
        public var typeMask: UInt32 {
            get { return bytes.typeMask }
            set { bytes.typeMask = newValue }
        }
        
        @_alwaysEmitIntoClient
        public var opcode: UInt16 {
            get { return bytes.opcode }
            set { bytes.opcode = newValue }
        }
        
        @_alwaysEmitIntoClient
        public mutating func setPacketType(_ type: HCIPacketType) {
            bytes.setPacketType(type)
        }
        
        @_alwaysEmitIntoClient
        public mutating func setEvent<T: HCIEvent>(_ event: T) {
            bytes.setEvent(event.rawValue)
        }
        
        @_alwaysEmitIntoClient
        public func withUnsafeBytes<Result>(_ pointer: ((UnsafeRawBufferPointer) throws -> (Result))) rethrows -> Result {
            return try Swift.withUnsafeBytes(of: bytes) { bufferPointer in
                try pointer(bufferPointer)
            }
        }
        
        @_alwaysEmitIntoClient
        public static func withUnsafeBytes(_ body: (UnsafeMutableRawBufferPointer) throws -> ()) rethrows -> Self {
            var value = self.init()
            try Swift.withUnsafeMutableBytes(of: &value.bytes, body)
            return value
        }
    }
}
