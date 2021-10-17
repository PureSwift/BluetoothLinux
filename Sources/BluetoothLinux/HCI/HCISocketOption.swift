//
//  HCISocketOption.swift
//  
//
//  Created by Alsey Coleman Miller on 16/10/21.
//

import Bluetooth
import BluetoothHCI
import SystemPackage

/// Bluetooth HCI Socket Option Identifier
public enum HCISocketOption: Int32, SocketOptionID {
    
    public static var optionLevel: SocketOptionLevel { .hostControllerInterface }
    
    case dataDirection                      = 1
    case filter                             = 2
    case timeStamp                          = 3
}
