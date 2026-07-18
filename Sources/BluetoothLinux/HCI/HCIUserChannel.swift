//
//  HCIUserChannel.swift
//  BluetoothLinux
//

import Foundation
import Bluetooth
import BluetoothHCI
import SystemPackage
import Socket

/// HCI User Channel
///
/// Provides exclusive access to a Bluetooth controller (`HCI_CHANNEL_USER`),
/// bypassing the kernel's host stack. While the channel is open, all HCI traffic
/// (commands, events, ACL and SCO data) flows through this socket and the kernel
/// does not process packets itself.
///
/// The controller must be powered off before the channel can be opened
/// (use ``open(device:)`` to power it off automatically), and the
/// `CAP_NET_ADMIN` capability (root) is required.
public actor HCIUserChannel {

    // MARK: - Properties

    /// Maximum size of an HCI packet in bytes, including the packet type prefix.
    public static var maximumPacketLength: Int { 1 + 4 + Int(UInt16.max) }

    /// Controller identifier.
    public let id: HostController.ID

    @usableFromInline
    internal let socket: Socket

    // MARK: - Initialization

    deinit {
        let socket = self.socket
        Task(priority: .high) {
            await socket.close()
        }
    }

    /// Open a user channel for the specified controller.
    ///
    /// The controller must already be powered off.
    public init(id: HostController.ID) async throws {
        let address = HCISocketAddress(
            device: id,
            channel: .user
        )
        let fileDescriptor = try SocketDescriptor.hci(address, flags: [.closeOnExec, .nonBlocking])
        self.id = id
        self.socket = await Socket(fileDescriptor: fileDescriptor)
    }

    /// Power off the specified controller and open a user channel for it.
    public static func open(device id: HostController.ID) async throws -> HCIUserChannel {
        try HostController.disable(device: id)
        return try await HCIUserChannel(id: id)
    }

    // MARK: - Methods

    /// Send a raw HCI packet.
    public func send(_ packet: Packet) async throws {
        var data = Data(capacity: 1 + packet.data.count)
        data.append(packet.type.rawValue)
        data.append(packet.data)
        _ = try await socket.write(data)
    }

    /// Send an HCI command with parameters, without waiting for a response.
    public func send<Command: HCICommand & Sendable>(
        _ command: Command,
        parameter: Data = Data()
    ) async throws {
        try await socket.sendCommand(command, parameter: parameter)
    }

    /// Receive the next HCI packet.
    public func receive() async throws -> Packet {
        let data = try await socket.read(Self.maximumPacketLength)
        guard let packet = Packet(data: data) else {
            throw BluetoothHostControllerError.garbageResponse(data)
        }
        return packet
    }

    /// Send an HCI command and wait for its response, ignoring unrelated packets.
    ///
    /// - Returns: The return parameters of the Command Complete event,
    ///   or empty data if the command was acknowledged with a successful Command Status event.
    ///
    /// - Throws: ``HCIError`` if the command fails.
    @discardableResult
    public func request<Command: HCICommand & Sendable>(
        _ command: Command,
        parameter: Data = Data()
    ) async throws -> Data {
        try await socket.sendCommand(command, parameter: parameter)
        while true {
            let packet = try await receive()
            guard let response = CommandResponse(packet), response.opcode == command.opcode else {
                continue
            }
            if let status = response.status, status != 0 {
                throw HCIError(rawValue: status) ?? BluetoothHostControllerError.garbageResponse(packet.data)
            }
            return response.parameters
        }
    }
}

// MARK: - Supporting Types

public extension HCIUserChannel {

    /// HCI packet.
    struct Packet: Equatable, Hashable, Sendable {

        /// Packet type.
        public let type: HCIPacketType

        /// Packet payload, without the packet type prefix.
        public let data: Data

        public init(type: HCIPacketType, data: Data) {
            self.type = type
            self.data = data
        }
    }
}

public extension HCIUserChannel.Packet {

    /// Decode a packet from its wire representation (packet type prefix followed by payload).
    init?(data: Data) {
        guard data.isEmpty == false,
              let type = HCIPacketType(rawValue: data[data.startIndex]) else {
            return nil
        }
        self.init(type: type, data: Data(data.dropFirst()))
    }
}

internal extension HCIUserChannel {

    /// Parsed Command Complete or Command Status event.
    struct CommandResponse {

        /// Opcode of the command this event responds to.
        let opcode: UInt16

        /// Command status, if this is a Command Status event.
        let status: UInt8?

        /// Return parameters, if this is a Command Complete event.
        let parameters: Data

        init?(_ packet: HCIUserChannel.Packet) {
            guard packet.type == .event,
                  packet.data.count >= HCIEventHeader.length,
                  let header = HCIEventHeader(data: Data(packet.data.prefix(HCIEventHeader.length))) else {
                return nil
            }
            let parameters = Data(packet.data.dropFirst(HCIEventHeader.length))
            guard parameters.count == Int(header.parameterLength) else {
                return nil
            }
            switch header.event {
            case .commandComplete:
                // number of packets, opcode, return parameters
                guard parameters.count >= 3 else {
                    return nil
                }
                self.opcode = UInt16(littleEndian: UInt16(bytes: (parameters[1], parameters[2])))
                self.status = nil
                self.parameters = Data(parameters.dropFirst(3))
            case .commandStatus:
                // status, number of packets, opcode
                guard parameters.count >= 4 else {
                    return nil
                }
                self.opcode = UInt16(littleEndian: UInt16(bytes: (parameters[2], parameters[3])))
                self.status = parameters[0]
                self.parameters = Data()
            default:
                return nil
            }
        }
    }
}
