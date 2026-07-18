//
//  ManagementSocket.swift
//  BluetoothLinux
//

import Foundation
import Bluetooth
import BluetoothHCI
import SystemPackage
import Socket

/// Bluetooth Management interface socket.
///
/// Opens an HCI control channel (`HCI_CHANNEL_CONTROL`) socket for controller management
/// (power, discoverable, connectable, pairing, and other adapter settings).
///
/// Unlike raw HCI sockets, the control channel is not bound to a single controller;
/// commands target a controller by index and events report the originating index.
/// Most commands require the `CAP_NET_ADMIN` capability (root).
public actor ManagementSocket {

    // MARK: - Properties

    /// Maximum size of a management interface message in bytes.
    public static var maximumMessageLength: Int { ManagementEventHeader.length + Int(UInt16.max) }

    @usableFromInline
    internal let socket: Socket

    // MARK: - Initialization

    deinit {
        let socket = self.socket
        Task(priority: .high) {
            await socket.close()
        }
    }

    /// Open a management interface socket.
    public init() async throws {
        let address = HCISocketAddress(
            device: .none,
            channel: .control
        )
        let fileDescriptor = try SocketDescriptor.hci(address, flags: [.closeOnExec, .nonBlocking])
        self.socket = await Socket(fileDescriptor: fileDescriptor)
    }

    // MARK: - Methods

    /// Send a command and wait for its response.
    ///
    /// - Parameter opcode: The command to send.
    /// - Parameter index: The controller the command targets, or ``HostController/ID/none``.
    /// - Parameter parameters: The command parameters.
    ///
    /// - Returns: The return parameters of the command.
    ///
    /// - Throws: ``ManagementStatus`` if the kernel rejects the command.
    @discardableResult
    public func send(
        _ opcode: ManagementOpcode,
        index: HostController.ID = .none,
        parameters: Data = Data()
    ) async throws -> Data {
        assert(parameters.count <= UInt16.max)
        let header = ManagementCommandHeader(
            opcode: opcode,
            index: index,
            parameterLength: UInt16(parameters.count)
        )
        var packet = header.data
        packet.append(parameters)
        _ = try await socket.write(packet)
        // wait for a response to this command, ignoring unrelated events
        while true {
            let notification = try await receive()
            guard let response = ManagementCommandResponse(notification) else {
                continue
            }
            guard response.opcode == opcode else {
                continue
            }
            guard response.status == .success else {
                throw response.status
            }
            switch notification.event {
            case .commandComplete:
                return response.parameters
            case .commandStatus:
                // command accepted, wait for completion
                continue
            default:
                continue
            }
        }
    }

    /// Receive the next event.
    public func receive() async throws -> ManagementEventNotification {
        let data = try await socket.read(Self.maximumMessageLength)
        guard let notification = ManagementEventNotification(data: data) else {
            throw BluetoothHostControllerError.garbageResponse(data)
        }
        return notification
    }
}

// MARK: - Supporting Types

/// Parsed parameters of a Command Complete or Command Status event.
internal struct ManagementCommandResponse {

    let opcode: ManagementOpcode

    let status: ManagementStatus

    let parameters: Data

    init?(_ notification: ManagementEventNotification) {
        guard notification.event == .commandComplete || notification.event == .commandStatus else {
            return nil
        }
        let data = notification.parameters
        guard data.count >= 3 else {
            return nil
        }
        let start = data.startIndex
        self.opcode = ManagementOpcode(rawValue: UInt16(littleEndian: UInt16(bytes: (data[start], data[start + 1]))))
        guard let status = ManagementStatus(rawValue: data[start + 2]) else {
            return nil
        }
        self.status = status
        self.parameters = Data(data.dropFirst(3))
    }
}
