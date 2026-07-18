//
//  HIDPAddConnection.swift
//  BluetoothLinux
//

import Foundation
import Bluetooth
import SystemPackage
import Socket

public extension HIDPIO {

    /// HIDP Add Connection
    ///
    /// Bridges connected L2CAP control (PSM 17) and interrupt (PSM 19) sockets
    /// into a kernel input device.
    struct AddConnection: IOControlValue {

        @_alwaysEmitIntoClient
        public static var id: HIDPIO { .addConnection }

        @usableFromInline
        internal private(set) var bytes: CInterop.HIDPConnectionAddRequest

        /// HID report descriptor.
        public let reportDescriptor: Data

        public init(
            controlSocket: SocketDescriptor,
            interruptSocket: SocketDescriptor,
            flags: HIDPConnectionFlag = [],
            parser: UInt16 = 0x0100,
            country: UInt8 = 0,
            subclass: UInt8 = 0,
            vendor: UInt16 = 0,
            product: UInt16 = 0,
            version: UInt16 = 0,
            name: String = "",
            reportDescriptor: Data = Data(),
            idleTimeout: UInt32 = 0
        ) {
            precondition(reportDescriptor.count <= UInt16.max)
            self.reportDescriptor = reportDescriptor
            self.bytes = CInterop.HIDPConnectionAddRequest(
                controlSocket: controlSocket.rawValue,
                interruptSocket: interruptSocket.rawValue,
                parser: parser,
                reportDescriptorSize: UInt16(reportDescriptor.count),
                reportDescriptor: nil,
                country: country,
                subclass: subclass,
                vendor: vendor,
                product: product,
                version: version,
                flags: flags.rawValue,
                idleTimeout: idleTimeout,
                name: name.hidpDeviceName
            )
        }

        public mutating func withUnsafeMutablePointer<Result>(_ body: (UnsafeMutableRawPointer) throws -> (Result)) rethrows -> Result {
            // keep the report descriptor buffer alive for the duration of the call
            var descriptor = [UInt8](reportDescriptor)
            var bytes = self.bytes
            let result: Result = try descriptor.withUnsafeMutableBufferPointer { buffer in
                bytes.reportDescriptor = buffer.baseAddress
                return try Swift.withUnsafeMutableBytes(of: &bytes) { requestBuffer in
                    try body(requestBuffer.baseAddress!)
                }
            }
            bytes.reportDescriptor = nil
            self.bytes = bytes
            return result
        }
    }
}

public extension HIDPIO.AddConnection {

    @_alwaysEmitIntoClient
    var controlSocket: SocketDescriptor {
        return .init(rawValue: bytes.controlSocket)
    }

    @_alwaysEmitIntoClient
    var interruptSocket: SocketDescriptor {
        return .init(rawValue: bytes.interruptSocket)
    }

    @_alwaysEmitIntoClient
    var flags: HIDPConnectionFlag {
        return .init(rawValue: bytes.flags)
    }

    /// Name of the device.
    var name: String {
        return String(hidpDeviceName: bytes.name)
    }
}

// MARK: - File Descriptor

internal extension SocketDescriptor {

    @usableFromInline
    func hidpAddConnection(
        controlSocket: SocketDescriptor,
        interruptSocket: SocketDescriptor,
        flags: HIDPConnectionFlag = [],
        parser: UInt16 = 0x0100,
        country: UInt8 = 0,
        subclass: UInt8 = 0,
        vendor: UInt16 = 0,
        product: UInt16 = 0,
        version: UInt16 = 0,
        name: String = "",
        reportDescriptor: Data = Data(),
        idleTimeout: UInt32 = 0
    ) throws {
        var request = HIDPIO.AddConnection(
            controlSocket: controlSocket,
            interruptSocket: interruptSocket,
            flags: flags,
            parser: parser,
            country: country,
            subclass: subclass,
            vendor: vendor,
            product: product,
            version: version,
            name: name,
            reportDescriptor: reportDescriptor,
            idleTimeout: idleTimeout
        )
        try inputOutput(&request)
    }
}
