//
//  ManagementCommands.swift
//  BluetoothLinux
//

import Foundation
import Bluetooth
import BluetoothHCI

/// Bluetooth Management interface version information.
public struct ManagementVersion: Equatable, Hashable, Sendable {

    /// Interface version.
    public let version: UInt8

    /// Interface revision.
    public let revision: UInt16
}

/// Discoverable mode.
public enum ManagementDiscoverableMode: UInt8, Sendable, CaseIterable {

    case disabled   = 0x00
    case general    = 0x01
    case limited    = 0x02
}

/// Advertising mode.
public enum ManagementAdvertisingMode: UInt8, Sendable, CaseIterable {

    case disabled   = 0x00
    case enabled    = 0x01

    /// Advertise as connectable even when not connectable.
    case connectable = 0x02
}

public extension ManagementSocket {

    /// Read Management Version Information
    func readVersion() async throws -> ManagementVersion {
        let response = try await send(.readVersion)
        guard response.count >= 3 else {
            throw BluetoothHostControllerError.garbageResponse(response)
        }
        let bytes = Array(response)
        return ManagementVersion(
            version: bytes[0],
            revision: UInt16(littleEndian: UInt16(bytes: (bytes[1], bytes[2])))
        )
    }

    /// Read Controller Index List
    func readControllerIndexList() async throws -> [HostController.ID] {
        let response = try await send(.readIndexList)
        guard response.count >= 2 else {
            throw BluetoothHostControllerError.garbageResponse(response)
        }
        let bytes = Array(response)
        let count = Int(UInt16(littleEndian: UInt16(bytes: (bytes[0], bytes[1]))))
        guard response.count >= 2 + (count * 2) else {
            throw BluetoothHostControllerError.garbageResponse(response)
        }
        return (0 ..< count).map { index in
            let offset = 2 + (index * 2)
            return HostController.ID(
                rawValue: UInt16(littleEndian: UInt16(bytes: (bytes[offset], bytes[offset + 1])))
            )
        }
    }

    /// Read Controller Information
    func readControllerInformation(for index: HostController.ID) async throws -> ManagementControllerInformation {
        let response = try await send(.readControllerInformation, index: index)
        guard let information = ManagementControllerInformation(data: response) else {
            throw BluetoothHostControllerError.garbageResponse(response)
        }
        return information
    }

    /// Set Powered
    @discardableResult
    func setPowered(_ isEnabled: Bool, for index: HostController.ID) async throws -> ManagementSettings {
        try await setMode(.setPowered, isEnabled, for: index)
    }

    /// Set Connectable
    @discardableResult
    func setConnectable(_ isEnabled: Bool, for index: HostController.ID) async throws -> ManagementSettings {
        try await setMode(.setConnectable, isEnabled, for: index)
    }

    /// Set Fast Connectable
    @discardableResult
    func setFastConnectable(_ isEnabled: Bool, for index: HostController.ID) async throws -> ManagementSettings {
        try await setMode(.setFastConnectable, isEnabled, for: index)
    }

    /// Set Bondable
    @discardableResult
    func setBondable(_ isEnabled: Bool, for index: HostController.ID) async throws -> ManagementSettings {
        try await setMode(.setBondable, isEnabled, for: index)
    }

    /// Set Link Security
    @discardableResult
    func setLinkSecurity(_ isEnabled: Bool, for index: HostController.ID) async throws -> ManagementSettings {
        try await setMode(.setLinkSecurity, isEnabled, for: index)
    }

    /// Set Secure Simple Pairing
    @discardableResult
    func setSecureSimplePairing(_ isEnabled: Bool, for index: HostController.ID) async throws -> ManagementSettings {
        try await setMode(.setSecureSimplePairing, isEnabled, for: index)
    }

    /// Set Low Energy
    @discardableResult
    func setLowEnergy(_ isEnabled: Bool, for index: HostController.ID) async throws -> ManagementSettings {
        try await setMode(.setLowEnergy, isEnabled, for: index)
    }

    /// Set Discoverable
    ///
    /// - Parameter mode: The discoverable mode to set.
    /// - Parameter timeout: Duration in seconds before discoverable mode is disabled again,
    ///   or `0` to remain discoverable indefinitely.
    @discardableResult
    func setDiscoverable(
        _ mode: ManagementDiscoverableMode,
        timeout: UInt16 = 0,
        for index: HostController.ID
    ) async throws -> ManagementSettings {
        let timeoutBytes = timeout.littleEndian.bytes
        let parameters = Data([mode.rawValue, timeoutBytes.0, timeoutBytes.1])
        let response = try await send(.setDiscoverable, index: index, parameters: parameters)
        return try Self.settings(from: response)
    }

    /// Set Advertising
    @discardableResult
    func setAdvertising(
        _ mode: ManagementAdvertisingMode,
        for index: HostController.ID
    ) async throws -> ManagementSettings {
        let response = try await send(.setAdvertising, index: index, parameters: Data([mode.rawValue]))
        return try Self.settings(from: response)
    }

    /// Set Local Name
    ///
    /// - Parameter name: The controller name (truncated to fit).
    /// - Parameter shortName: The short name used when advertising space is limited (truncated to fit).
    func setLocalName(
        _ name: String,
        shortName: String = "",
        for index: HostController.ID
    ) async throws {
        var parameters = Data(capacity: ManagementControllerInformation.maximumNameLength + ManagementControllerInformation.maximumShortNameLength)
        parameters.append(Self.fixedLengthString(name, length: ManagementControllerInformation.maximumNameLength))
        parameters.append(Self.fixedLengthString(shortName, length: ManagementControllerInformation.maximumShortNameLength))
        try await send(.setLocalName, index: index, parameters: parameters)
    }

    // MARK: - Internal

    internal func setMode(
        _ opcode: ManagementOpcode,
        _ isEnabled: Bool,
        for index: HostController.ID
    ) async throws -> ManagementSettings {
        let response = try await send(opcode, index: index, parameters: Data([isEnabled ? 0x01 : 0x00]))
        return try Self.settings(from: response)
    }

    internal static func settings(from response: Data) throws -> ManagementSettings {
        guard response.count >= 4 else {
            throw BluetoothHostControllerError.garbageResponse(response)
        }
        let bytes = Array(response)
        return ManagementSettings(
            rawValue: UInt32(littleEndian: UInt32(bytes: (bytes[0], bytes[1], bytes[2], bytes[3])))
        )
    }

    internal static func fixedLengthString(_ string: String, length: Int) -> Data {
        var data = Data(string.utf8.prefix(length - 1))
        data.append(contentsOf: repeatElement(0, count: length - data.count))
        return data
    }
}
