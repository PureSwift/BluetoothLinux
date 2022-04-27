//
//  SecuritySocketOption.swift
//  
//
//  Created by Alsey Coleman Miller on 16/10/21.
//

import Bluetooth
import SystemPackage
import Socket

public extension BluetoothSocketOption {
    
    struct Security: Equatable, Hashable, SocketOption {
        
        @_alwaysEmitIntoClient
        public static var id: BluetoothSocketOption { .security }
        
        internal private(set) var bytes: CInterop.BluetoothSocketSecurity
        
        @usableFromInline
        internal init(_ bytes: CInterop.BluetoothSocketSecurity) {
            self.bytes = bytes
        }
        
        ///
        public init(level: SecurityLevel = .sdp, keySize: UInt8 = 0) {
            self.init(CInterop.BluetoothSocketSecurity())
            self.bytes.level = level.rawValue
            self.bytes.key_size = keySize
        }
        
        public var level: SecurityLevel {
            return SecurityLevel(rawValue: bytes.level)!
        }
        
        public var keySize: UInt8 {
            return bytes.key_size
        }
        
        public func withUnsafeBytes<Result>(_ body: ((UnsafeRawBufferPointer) throws -> (Result))) rethrows -> Result {
            return try Swift.withUnsafeBytes(of: bytes, body)
        }
        
        public static func withUnsafeBytes(_ body: (UnsafeMutableRawBufferPointer) throws -> ()) rethrows -> Self {
            var value = CInterop.BluetoothSocketSecurity()
            try Swift.withUnsafeMutableBytes(of: &value, body)
            return Self.init(value)
        }
    }
}
