//
//  HCI.swift
//  BluetoothLinux
//
//  Created by Alsey Coleman Miller on 3/1/16.
//  Copyright © 2016 PureSwift. All rights reserved.
//

#if os(Linux)
    import Glibc
#elseif os(macOS) || os(iOS)
    import Darwin.C
#endif

import Bluetooth
import CSwiftBluetoothLinux

public extension HCI {
    
    // MARK: - Typealiases
    
    public typealias DeviceFlag             = HCIDeviceFlag
    
    public typealias DeviceEvent            = HCIDeviceEvent
    
    public typealias ControllerType         = HCIControllerType
    
    public typealias BusType                = HCIBusType
    
    public typealias IOCTL                  = HCIIOCTL
}

/// HCI device flags
public enum HCIDeviceFlag: CInt {
    
    case Up
    case Initialized
    case Running
    
    case PassiveScan
    case InteractiveScan
    case Authenticated
    case Encrypt
    case Inquiry
    
    case Raw
    
    public init() { self = .Up }
}

/// HCI controller types
public enum HCIControllerType: UInt8 {
    
    case BREDR                              = 0x00
    case AMP                                = 0x01
}

/// HCI bus types
public enum HCIBusType: CInt {
    
    case Virtual
    case USB
    case PCCard
    case UART
    case RS232
    case PCI
    case SDIO
}

/// HCI dev events
public enum HCIDeviceEvent: CInt {
    
    case Register                           = 1
    case Unregister
    case Up
    case Down
    case Suspend
    case Resume
}

/// HCI Packet types
public enum HCIPacketType: UInt8 {
    
    case Command                            = 0x01
    case ACL                                = 0x02
    case SCO                                = 0x03
    case Event                              = 0x04
    case Vendor                             = 0xff
}

/// HCI Socket Option
public enum HCISocketOption: CInt {
    
    case DataDirection                      = 1
    case Filter                             = 2
    case TimeStamp                          = 3
}

/// HCI `ioctl()` defines
public struct HCIIOCTL {
    
    private static let H                    = CInt(UnicodeScalar(unicodeScalarLiteral: "H").value)
    
    /// #define HCIDEVUP	_IOW('H', 201, int)
    public static let DeviceUp              = IOC.IOW(H, 201, CInt.self)
    
    /// #define HCIDEVDOWN	_IOW('H', 202, int)
    public static let DeviceDown            = IOC.IOW(H, 202, CInt.self)
    
    /// #define HCIDEVRESET	_IOW('H', 203, int)
    public static let DeviceReset           = IOC.IOW(H, 203, CInt.self)
    
    /// #define HCIDEVRESTAT	_IOW('H', 204, int)
    public static let DeviceRestat          = IOC.IOW(H, 204, CInt.self)
    
    
    /// #define HCIGETDEVLIST	_IOR('H', 210, int)
    public static let GetDeviceList         = IOC.IOR(H, 210, CInt.self)
    
    /// #define HCIGETDEVINFO	_IOR('H', 211, int)
    public static let GetDeviceInfo         = IOC.IOR(H, 211, CInt.self)
    
    // TODO: All HCI ioctl defines
    
    /// #define HCIINQUIRY	_IOR('H', 240, int)
    public static let Inquiry               = IOC.IOR(H, 240, CInt.self)
}

// MARK: - Internal Supporting Types

internal struct HCISocketAddress {
    
    var family = sa_family_t()
    
    var deviceIdentifier: UInt16 = 0
    
    var channel: UInt16 = 0
    
    init() { }
}

/* Ioctl requests structures */

/// `hci_dev_req`
internal struct HCIDeviceRequest {
    
    /// uint16_t dev_id;
    var identifier: UInt16 = 0
    
    /// uint32_t dev_opt;
    var options: UInt32 = 0
    
    init() { }
}

/// `hci_dev_list_req`
internal struct HCIDeviceListRequest {
    
    /// uint16_t dev_num;
    var count: UInt16 = 0
    
