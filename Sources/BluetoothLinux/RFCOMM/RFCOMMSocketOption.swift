//
//  RFCOMMSocketOption.swift
//  
//
//  Created by Alsey Coleman Miller on 16/10/21.
//

import Bluetooth
import Socket

/// RFCOMM Socket Options
@frozen
public enum RFCOMMSocketOption: CInt, SocketOptionID {
    
    @_alwaysEmitIntoClient
    public static var optionLevel: SocketOptionLevel { .rfcomm }
    
    /// RFCOMM Connection Info
    case connectionInfo     = 0x02 // RFCOMM_CONNINFO
    
    /// RFCOMM LM
    case linkMode           = 0x03 // RFCOMM_LM
}

public extension RFCOMMSocketOption {
    
    /// L2CAP Connection Info
    @frozen
    struct ConnectionInfo: SocketOption {
        
        @_alwaysEmitIntoClient
        public static var id: RFCOMMSocketOption { .connectionInfo }
        
        public private(set) var handle: UInt16
        public private(set) var deviceClass: (UInt8, UInt8, UInt8)
        
        public init() {
            self.handle = 0
            self.deviceClass = (0,0,0)
        }
        
        public func withUnsafeBytes<Result>(_ pointer: ((UnsafeRawBufferPointer) throws -> (Result))) rethrows -> Result {
            return try Swift.withUnsafeBytes(of: self) { bufferPointer in
                try pointer(bufferPointer)
            }
        }
        
        public static func withUnsafeBytes(_ body: (UnsafeMutableRawBufferPointer) throws -> ()) rethrows -> Self {
            var value = self.init()
            try Swift.withUnsafeMutableBytes(of: &value, body)
            return value
        }
    }
}

public extension RFCOMMSocketOption {
    
    /// L2CAP Connection Info
    @frozen
    struct LinkMode: SocketOption {
        
        @_alwaysEmitIntoClient
        public static var id: RFCOMMSocketOption { .connectionInfo }
        
        public var linkMode: BitMaskOptionSet<RFCOMMLinkMode>
        
        public init(linkMode: BitMaskOptionSet<RFCOMMLinkMode> = []) {
            self.linkMode = linkMode
        }
        
        public func withUnsafeBytes<Result>(_ pointer: ((UnsafeRawBufferPointer) throws -> (Result))) rethrows -> Result {
            return try Swift.withUnsafeBytes(of: linkMode.rawValue) { bufferPointer in
                try pointer(bufferPointer)
            }
        }
        
        public static func withUnsafeBytes(_ body: (UnsafeMutableRawBufferPointer) throws -> ()) rethrows -> Self {
            var rawValue: UInt16 = 0
            try Swift.withUnsafeMutableBytes(of: &rawValue, body)
            return self.init(linkMode: .init(rawValue: rawValue))
        }
    }
}
