//
//  HCI.swift
//  BlueZ
//
//  Created by Alsey Coleman Miller on 3/1/16.
//  Copyright © 2016 PureSwift. All rights reserved.
//

import SwiftFoundation

/// Bluetooth HCI
public struct HCI {
    
    // MARK: - Constants
    
    public static let MaximumDeviceCount    = 16
    
    public static let MaximumACLSize        = (1492 + 4)
    
    public static let MaximumSCOSize        = 255
    
    public static let MaximumEventSize      = 260
    
    public static let MaximumFrameSize      = MaximumACLSize + 4
    
    public static let TypeLength            = 1
    
    // MARK: - Typealiases
    
    public typealias Error                  = HCIError
    
    public typealias Event                  = HCIEvent
    
    public typealias DeviceFlag             = HCIDeviceFlag
    
    public typealias DeviceEvent            = HCIDeviceEvent
    
    public typealias ControllerType         = HCIControllerType
    
    public typealias BusType                = HCIBusType
    
    public typealias IOCTL                  = HCIIOCTL
}

/// HCI Errors
public enum HCIError: UInt8, ErrorType {
    
    case UnknownCommand                     = 0x01
    case NoConnection
    case HardwareFailure
    case PageTimeout
    case AuthenticationFailure
    case KeyMissing
    case MemoryFull
    case ConnectionTimeout
    case MaxConnections
    case MaxSCOConnections
    case ACLConnectionExists
    case CommandDisallowed
    case RejectedLimitedResources
    case RejectedSecurity
    case RejectedPersonal
    case HostTimeout
    case UnsupportedFeature
    case InvalidParameters
    case OEUserEndedConnection
    case OELowResources
    case OEPowerOff
    case ConnectionTerminated
    case RepeatedAttempts
    case PairingNotAllowed
    
    // ... Add More
    
    case TransactionCollision               = 0x2a
    case QOSUnacceptableParameter           = 0x2c
    
    // TODO: Add all errors
    
    case HostBusyPairing                    = 0x38
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

/// HCI `ioctl()` defines
public struct HCIIOCTL {
    
    /// #define HCIDEVUP	_IOW('H', 201, int)
    public static let DeviceUp              = IOC.IOW(CInt("H")!, 201, CInt.self)
    
    /// #define HCIDEVDOWN	_IOW('H', 202, int)
    public static let DeviceDown            = IOC.IOW(CInt("H")!, 202, CInt.self)
    
    /// #define HCIDEVRESET	_IOW('H', 203, int)
    public static let DeviceReset           = IOC.IOW(CInt("H")!, 203, CInt.self)
    
    /// #define HCIDEVRESTAT	_IOW('H', 204, int)
    public static let DeviceRestat          = IOC.IOW(CInt("H")!, 204, CInt.self)
    
    
    /// #define HCIGETDEVLIST	_IOR('H', 210, int)
    public static let GetDeviceList         = IOC.IOR(CInt("H")!, 210, CInt.self)
    
    /// #define HCIGETDEVINFO	_IOR('H', 211, int)
    public static let GetDeviceInfo         = IOC.IOR(CInt("H")!, 211, CInt.self)
    
    // TODO: All HCI ioctl defines
}

// MARK: - Internal Supporting Types

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
    var deviceRequest: ()
    
    init() { }
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

/* --------  HCI Packet structures  -------- */

/// hci_command_hdr (packed)
internal struct HCICommandHDR {
    
    static let length = 3
    
    /// OCF & OGF
    var opcode: UInt16 // uint16_t opcode;
    
    var parameterLength: UInt8 // uint8_t plen;
}



