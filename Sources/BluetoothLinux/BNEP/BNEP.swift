//
//  BNEP.swift
//  BluetoothLinux
//
//  Bluetooth Network Encapsulation Protocol (PAN) control socket.
//

import Foundation
import Bluetooth
import SystemPackage
import Socket

/// BNEP control socket.
///
/// Manages kernel Bluetooth network encapsulation sessions, which bridge
/// connected L2CAP sockets (PSM 15) into virtual Ethernet interfaces
/// (e.g. `bnep0`) for Personal Area Networking.
public struct BNEPSocket: Sendable {

    // MARK: - Properties

    @usableFromInline
    internal let fileDescriptor: SocketDescriptor

    // MARK: - Initialization

    /// Open a BNEP control socket.
    public init() throws(Errno) {
        self.fileDescriptor = try .bluetooth(.bnep, flags: [.closeOnExec])
    }

    // MARK: - Methods

    /// Close the control socket.
    ///
    /// Established sessions are not affected.
    public func close() {
        try? fileDescriptor.close()
    }

    /// Bridge a connected L2CAP socket into a kernel network interface.
    ///
    /// The L2CAP socket must be connected to the remote device on the BNEP PSM (15)
    /// and the setup connection request/response exchange must already have taken place
    /// (or pass ``BNEPConnectionFlag/setupResponse`` to let the kernel reply to a
    /// received setup request).
    ///
    /// - Returns: The name of the created network interface (e.g. `bnep0`).
    @discardableResult
    public func addConnection(
        _ socket: L2CAPSocket,
        role: BNEPRole,
        flags: BNEPConnectionFlag = [],
        device: String = ""
    ) throws -> String {
        try fileDescriptor.bnepAddConnection(
            socket: socket.fileDescriptor,
            flags: flags,
            role: role,
            device: device
        )
    }

    /// Destroy the session (and network interface) for the specified remote device.
    public func removeConnection(
        destination: BluetoothAddress,
        flags: BNEPConnectionFlag = []
    ) throws {
        try fileDescriptor.bnepRemoveConnection(
            destination: destination,
            flags: flags
        )
    }

    /// List the active sessions.
    public func connections(
        limit: Int = BNEPIO.GetConnectionList.maxLimit
    ) throws -> [BNEPConnection] {
        try fileDescriptor.bnepConnectionList(limit: limit)
    }

    /// Read the feature bitmask supported by the kernel.
    public func supportedFeatures() throws -> BNEPIO.GetSupportedFeatures {
        try fileDescriptor.bnepSupportedFeatures()
    }
}
