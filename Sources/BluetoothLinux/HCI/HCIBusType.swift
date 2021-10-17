//
//  HCIBusType.swift
//  
//
//  Created by Alsey Coleman Miller on 16/10/21.
//

/// HCI bus types
public enum HCIBusType: CInt {
    
    case virtual    = 0
    case usb        = 1
    case pcCard     = 2
    case uart       = 3
    case rs232      = 4
    case pci        = 5
    case sdio       = 6
    case spi        = 7
    case i2c        = 8
    case smd        = 9
    case virtio     = 10
}
