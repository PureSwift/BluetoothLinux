//
//  ManagementOpcode.swift
//  BluetoothLinux
//

/// Bluetooth Management interface command opcode.
///
/// Commands sent to the kernel over an HCI control channel (`HCI_CHANNEL_CONTROL`) socket.
@frozen
public struct ManagementOpcode: RawRepresentable, Equatable, Hashable, Sendable {

    public let rawValue: UInt16

    public init(rawValue: UInt16) {
        self.rawValue = rawValue
    }
}

public extension ManagementOpcode {

    /// Read Management Version Information
    static var readVersion: ManagementOpcode                    { 0x0001 }

    /// Read Management Supported Commands
    static var readCommands: ManagementOpcode                   { 0x0002 }

    /// Read Controller Index List
    static var readIndexList: ManagementOpcode                  { 0x0003 }

    /// Read Controller Information
    static var readControllerInformation: ManagementOpcode      { 0x0004 }

    /// Set Powered
    static var setPowered: ManagementOpcode                     { 0x0005 }

    /// Set Discoverable
    static var setDiscoverable: ManagementOpcode                { 0x0006 }

    /// Set Connectable
    static var setConnectable: ManagementOpcode                 { 0x0007 }

    /// Set Fast Connectable
    static var setFastConnectable: ManagementOpcode             { 0x0008 }

    /// Set Bondable
    static var setBondable: ManagementOpcode                    { 0x0009 }

    /// Set Link Security
    static var setLinkSecurity: ManagementOpcode                { 0x000A }

    /// Set Secure Simple Pairing
    static var setSecureSimplePairing: ManagementOpcode         { 0x000B }

    /// Set High Speed
    static var setHighSpeed: ManagementOpcode                   { 0x000C }

    /// Set Low Energy
    static var setLowEnergy: ManagementOpcode                   { 0x000D }

    /// Set Device Class
    static var setDeviceClass: ManagementOpcode                 { 0x000E }

    /// Set Local Name
    static var setLocalName: ManagementOpcode                   { 0x000F }

    /// Add UUID
    static var addUUID: ManagementOpcode                        { 0x0010 }

    /// Remove UUID
    static var removeUUID: ManagementOpcode                     { 0x0011 }

    /// Load Link Keys
    static var loadLinkKeys: ManagementOpcode                   { 0x0012 }

    /// Load Long Term Keys
    static var loadLongTermKeys: ManagementOpcode               { 0x0013 }

    /// Disconnect
    static var disconnect: ManagementOpcode                     { 0x0014 }

    /// Get Connections
    static var getConnections: ManagementOpcode                 { 0x0015 }

    /// PIN Code Reply
    static var pinCodeReply: ManagementOpcode                   { 0x0016 }

    /// PIN Code Negative Reply
    static var pinCodeNegativeReply: ManagementOpcode           { 0x0017 }

    /// Set IO Capability
    static var setIOCapability: ManagementOpcode                { 0x0018 }

    /// Pair Device
    static var pairDevice: ManagementOpcode                     { 0x0019 }

    /// Cancel Pair Device
    static var cancelPairDevice: ManagementOpcode               { 0x001A }

    /// Unpair Device
    static var unpairDevice: ManagementOpcode                   { 0x001B }

    /// User Confirmation Reply
    static var userConfirmationReply: ManagementOpcode          { 0x001C }

    /// User Confirmation Negative Reply
    static var userConfirmationNegativeReply: ManagementOpcode  { 0x001D }

    /// User Passkey Reply
    static var userPasskeyReply: ManagementOpcode               { 0x001E }

    /// User Passkey Negative Reply
    static var userPasskeyNegativeReply: ManagementOpcode       { 0x001F }

    /// Read Local Out Of Band Data
    static var readLocalOutOfBandData: ManagementOpcode         { 0x0020 }

    /// Add Remote Out Of Band Data
    static var addRemoteOutOfBandData: ManagementOpcode         { 0x0021 }

    /// Remove Remote Out Of Band Data
    static var removeRemoteOutOfBandData: ManagementOpcode      { 0x0022 }

    /// Start Discovery
    static var startDiscovery: ManagementOpcode                 { 0x0023 }

    /// Stop Discovery
    static var stopDiscovery: ManagementOpcode                  { 0x0024 }

