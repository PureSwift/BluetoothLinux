//
//  SecurityType.swift
//  BluetoothLinux
//
//  Created by Alsey Coleman Miller on 2/28/16.
//  Copyright © 2016 PureSwift. All rights reserved.
//

/// Bluetooth security level.
public enum SecurityLevel: UInt8, Comparable {
    
    case SDP        = 0
    case Low        = 1
    case Medium     = 2
    case High       = 3
    case Fips       = 4
    
    public init() { self = .SDP }
}

// MARK: - Comparable

public func < (lhs: SecurityLevel, rhs: SecurityLevel) -> Bool {
    
    return lhs.rawValue < rhs.rawValue
}
