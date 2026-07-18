//
//  BNEPGetSupportedFeatures.swift
//  BluetoothLinux
//

import Bluetooth
import SystemPackage
import Socket

public extension BNEPIO {

    /// BNEP Get Supported Features
    struct GetSupportedFeatures: Equatable, Hashable, IOControlValue {

        @_alwaysEmitIntoClient
        public static var id: BNEPIO { .getSupportedFeatures }

        @usableFromInline
        internal private(set) var bytes: UInt32

        public init() {
            self.bytes = 0
        }

        @_alwaysEmitIntoClient
        public mutating func withUnsafeMutablePointer<Result>(_ body: (UnsafeMutableRawPointer) throws -> (Result)) rethrows -> Result {
            try Swift.withUnsafeMutableBytes(of: &bytes) { buffer in
                try body(buffer.baseAddress!)
            }
        }
    }
}

public extension BNEPIO.GetSupportedFeatures {

    /// Feature bitmask reported by the kernel.
    @_alwaysEmitIntoClient
    var features: UInt32 {
        return bytes
    }

    /// Whether the kernel can send the setup connection response
    /// (``BNEPConnectionFlag/setupResponse``).
    @_alwaysEmitIntoClient
    var isSetupResponseSupported: Bool {
        return bytes & (1 << 0) != 0
    }
}

// MARK: - File Descriptor

internal extension SocketDescriptor {

    @usableFromInline
    func bnepSupportedFeatures() throws -> BNEPIO.GetSupportedFeatures {
        var request = BNEPIO.GetSupportedFeatures()
        try inputOutput(&request)
        return request
    }
}
