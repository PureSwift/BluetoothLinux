//
//  HCIChannel.swift
//  
//
//  Created by Alsey Coleman Miller on 16/10/21.
//

/// HCI Channel
public enum HCIChannel: UInt16 {
    
    case raw        = 0
    case user       = 1
    case monitor    = 2
    case control    = 3
    case logging    = 4
}
