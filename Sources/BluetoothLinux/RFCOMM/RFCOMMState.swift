//
//  File.swift
//  
//
//  Created by Alsey Coleman Miller on 27/10/21.
//

/// RFCOMM State
public enum RFCOMMState: CInt, CaseIterable, Codable {
    
    case unknown = 0x00
    case connected
    case clean
    case bound
    case listening
    case connecting
    case connecting
    case config
    case disconnecting
    case closed
}
