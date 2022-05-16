//
//  HCIControllerType.swift
//  
//
//  Created by Alsey Coleman Miller on 16/10/21.
//

/// HCI controller types
@frozen
public struct HCIControllerType: RawRepresentable, Equatable, Hashable {
    
    public let rawValue: CInt
    
    public init(rawValue: CInt) {
        self.rawValue = rawValue
    }
    
    private init(_ raw: CInt) {
        self.init(rawValue: raw)
    }
}

// MARK: - Definitions

public extension HCIControllerType {
    
    /// Bluetooth Primary / BREDR controller type
    static var primary: HCIControllerType { HCIControllerType(0x00) } // Also known as BREDR
    
    /// Bluetooth AMP controller type
    static var amp: HCIControllerType { HCIControllerType(0x01) }
}

// MARK: - Definitions

extension HCIControllerType: CustomStringConvertible, CustomDebugStringConvertible {
    
    public var description: String {
        switch self {
        case .primary:
            return "Primary"
        case .amp:
            return "AMP"
        default:
            return "Unknown \(rawValue)"
        }
    }
    
    public var debugDescription: String {
        description
    }
}