    /// struct hci_dev_req dev_req[0];	/* hci_dev_req structures */
    /// 16 elements
    var list: (HCIDeviceRequest, HCIDeviceRequest, HCIDeviceRequest, HCIDeviceRequest, HCIDeviceRequest, HCIDeviceRequest, HCIDeviceRequest, HCIDeviceRequest, HCIDeviceRequest, HCIDeviceRequest, HCIDeviceRequest, HCIDeviceRequest, HCIDeviceRequest, HCIDeviceRequest, HCIDeviceRequest, HCIDeviceRequest) = (HCIDeviceRequest(), HCIDeviceRequest(), HCIDeviceRequest(), HCIDeviceRequest(), HCIDeviceRequest(), HCIDeviceRequest(), HCIDeviceRequest(), HCIDeviceRequest(), HCIDeviceRequest(), HCIDeviceRequest(), HCIDeviceRequest(), HCIDeviceRequest(), HCIDeviceRequest(), HCIDeviceRequest(), HCIDeviceRequest(), HCIDeviceRequest())
    
    init() { }
    
    subscript (index: Int) -> HCIDeviceRequest {
        
        switch index {
            
        case 0:  return list.0
        case 1:  return list.1
        case 2:  return list.2
        case 3:  return list.3
        case 4:  return list.4
        case 5:  return list.5
        case 6:  return list.6
        case 7:  return list.7
        case 8:  return list.8
        case 9:  return list.9
        case 10: return list.10
        case 11: return list.11
        case 12: return list.12
        case 13: return list.13
        case 14: return list.14
        case 15: return list.15
            
        default: fatalError("Invalid index \(index)")
        }
    }
}

/// `hci_inquiry_req`
internal struct HCIInquiryRequest {
    
    /// uint16_t dev_id;
    var identifier: UInt16 = 0
    
    /// uint16_t flags;
    var flags: UInt16 = 0
    
    /// uint8_t  lap[3];
    var lap: (UInt8, UInt8, UInt8) = (0,0,0)
    
    /// uint8_t  length;
    var length: UInt8 = 0
    
    /// uint8_t  num_rsp;
    var responseCount: UInt8 = 0
    
    init() { }
}

/// `hci_dev_info`
internal struct HCIDeviceInformation {
    
    /// uint16_t dev_id;
    var identifier: UInt16 = 0
    
    /// char name[8];
    var name: (CChar, CChar, CChar, CChar, CChar, CChar, CChar, CChar) = (0, 0, 0, 0, 0, 0, 0, 0)
    
    /// bdaddr_t bdaddr;
    var address: Address = Address()
    
    /// uint32_t flags;
    var flags: UInt32 = 0
    
    /// uint8_t type;
    var type: UInt8 = 0
    
    /// uint8_t  features[8];
    var features: (UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8) = (0, 0, 0, 0, 0, 0, 0, 0)
    
    /// uint32_t pkt_type;
    var packetType: UInt32 = 0
    
    /// uint32_t link_policy;
    var linkPolicy: UInt32 = 0
    
    /// uint32_t link_mode;
    var linkMode: UInt32 = 0
    
    /// uint16_t acl_mtu;
    var ACLMaximumTransmissionUnit: UInt16 = 0
    
    /// uint16_t acl_pkts;
    var ACLPacketSize: UInt16 = 0
    
    /// uint16_t sco_mtu;
    var SCOMaximumTransmissionUnit: UInt16 = 0
    
    /// uint16_t sco_pkts;
    var SCOPacketSize: UInt16 = 0
    
    /// struct hci_dev_stats stat;
    var stat: HCIDeviceStats = HCIDeviceStats()
    
    init() { }
}

internal struct HCIDeviceStats {
    
    /// uint32_t err_rx;
    var errorRX: UInt32 = 0
    
    /// uint32_t err_tx;
    var errorTX: UInt32 = 0
    
    /// uint32_t cmd_tx;
    var commandTX: UInt32 = 0
    
    /// uint32_t evt_rx;
    var eventRX: UInt32 = 0
    
    /// uint32_t acl_tx;
    var ALC_TX: UInt32 = 0
    
    /// uint32_t acl_rx;
    var ALC_RX: UInt32 = 0
    
