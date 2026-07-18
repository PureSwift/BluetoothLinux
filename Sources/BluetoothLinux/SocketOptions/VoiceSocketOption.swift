//
//  VoiceSocketOption.swift
//  BluetoothLinux
//

import Bluetooth
import SystemPackage
import Socket

public extension BluetoothSocketOption {

    /// Bluetooth Voice socket option
    ///
    /// Configures the air coding format of an SCO socket (`bt_voice`).
    /// Must be set before the connection is established.
    struct Voice: Equatable, Hashable, SocketOption, Sendable {

        @_alwaysEmitIntoClient
        public static var id: BluetoothSocketOption { .voice }

        /// Voice setting.
        public var setting: Setting

        public init(setting: Setting = .cvsd) {
            self.setting = setting
        }

        public func withUnsafeBytes<Result, Error>(_ body: ((UnsafeRawBufferPointer) throws(Error) -> (Result))) rethrows -> Result where Error: Swift.Error {
            return try Swift.withUnsafeBytes(of: setting.rawValue) { bufferPointer in
                try body(bufferPointer)
            }
        }

        public static func withUnsafeBytes<Error>(
            _ body: (UnsafeMutableRawBufferPointer) throws(Error) -> ()
        ) rethrows -> Self where Error: Swift.Error {
            var rawValue: UInt16 = 0
            try Swift.withUnsafeMutableBytes(of: &rawValue, body)
            return Self.init(setting: Setting(rawValue: rawValue))
        }
    }
}

public extension BluetoothSocketOption.Voice {

    /// Voice setting.
    @frozen
    struct Setting: RawRepresentable, Equatable, Hashable, Sendable {

        public let rawValue: UInt16

        public init(rawValue: UInt16) {
            self.rawValue = rawValue
        }

        /// CVSD air coding format (`BT_VOICE_CVSD_16BIT`).
        public static var cvsd: Setting { Setting(rawValue: 0x0060) }

        /// Transparent air coding format (`BT_VOICE_TRANSPARENT`),
        /// used for wideband speech codecs such as mSBC.
        public static var transparent: Setting { Setting(rawValue: 0x0003) }
    }
}
