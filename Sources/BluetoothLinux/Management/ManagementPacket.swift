//
//  ManagementPacket.swift
//  BluetoothLinux
//

import Foundation
import Bluetooth

/// Bluetooth Management interface command packet header.
///
/// All fields are little endian on the wire.
@frozen
public struct ManagementCommandHeader: Equatable, Hashable, Sendable {

    /// Header length in bytes.
    public static var length: Int { 6 }

    /// Command opcode.
    public var opcode: ManagementOpcode

    /// Controller index, or ``HostController/ID/none``.
    public var index: HostController.ID

    /// Length of the parameters following the header.
    public var parameterLength: UInt16

    public init(
        opcode: ManagementOpcode,
        index: HostController.ID = .none,
        parameterLength: UInt16 = 0
    ) {
        self.opcode = opcode
        self.index = index
        self.parameterLength = parameterLength
    }
}

public extension ManagementCommandHeader {

    init?(data: Data) {
        guard data.count >= Self.length else {
            return nil
        }
        let start = data.startIndex
        self.opcode = ManagementOpcode(rawValue: UInt16(littleEndian: UInt16(bytes: (data[start], data[start + 1]))))
        self.index = HostController.ID(rawValue: UInt16(littleEndian: UInt16(bytes: (data[start + 2], data[start + 3]))))
        self.parameterLength = UInt16(littleEndian: UInt16(bytes: (data[start + 4], data[start + 5])))
    }

    var data: Data {
        let opcode = self.opcode.rawValue.littleEndian.bytes
        let index = self.index.rawValue.littleEndian.bytes
        let length = self.parameterLength.littleEndian.bytes
        return Data([opcode.0, opcode.1, index.0, index.1, length.0, length.1])
    }
}

/// Bluetooth Management interface event packet header.
///
/// All fields are little endian on the wire.
@frozen
public struct ManagementEventHeader: Equatable, Hashable, Sendable {

    /// Header length in bytes.
    public static var length: Int { 6 }

    /// Event code.
    public var event: ManagementEvent

    /// Controller index, or ``HostController/ID/none``.
    public var index: HostController.ID

    /// Length of the parameters following the header.
    public var parameterLength: UInt16

    public init(
        event: ManagementEvent,
        index: HostController.ID = .none,
        parameterLength: UInt16 = 0
    ) {
        self.event = event
        self.index = index
        self.parameterLength = parameterLength
    }
}

public extension ManagementEventHeader {

    init?(data: Data) {
        guard data.count >= Self.length else {
            return nil
        }
        let start = data.startIndex
        self.event = ManagementEvent(rawValue: UInt16(littleEndian: UInt16(bytes: (data[start], data[start + 1]))))
        self.index = HostController.ID(rawValue: UInt16(littleEndian: UInt16(bytes: (data[start + 2], data[start + 3]))))
        self.parameterLength = UInt16(littleEndian: UInt16(bytes: (data[start + 4], data[start + 5])))
    }

    var data: Data {
        let event = self.event.rawValue.littleEndian.bytes
        let index = self.index.rawValue.littleEndian.bytes
        let length = self.parameterLength.littleEndian.bytes
        return Data([event.0, event.1, index.0, index.1, length.0, length.1])
    }
}

/// A Bluetooth Management interface event received from the kernel.
@frozen
public struct ManagementEventNotification: Equatable, Hashable, Sendable {

    /// Event code.
    public let event: ManagementEvent

    /// Controller index the event originated from.
    public let index: HostController.ID

    /// Event parameters.
    public let parameters: Data

    public init(
        event: ManagementEvent,
        index: HostController.ID,
        parameters: Data
    ) {
        self.event = event
        self.index = index
        self.parameters = parameters
    }
}

public extension ManagementEventNotification {

    init?(data: Data) {
        guard let header = ManagementEventHeader(data: data) else {
            return nil
        }
        let parameters = Data(data.dropFirst(ManagementEventHeader.length))
        guard parameters.count == Int(header.parameterLength) else {
            return nil
        }
        self.init(
            event: header.event,
            index: header.index,
            parameters: parameters
        )
    }
}
