//
//  HIDP.swift
//  BluetoothLinux
//
//  Human Interface Device Protocol control socket.
//

import Foundation
import Bluetooth
import SystemPackage
import Socket

/// HIDP control socket.
///
/// Manages kernel HID protocol sessions, which bridge connected L2CAP
/// control (PSM 17) and interrupt (PSM 19) sockets into kernel input devices.
public struct HIDPSocket: Sendable {

    // MARK: - Properties

    @usableFromInline
    internal let fileDescriptor: SocketDescriptor

    // MARK: - Initialization

    /// Open a HIDP control socket.
    public init() throws(Errno) {
        self.fileDescriptor = try .bluetooth(.hidp, flags: [.closeOnExec])
    }

    // MARK: - Methods

    /// Close the control socket.
    ///
    /// Established sessions are not affected.
    public func close() {
        try? fileDescriptor.close()
    }

    /// Bridge connected L2CAP control and interrupt sockets into a kernel input device.
    ///
    /// The L2CAP sockets must be connected to the remote device on the HID control (PSM 17)
    /// and HID interrupt (PSM 19) channels. The report descriptor and device identity are
    /// typically read from the device's service record.
    public func addConnection(
        control: L2CAPSocket,
        interrupt: L2CAPSocket,
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
        try fileDescriptor.hidpAddConnection(
            controlSocket: control.fileDescriptor,
            interruptSocket: interrupt.fileDescriptor,
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
    }

    /// Destroy the session (and input device) for the specified remote device.
    public func removeConnection(
        destination: BluetoothAddress,
        flags: HIDPConnectionFlag = []
    ) throws {
        try fileDescriptor.hidpRemoveConnection(
            destination: destination,
            flags: flags
        )
    }

    /// List the active sessions.
    public func connections(
        limit: Int = HIDPIO.GetConnectionList.maxLimit
    ) throws -> [HIDPConnection] {
        try fileDescriptor.hidpConnectionList(limit: limit)
    }

    /// Read information for the session with the specified remote device.
    public func connectionInformation(
        for destination: BluetoothAddress
    ) throws -> HIDPConnection {
        try fileDescriptor.hidpConnectionInformation(for: destination)
    }
}
