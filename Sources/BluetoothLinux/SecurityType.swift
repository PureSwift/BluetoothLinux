//
//  SecurityType.swift
//  BluetoothLinux
//
//  Created by Alsey Coleman Miller on 2/28/16.
//  Copyright © 2016 PureSwift. All rights reserved.
//

/// Bluetooth security level.
public enum SecurityLevel: UInt8, Comparable {
    
    case sdp        = 0
    case low        = 1
    case medium     = 2
    case high       = 3
    case fips       = 4
    
    public init() { self = .sdp }
}

// MARK: - Comparable

public func < (lhs: SecurityLevel, rhs: SecurityLevel) -> Bool {
    
    return lhs.rawValue < rhs.rawValue
}
