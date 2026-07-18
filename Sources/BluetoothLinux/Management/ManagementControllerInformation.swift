//
//  ManagementControllerInformation.swift
//  BluetoothLinux
//

import Foundation
import Bluetooth

/// Bluetooth Management interface controller information.
///
/// Return parameters of the Read Controller Information command.
public struct ManagementControllerInformation: Equatable, Hashable, Sendable {

    /// Length of the encoded structure in bytes.
    public static var length: Int { 6 + 1 + 2 + 4 + 4 + 3 + Self.maximumNameLength + Self.maximumShortNameLength }

    /// Maximum length of the controller name in bytes, including the null terminator.
    public static var maximumNameLength: Int { 249 }

    /// Maximum length of the controller short name in bytes, including the null terminator.
    public static var maximumShortNameLength: Int { 11 }

    /// Controller address.
    public let address: BluetoothAddress

    /// Bluetooth core specification version.
    public let version: UInt8

    /// Manufacturer identifier.
    public let manufacturer: UInt16

    /// Settings the controller supports.
    public let supportedSettings: ManagementSettings

    /// Settings currently active on the controller.
    public let currentSettings: ManagementSettings

    /// Class of device.
    public let classOfDevice: (UInt8, UInt8, UInt8)

    /// Controller name.
    public let name: String

    /// Controller short name.
    public let shortName: String

    public static func == (lhs: ManagementControllerInformation, rhs: ManagementControllerInformation) -> Bool {
        lhs.address == rhs.address
            && lhs.version == rhs.version
            && lhs.manufacturer == rhs.manufacturer
            && lhs.supportedSettings == rhs.supportedSettings
            && lhs.currentSettings == rhs.currentSettings
            && lhs.classOfDevice == rhs.classOfDevice
            && lhs.name == rhs.name
            && lhs.shortName == rhs.shortName
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(address)
        hasher.combine(version)
        hasher.combine(manufacturer)
        hasher.combine(supportedSettings)
        hasher.combine(currentSettings)
        hasher.combine(classOfDevice.0)
        hasher.combine(classOfDevice.1)
        hasher.combine(classOfDevice.2)
        hasher.combine(name)
        hasher.combine(shortName)
    }
}

public extension ManagementControllerInformation {

    init?(data: Data) {
        guard data.count >= Self.length else {
            return nil
        }
        let bytes = Array(data)
        self.address = BluetoothAddress(
            littleEndian: BluetoothAddress(
                bytes: (bytes[0], bytes[1], bytes[2], bytes[3], bytes[4], bytes[5])
            )
        )
        self.version = bytes[6]
        self.manufacturer = UInt16(littleEndian: UInt16(bytes: (bytes[7], bytes[8])))
        self.supportedSettings = ManagementSettings(
            rawValue: UInt32(littleEndian: UInt32(bytes: (bytes[9], bytes[10], bytes[11], bytes[12])))
        )
        self.currentSettings = ManagementSettings(
            rawValue: UInt32(littleEndian: UInt32(bytes: (bytes[13], bytes[14], bytes[15], bytes[16])))
        )
        self.classOfDevice = (bytes[17], bytes[18], bytes[19])
        let nameBytes = bytes[20 ..< 20 + Self.maximumNameLength]
        let shortNameBytes = bytes[20 + Self.maximumNameLength ..< Self.length]
        self.name = String(cString: nameBytes)
        self.shortName = String(cString: shortNameBytes)
    }
}

internal extension String {

    /// Initialize from a fixed-size null-terminated C string buffer.
    init<C: Collection>(cString bytes: C) where C.Element == UInt8 {
        let characters = bytes.prefix(while: { $0 != 0 })
        self.init(decoding: characters, as: UTF8.self)
    }
}
