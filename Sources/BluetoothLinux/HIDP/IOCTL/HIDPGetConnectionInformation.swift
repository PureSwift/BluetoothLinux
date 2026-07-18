//
//  HIDPGetConnectionInformation.swift
//  BluetoothLinux
//

import Bluetooth
import SystemPackage
import Socket

public extension HIDPIO {

    /// HIDP Get Connection Information
    struct GetConnectionInformation: IOControlValue {

        @_alwaysEmitIntoClient
        public static var id: HIDPIO { .getConnectionInfo }

        @usableFromInline
        internal private(set) var bytes: CInterop.HIDPConnectionInformation

        public init(destination: BluetoothAddress) {
            self.bytes = CInterop.HIDPConnectionInformation(
                address: destination.littleEndian
            )
        }

        /// The connection information returned by the kernel.
        public var response: HIDPConnection {
            return HIDPConnection(bytes)
        }

        @_alwaysEmitIntoClient
        public mutating func withUnsafeMutablePointer<Result>(_ body: (UnsafeMutableRawPointer) throws -> (Result)) rethrows -> Result {
            try Swift.withUnsafeMutableBytes(of: &bytes) { buffer in
                try body(buffer.baseAddress!)
            }
        }
    }
}

// MARK: - File Descriptor

internal extension SocketDescriptor {

    @usableFromInline
    func hidpConnectionInformation(
        for destination: BluetoothAddress
    ) throws -> HIDPConnection {
        var request = HIDPIO.GetConnectionInformation(destination: destination)
        try inputOutput(&request)
        return request.response
    }
}