    /// Confirm Name
    static var confirmName: ManagementOpcode                    { 0x0025 }

    /// Block Device
    static var blockDevice: ManagementOpcode                    { 0x0026 }

    /// Unblock Device
    static var unblockDevice: ManagementOpcode                  { 0x0027 }

    /// Set Device ID
    static var setDeviceID: ManagementOpcode                    { 0x0028 }

    /// Set Advertising
    static var setAdvertising: ManagementOpcode                 { 0x0029 }

    /// Set BR/EDR
    static var setBREDR: ManagementOpcode                       { 0x002A }

    /// Set Static Address
    static var setStaticAddress: ManagementOpcode               { 0x002B }

    /// Set Scan Parameters
    static var setScanParameters: ManagementOpcode              { 0x002C }

    /// Set Secure Connections
    static var setSecureConnections: ManagementOpcode           { 0x002D }

    /// Set Debug Keys
    static var setDebugKeys: ManagementOpcode                   { 0x002E }

    /// Set Privacy
    static var setPrivacy: ManagementOpcode                     { 0x002F }

    /// Load Identity Resolving Keys
    static var loadIdentityResolvingKeys: ManagementOpcode      { 0x0030 }

    /// Get Connection Information
    static var getConnectionInformation: ManagementOpcode       { 0x0031 }

    /// Get Clock Information
    static var getClockInformation: ManagementOpcode            { 0x0032 }

    /// Add Device
    static var addDevice: ManagementOpcode                      { 0x0033 }

    /// Remove Device
    static var removeDevice: ManagementOpcode                   { 0x0034 }

    /// Load Connection Parameters
    static var loadConnectionParameters: ManagementOpcode       { 0x0035 }

    /// Read Unconfigured Controller Index List
    static var readUnconfiguredIndexList: ManagementOpcode      { 0x0036 }

    /// Read Controller Configuration Information
    static var readControllerConfiguration: ManagementOpcode    { 0x0037 }

    /// Set External Configuration
    static var setExternalConfiguration: ManagementOpcode       { 0x0038 }

    /// Set Public Address
    static var setPublicAddress: ManagementOpcode               { 0x0039 }

    /// Start Service Discovery
    static var startServiceDiscovery: ManagementOpcode          { 0x003A }

    /// Read Local Out Of Band Extended Data
    static var readLocalOutOfBandExtendedData: ManagementOpcode { 0x003B }

    /// Read Extended Controller Index List
    static var readExtendedIndexList: ManagementOpcode          { 0x003C }

    /// Read Advertising Features
    static var readAdvertisingFeatures: ManagementOpcode        { 0x003D }

    /// Add Advertising
    static var addAdvertising: ManagementOpcode                 { 0x003E }

    /// Remove Advertising
    static var removeAdvertising: ManagementOpcode              { 0x003F }

    /// Get Advertising Size Information
    static var getAdvertisingSizeInformation: ManagementOpcode  { 0x0040 }

    /// Start Limited Discovery
    static var startLimitedDiscovery: ManagementOpcode          { 0x0041 }

    /// Read Extended Controller Information
    static var readExtendedControllerInformation: ManagementOpcode { 0x0042 }

    /// Set Appearance
    static var setAppearance: ManagementOpcode                  { 0x0043 }

    /// Get PHY Configuration
    static var getPHYConfiguration: ManagementOpcode            { 0x0044 }

    /// Set PHY Configuration
    static var setPHYConfiguration: ManagementOpcode            { 0x0045 }

    /// Set Blocked Keys
    static var setBlockedKeys: ManagementOpcode                 { 0x0046 }

    /// Set Wideband Speech
    static var setWidebandSpeech: ManagementOpcode              { 0x0047 }
}

// MARK: - ExpressibleByIntegerLiteral

extension ManagementOpcode: ExpressibleByIntegerLiteral {

    public init(integerLiteral value: UInt16) {
        self.init(rawValue: value)
    }
}

// MARK: - CustomStringConvertible

extension ManagementOpcode: CustomStringConvertible, CustomDebugStringConvertible {

    public var description: String {
        "0x" + String(rawValue, radix: 16, uppercase: true).padded(to: 4)
    }

    public var debugDescription: String {
        description
    }
}

internal extension String {

    func padded(to length: Int) -> String {
        count < length ? String(repeating: "0", count: length - count) + self : self
    }
}
