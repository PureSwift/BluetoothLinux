//
//  ManagementSettings.swift
//  BluetoothLinux
//

/// Bluetooth Management interface controller settings.
///
/// Bitmask describing the supported or current settings of a controller.
@frozen
public struct ManagementSettings: OptionSet, Equatable, Hashable, Sendable {

    public let rawValue: UInt32

    public init(rawValue: UInt32) {
        self.rawValue = rawValue
    }
}

public extension ManagementSettings {

    static var powered: ManagementSettings                  { ManagementSettings(rawValue: 1 << 0) }

    static var connectable: ManagementSettings              { ManagementSettings(rawValue: 1 << 1) }

    static var fastConnectable: ManagementSettings          { ManagementSettings(rawValue: 1 << 2) }

    static var discoverable: ManagementSettings             { ManagementSettings(rawValue: 1 << 3) }

    static var bondable: ManagementSettings                 { ManagementSettings(rawValue: 1 << 4) }

    static var linkSecurity: ManagementSettings             { ManagementSettings(rawValue: 1 << 5) }

    static var secureSimplePairing: ManagementSettings      { ManagementSettings(rawValue: 1 << 6) }

    static var basicRateEnhancedDataRate: ManagementSettings { ManagementSettings(rawValue: 1 << 7) }

    static var highSpeed: ManagementSettings                { ManagementSettings(rawValue: 1 << 8) }

    static var lowEnergy: ManagementSettings                { ManagementSettings(rawValue: 1 << 9) }

    static var advertising: ManagementSettings              { ManagementSettings(rawValue: 1 << 10) }

    static var secureConnections: ManagementSettings        { ManagementSettings(rawValue: 1 << 11) }

    static var debugKeys: ManagementSettings                { ManagementSettings(rawValue: 1 << 12) }

    static var privacy: ManagementSettings                  { ManagementSettings(rawValue: 1 << 13) }

    static var configuration: ManagementSettings            { ManagementSettings(rawValue: 1 << 14) }

    static var staticAddress: ManagementSettings            { ManagementSettings(rawValue: 1 << 15) }

    static var phyConfiguration: ManagementSettings         { ManagementSettings(rawValue: 1 << 16) }

    static var widebandSpeech: ManagementSettings           { ManagementSettings(rawValue: 1 << 17) }
}

// MARK: - CustomStringConvertible

extension ManagementSettings: CustomStringConvertible, CustomDebugStringConvertible {

    public var description: String {
        let names: [(ManagementSettings, String)] = [
            (.powered, "powered"),
            (.connectable, "connectable"),
            (.fastConnectable, "fast-connectable"),
            (.discoverable, "discoverable"),
            (.bondable, "bondable"),
            (.linkSecurity, "link-security"),
            (.secureSimplePairing, "ssp"),
            (.basicRateEnhancedDataRate, "br/edr"),
            (.highSpeed, "hs"),
            (.lowEnergy, "le"),
            (.advertising, "advertising"),
            (.secureConnections, "secure-conn"),
            (.debugKeys, "debug-keys"),
            (.privacy, "privacy"),
            (.configuration, "configuration"),
            (.staticAddress, "static-addr"),
            (.phyConfiguration, "phy-configuration"),
            (.widebandSpeech, "wideband-speech")
        ]
        return names
            .compactMap { contains($0.0) ? $0.1 : nil }
            .joined(separator: " ")
    }

    public var debugDescription: String {
        description
    }
}
