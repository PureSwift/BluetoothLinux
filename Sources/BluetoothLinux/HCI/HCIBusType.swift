//
//  HCIBusType.swift
//  
//
//  Created by Alsey Coleman Miller on 16/10/21.
//

/// HCI bus types
public enum HCIBusType: CInt {
    
    case virtual
    case usb
    case pcCard
    case uart
    case rs232
    case pci
    case sdio
}
