//
//  SecurityType.swift
//  BlueZ
//
//  Created by Alsey Coleman Miller on 2/28/16.
//  Copyright © 2016 PureSwift. All rights reserved.
//

/// Bluetooth security level.
public enum SecurityLevel: UInt8 {
    
    case SDP        = 0
    case Low        = 1
    case Medium     = 2
    case High       = 3
    
    public init() { self = .SDP }
}