//
//  HCIBusType.swift
//  
//
//  Created by Alsey Coleman Miller on 16/10/21.
//

/// HCI bus types
@frozen
public struct HCIBusType: RawRepresentable, Equatable, Hashable {
    
    public let rawValue: CInt
    
    public init(rawValue: CInt) {
        self.rawValue = rawValue
    }
    
    private init(_ raw: CInt) {
        self.init(rawValue: raw)
    }
}

// MARK: - Definitions

public extension HCIBusType {
    
    /// Bluetooth Virtual Bus Type
    static var virtual: HCIBusType       { HCIBusType(0) }
    
    /// Bluetooth USB controller type
    static var usb: HCIBusType           { HCIBusType(1) }
    
    /// Bluetooth PCCARD controller type
    static var pcCard: HCIBusType        { HCIBusType(2) }
    
    /// Bluetooth UART controller type
    static var uart: HCIBusType          { HCIBusType(3) }
    
    /// Bluetooth RS232 controller type
    static var rs232: HCIBusType         { HCIBusType(4) }
    
    /// Bluetooth PCI controller type
    static var pci: HCIBusType           { HCIBusType(5) }
    
    /// Bluetooth SDIO controller type
    static var sdio: HCIBusType          { HCIBusType(6) }
    
    /// Bluetooth SPI controller type
    static var spi: HCIBusType           { HCIBusType(7) }
    
    /// Bluetooth I2C controller type
    static var i2c: HCIBusType           { HCIBusType(8) }
    
    /// Bluetooth SMD controller type
    static var smd: HCIBusType           { HCIBusType(9) }
    
    /// Bluetooth VIRTIO controller type
    static var virtio: HCIBusType        { HCIBusType(10) }
}

// MARK: - Definitions

extension HCIBusType: CustomStringConvertible, CustomDebugStringConvertible {
    
    public var description: String {
        switch self {
        case .virtual:
            return "Virtual"
        case .usb:
            return "USB"
        case .pcCard:
            return "PCCARD"
        case .uart:
            return "UART"
        case .rs232:
            return "RS232"
        case .pci:
            return "PCI"
        case .sdio:
            return "SDIO"
        case .spi:
            return "SPI"
        case .i2c:
            return "I2C"
        case .smd:
            return "SMD"
        case .virtio:
            return "VIRTIO"
        default:
            return "Unknown \(rawValue)"
        }
    }
    
    public var debugDescription: String {
        description
    }
}
