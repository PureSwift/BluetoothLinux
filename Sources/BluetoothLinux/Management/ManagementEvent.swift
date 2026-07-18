//
//  ManagementEvent.swift
//  BluetoothLinux
//

/// Bluetooth Management interface event code.
///
/// Events received from the kernel over an HCI control channel (`HCI_CHANNEL_CONTROL`) socket.
@frozen
public struct ManagementEvent: RawRepresentable, Equatable, Hashable, Sendable {

    public let rawValue: UInt16

    public init(rawValue: UInt16) {
        self.rawValue = rawValue
    }
}

public extension ManagementEvent {

    /// Command Complete
    static var commandComplete: ManagementEvent                 { 0x0001 }

    /// Command Status
    static var commandStatus: ManagementEvent                   { 0x0002 }

    /// Controller Error
    static var controllerError: ManagementEvent                 { 0x0003 }

    /// Index Added
    static var indexAdded: ManagementEvent                      { 0x0004 }

    /// Index Removed
    static var indexRemoved: ManagementEvent                    { 0x0005 }

    /// New Settings
    static var newSettings: ManagementEvent                     { 0x0006 }

    /// Class Of Device Changed
    static var classOfDeviceChanged: ManagementEvent            { 0x0007 }

    /// Local Name Changed
    static var localNameChanged: ManagementEvent                { 0x0008 }

    /// New Link Key
    static var newLinkKey: ManagementEvent                      { 0x0009 }

    /// New Long Term Key
    static var newLongTermKey: ManagementEvent                  { 0x000A }

    /// Device Connected
    static var deviceConnected: ManagementEvent                 { 0x000B }

    /// Device Disconnected
    static var deviceDisconnected: ManagementEvent              { 0x000C }

    /// Connect Failed
    static var connectFailed: ManagementEvent                   { 0x000D }

    /// PIN Code Request
    static var pinCodeRequest: ManagementEvent                  { 0x000E }

    /// User Confirmation Request
    static var userConfirmationRequest: ManagementEvent         { 0x000F }

    /// User Passkey Request
    static var userPasskeyRequest: ManagementEvent              { 0x0010 }

    /// Authentication Failed
    static var authenticationFailed: ManagementEvent            { 0x0011 }

    /// Device Found
    static var deviceFound: ManagementEvent                     { 0x0012 }

    /// Discovering
    static var discovering: ManagementEvent                     { 0x0013 }

    /// Device Blocked
    static var deviceBlocked: ManagementEvent                   { 0x0014 }

    /// Device Unblocked
    static var deviceUnblocked: ManagementEvent                 { 0x0015 }

    /// Device Unpaired
    static var deviceUnpaired: ManagementEvent                  { 0x0016 }

    /// Passkey Notify
    static var passkeyNotify: ManagementEvent                   { 0x0017 }

    /// New Identity Resolving Key
    static var newIdentityResolvingKey: ManagementEvent         { 0x0018 }

    /// New Signature Resolving Key
    static var newSignatureResolvingKey: ManagementEvent        { 0x0019 }

    /// Device Added
    static var deviceAdded: ManagementEvent                     { 0x001A }

    /// Device Removed
    static var deviceRemoved: ManagementEvent                   { 0x001B }

    /// New Connection Parameters
    static var newConnectionParameters: ManagementEvent         { 0x001C }

    /// Unconfigured Index Added
    static var unconfiguredIndexAdded: ManagementEvent          { 0x001D }

    /// Unconfigured Index Removed
    static var unconfiguredIndexRemoved: ManagementEvent        { 0x001E }

    /// New Configuration Options
    static var newConfigurationOptions: ManagementEvent         { 0x001F }

    /// Extended Index Added
    static var extendedIndexAdded: ManagementEvent              { 0x0020 }

    /// Extended Index Removed
    static var extendedIndexRemoved: ManagementEvent            { 0x0021 }

    /// Local Out Of Band Data Updated
    static var localOutOfBandDataUpdated: ManagementEvent       { 0x0022 }

    /// Advertising Added
    static var advertisingAdded: ManagementEvent                { 0x0023 }

    /// Advertising Removed
    static var advertisingRemoved: ManagementEvent              { 0x0024 }

    /// Extended Controller Information Changed
    static var extendedControllerInformationChanged: ManagementEvent { 0x0025 }

    /// PHY Configuration Changed
    static var phyConfigurationChanged: ManagementEvent         { 0x0026 }

    /// Experimental Feature Changed
    static var experimentalFeatureChanged: ManagementEvent      { 0x0027 }

    /// Default System Configuration Changed
    static var defaultSystemConfigurationChanged: ManagementEvent { 0x0028 }

    /// Default Runtime Configuration Changed
    static var defaultRuntimeConfigurationChanged: ManagementEvent { 0x0029 }

    /// Device Flags Changed
    static var deviceFlagsChanged: ManagementEvent              { 0x002A }

    /// Advertisement Monitor Added
    static var advertisementMonitorAdded: ManagementEvent       { 0x002B }

    /// Advertisement Monitor Removed
    static var advertisementMonitorRemoved: ManagementEvent     { 0x002C }

    /// Controller Suspend
    static var controllerSuspend: ManagementEvent               { 0x002D }

    /// Controller Resume
    static var controllerResume: ManagementEvent                { 0x002E }
}

// MARK: - ExpressibleByIntegerLiteral

extension ManagementEvent: ExpressibleByIntegerLiteral {

    public init(integerLiteral value: UInt16) {
        self.init(rawValue: value)
    }
}

// MARK: - CustomStringConvertible

extension ManagementEvent: CustomStringConvertible, CustomDebugStringConvertible {

    public var description: String {
        "0x" + String(rawValue, radix: 16, uppercase: true).padded(to: 4)
    }

    public var debugDescription: String {
        description
    }
}
