//
//  L2CAPSocketOption.swift
//  
//
//  Created by Alsey Coleman Miller on 16/10/21.
//

import SystemPackage
import Socket

/// L2CAP Socket Options
public enum L2CAPSocketOption: CInt, SocketOptionID {
    
    public static var optionLevel: SocketOptionLevel { .l2cap }
    
    /// L2CAP Socket Options
    case options        = 0x01
    
    /// L2CAP Connection Info
    case connectionInfo = 0x02
    
    /// L2CAP Link Mode
    case linkMode       = 0x03
}

public extension L2CAPSocketOption {
    
    struct Options: Equatable, Hashable, SocketOption {
        
        public static var id: L2CAPSocketOption { .options }
        
        public var outputMaximumTransmissionUnit: UInt16 // omtu
        public var inputMaximumTransmissionUnit: UInt16 // imtu
        public var flushTo: UInt16 // flush_to
        public var mode: UInt8
        public var fcs: UInt8
        public var maxTransmission: UInt8 // max_tx
        public var transmissionWindowSize: UInt8 // txwin_size
        
        public init() {
            self.outputMaximumTransmissionUnit = 0
            self.inputMaximumTransmissionUnit = 0
            self.flushTo = 0
            self.mode = 0
            self.fcs = 0
            self.maxTransmission = 0
            self.transmissionWindowSize = 0
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

public extension L2CAPSocketOption {
    
    /// L2CAP Connection Info
    struct ConnectionInfo: SocketOption {
        
        public static var id: L2CAPSocketOption { .connectionInfo }
        
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