    /// uint32_t sco_tx;
    var SCO_TX: UInt32 = 0
    
    /// uint32_t sco_rx;
    var SCO_RX: UInt32 = 0
    
    /// uint32_t byte_rx;
    var byteRX: UInt32 = 0
    
    /// uint32_t byte_tx;
    var byteTX: UInt32 = 0
    
    init() { }
}

internal struct HCIFilter {
    
    internal struct Bits {
        
        static let FilterType           = CInt(31)
        static let Event                = CInt(63)
        static let OpcodeGroupField     = CInt(63)
        static let OpcodeCommandField   = CInt(127)
    }
    
    var typeMask: UInt32 = 0
    
    var eventMask: (UInt32, UInt32) = (0, 0)
    
    var opcode: UInt16 = 0
    
    init() { clear() }
    
    @inline(__always)
    mutating func clear() {
        
        memset(&self, 0, MemoryLayout<HCIFilter>.size)
    }
    
    @inline(__always)
    mutating func setPacketType(_ type: HCIPacketType) {
        
        let bit = type == .Vendor ? 0 : CInt(type.rawValue) & HCIFilter.Bits.FilterType
        
        HCISetBit(bit, &typeMask)
    }
    
    @inline(__always)
    mutating func setEvent(_ event: UInt8) {
        
        let bit = (CInt(event) & HCIFilter.Bits.Event)
        
        HCISetBit(bit, &eventMask.0)
    }
    
    @inline(__always)
    mutating func setEvent<T: HCIEvent>(_ event: T) {
        
        setEvent(event.rawValue)
    }
    
    @inline(__always)
    mutating func setEvent(_ event1: UInt8, _ event2: UInt8, _ event3: UInt8, _ event4: UInt8) {
        
        eventMask.0 = 0
        eventMask.0 += UInt32(event4) << 0o30
        eventMask.0 += UInt32(event3) << 0o20
        eventMask.0 += UInt32(event2) << 0o10
        eventMask.0 += UInt32(event1) << 0o00
    }
}

/*
@inline(__always)
internal func HCISetBit(bit: CInt, _ destination: UnsafeMutablePointer<Void>) {
    
    let addressPointer = UnsafeMutablePointer<UInt32>(destination)
    
    let destination = addressPointer.pointee
    
    let unsignedBit = UInt32(bitPattern: bit)
    
    addressPointer.pointee = (destination + (unsignedBit >> 5)) | (1 << (unsignedBit & 31))
}*/

/* --------  HCI Packet structures  -------- */

internal protocol HCIPacketHeader {
    
    static var length: Int { get }
    
    init?(bytes: [UInt8])
    
    var byteValue: [UInt8] { get }
}

// hci_command_hdr (packed)

/// HCI Command Packet Header
internal struct HCICommandHeader: HCIPacketHeader {
    
    static let length = 3
    
    /// OCF & OGF
    var opcode: UInt16
    
    var parameterLength: UInt8
    
    init(opcode: UInt16 = 0, parameterLength: UInt8 = 0) {
        
        self.opcode = opcode
        self.parameterLength = parameterLength
    }
    
    init?(bytes: [UInt8]) {
        
        guard bytes.count == HCICommandHeader.length
            else { return nil }
        
        self.opcode = UInt16(bytes: (bytes[0], bytes[1])).littleEndian
        self.parameterLength = bytes[2]
    }
    
    var byteValue: [UInt8] {
        
        let opcodeBytes = opcode.littleEndian.bytes
        
        return [opcodeBytes.0, opcodeBytes.1, parameterLength]
    }
}

/// HCI Event Packet Header
internal struct HCIEventHeader: HCIPacketHeader {
    
    static let length = 2
    
    var event: UInt8
    
    var parameterLength: UInt8
    
    init?(bytes: [UInt8]) {
        
        guard bytes.count == HCIEventHeader.length
            else { return nil }
        
        self.event = bytes[0]
        self.parameterLength = bytes[1]
    }
    
    var byteValue: [UInt8] {
        
        return [event, parameterLength]
    }
}

