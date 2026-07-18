//
//  ManagementStatus.swift
//  BluetoothLinux
//

/// Bluetooth Management interface command status.
public enum ManagementStatus: UInt8, Error, Equatable, Hashable, Sendable, CaseIterable {

    case success            = 0x00
    case unknownCommand     = 0x01
    case notConnected       = 0x02
    case failed             = 0x03
    case connectFailed      = 0x04
    case authenticationFailed = 0x05
    case notPaired          = 0x06
    case noResources        = 0x07
    case timeout            = 0x08
    case alreadyConnected   = 0x09
    case busy               = 0x0A
    case rejected           = 0x0B
    case notSupported       = 0x0C
    case invalidParameters  = 0x0D
    case disconnected       = 0x0E
    case notPowered         = 0x0F
    case cancelled          = 0x10
    case invalidIndex       = 0x11
    case rfKilled           = 0x12
    case alreadyPaired      = 0x13
    case permissionDenied   = 0x14
}

// MARK: - CustomStringConvertible

extension ManagementStatus: CustomStringConvertible, CustomDebugStringConvertible {

    public var description: String {
        switch self {
        case .success:              return "Success"
        case .unknownCommand:       return "Unknown Command"
        case .notConnected:         return "Not Connected"
        case .failed:               return "Failed"
        case .connectFailed:        return "Connect Failed"
        case .authenticationFailed: return "Authentication Failed"
        case .notPaired:            return "Not Paired"
        case .noResources:          return "No Resources"
        case .timeout:              return "Timeout"
        case .alreadyConnected:     return "Already Connected"
        case .busy:                 return "Busy"
        case .rejected:             return "Rejected"
        case .notSupported:         return "Not Supported"
        case .invalidParameters:    return "Invalid Parameters"
        case .disconnected:         return "Disconnected"
        case .notPowered:           return "Not Powered"
        case .cancelled:            return "Cancelled"
        case .invalidIndex:         return "Invalid Index"
        case .rfKilled:             return "RF Killed"
        case .alreadyPaired:        return "Already Paired"
        case .permissionDenied:     return "Permission Denied"
        }
    }

    public var debugDescription: String {
        description
    }
}
