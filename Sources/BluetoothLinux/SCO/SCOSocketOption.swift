//
//  SCOSocketOption.swift
//  BluetoothLinux
//

import SystemPackage
import Socket

/// SCO Socket Options
public enum SCOSocketOption: CInt, SocketOptionID {

    public static var optionLevel: SocketOptionLevel { .sco }

    /// SCO Socket Options
    case options        = 0x01

    /// SCO Connection Info
    case connectionInfo = 0x02
}

public extension SCOSocketOption {

    /// SCO Socket Options
    ///
    /// `sco_options`
    struct Options: Equatable, Hashable, SocketOption, Sendable {

        @_alwaysEmitIntoClient
        public static var id: SCOSocketOption { .options }

        /// Maximum transmission unit.
        public var maximumTransmissionUnit: UInt16 // mtu

        public init() {
            self.maximumTransmissionUnit = 0
        }

        public func withUnsafeBytes<Result, Error>(_ body: ((UnsafeRawBufferPointer) throws(Error) -> (Result))) rethrows -> Result where Error: Swift.Error {
            return try Swift.withUnsafeBytes(of: self) { bufferPointer in
                try body(bufferPointer)
            }
        }

        public static func withUnsafeBytes<Error>(
            _ body: (UnsafeMutableRawBufferPointer) throws(Error) -> ()
        ) rethrows -> Self where Error: Swift.Error {
            var value = self.init()
            try Swift.withUnsafeMutableBytes(of: &value, body)
            return value
        }
    }

    /// SCO Connection Information
    ///
    /// `sco_conninfo`
    struct ConnectionInfo: SocketOption, Sendable {

        @_alwaysEmitIntoClient
        public static var id: SCOSocketOption { .connectionInfo }

        /// Connection handle.
        public var handle: UInt16

        /// Device class.
        public var deviceClass: (UInt8, UInt8, UInt8)

        public init() {
            self.handle = 0
            self.deviceClass = (0, 0, 0)
        }

        public func withUnsafeBytes<Result, Error>(_ body: ((UnsafeRawBufferPointer) throws(Error) -> (Result))) rethrows -> Result where Error: Swift.Error {
            return try Swift.withUnsafeBytes(of: self) { bufferPointer in
                try body(bufferPointer)
            }
        }

        public static func withUnsafeBytes<Error>(
            _ body: (UnsafeMutableRawBufferPointer) throws(Error) -> ()
        ) rethrows -> Self where Error: Swift.Error {
            var value = self.init()
            try Swift.withUnsafeMutableBytes(of: &value, body)
            return value
        }
    }
}

extension SCOSocketOption.ConnectionInfo: Equatable, Hashable {

    public static func == (lhs: SCOSocketOption.ConnectionInfo, rhs: SCOSocketOption.ConnectionInfo) -> Bool {
        lhs.handle == rhs.handle
            && lhs.deviceClass == rhs.deviceClass
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(handle)
        hasher.combine(deviceClass.0)
        hasher.combine(deviceClass.1)
        hasher.combine(deviceClass.2)
    }
}
