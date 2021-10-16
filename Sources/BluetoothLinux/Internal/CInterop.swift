//
//  CInterop.swift
//  
//
//  Created by Alsey Coleman Miller on 16/10/21.
//

import Bluetooth
import BluetoothHCI
import SystemPackage
import CBluetoothLinux

public extension CInterop {
    
    struct HCISocketAddress: Equatable, Hashable {
        
        public var family: CInterop.SocketAddressFamily //sa_family_t()
        public var device: UInt16
        public var channel: UInt16
        
        public init(
            device: UInt16 = 0,
            channel: UInt16 = 0
        ) {
            self.family = .init(CInterop.HCISocketAddress.family.rawValue)
            self.device = device
            self.channel = channel
        }
    }
}

extension CInterop.HCISocketAddress: CSocketAddress {
    
    @usableFromInline
    static var family: SocketAddressFamily { .bluetooth }
}

public extension CInterop {
    
    /// `sockaddr_l2` L2CAP socket address (not packed)
    struct L2CAPSocketAddress: Equatable, Hashable {
        var l2_family: sa_family_t = 0
        var l2_psm: CUnsignedShort = 0
        var l2_bdaddr: BluetoothAddress = .zero
        var l2_cid: CUnsignedShort = 0
        var l2_bdaddr_type: UInt8 = 0
        init() { }
    }
}

extension CInterop.L2CAPSocketAddress: CSocketAddress {
    
    @usableFromInline
    static var family: SocketAddressFamily { .bluetooth }
}
    
public extension CInterop {

    /// `bt_security` Bluetooth security level (not packed)
    struct BluetoothSocketSecurity: Equatable, Hashable {
        var level: UInt8 = 0
        var key_size: UInt8 = 0
        init() { }
    }
}

/* Ioctl requests structures */

public extension CInterop {
    
    /// `hci_dev_list_req`
    struct HCIDeviceList {
        
        /// uint16_t dev_num;
        public private(set) var numberOfDevices: UInt16
        
        /// struct hci_dev_req dev_req[0];    /* hci_dev_req structures */
        /// 16 elements
        public private(set) var list: (Element, Element, Element, Element, Element, Element, Element, Element, Element, Element, Element, Element, Element, Element, Element, Element)
        
        init() {
            self.numberOfDevices = 0
            self.list = (Element(), Element(), Element(), Element(), Element(), Element(), Element(), Element(), Element(), Element(), Element(), Element(), Element(), Element(), Element(), Element())
        }
    }
}

public extension CInterop.HCIDeviceList {
    
    /// `hci_dev_req`
    struct Element {
        
        /// uint16_t dev_id;
        public var id: UInt16
        
        /// uint32_t dev_opt;
        public var options: UInt32
        
        public init(id: UInt16, options: UInt32) {
            self.id = id
            self.options = options
        }
        
        internal init() {
            self.id = 0
            self.options = 0
        }
    }
}

extension CInterop.HCIDeviceList: Collection {
    
    public subscript (index: Int) -> Element {
        
        assert(index < capacity, "HCIDeviceList can only contain up to \(capacity) devices")
        
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
    
    public var capacity: Int {
        return 16
    }
    
    public var count: Int {
        return Int(numberOfDevices)
    }
    
    /// The start `Index`.
    public var startIndex: Int {
        return 0
    }
    
    /// The end `Index`.
    ///
    /// This is the "one-past-the-end" position, and will always be equal to the `count`.
    public var endIndex: Int {
        return count
    }
    
    public func index(before i: Int) -> Int {
        return i - 1
    }
    
    public func index(after i: Int) -> Int {
        return i + 1
    }
    
}

extension CInterop.HCIDeviceList: RandomAccessCollection {

    public subscript(bounds: Range<Int>) -> Slice<CInterop.HCIDeviceList> {
        return Slice<CInterop.HCIDeviceList>(base: self, bounds: bounds)
    }
    
    public func makeIterator() -> IndexingIterator<CInterop.HCIDeviceList> {
        return IndexingIterator(_elements: self)
    }
}

public extension CInterop {
    
    /// `hci_inquiry_req`
    struct HCIInquiryRequest {
        
        /// uint16_t dev_id;
        public var id: UInt16 = 0
        
        /// uint16_t flags;
        public var flags: UInt16 = 0
        
        /// uint8_t  lap[3];
        public var lap: (UInt8, UInt8, UInt8) = (0,0,0)
        
        /// uint8_t  length;
        public var length: UInt8 = 0
        
        /// uint8_t  num_rsp;
        public var responseCount: UInt8 = 0
        
        public init() { }
    }
}

public extension CInterop {
    
    /// `hci_dev_info`
    struct HCIDeviceInformation {
        
        /// uint16_t dev_id;
        public var id: UInt16
        
        /// char name[8];
        public var name: (CChar, CChar, CChar, CChar, CChar, CChar, CChar, CChar) = (0, 0, 0, 0, 0, 0, 0, 0)
        
        /// bdaddr_t bdaddr;
        public var address: (UInt8, UInt8, UInt8, UInt8, UInt8, UInt8) = (0,0,0,0,0,0)
        
        /// uint32_t flags;
        public var flags: UInt32 = 0
        
        /// uint8_t type;
        public var type: UInt8 = 0
        
        /// uint8_t  features[8];
        public var features: (UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8) = (0, 0, 0, 0, 0, 0, 0, 0)
        
        /// uint32_t pkt_type;
        public var packetType: UInt32 = 0
        
        /// uint32_t link_policy;
        public var linkPolicy: UInt32 = 0
        
        /// uint32_t link_mode;
        public var linkMode: UInt32 = 0
        
        /// uint16_t acl_mtu;
        public var aclMaximumTransmissionUnit: UInt16 = 0
        
        /// uint16_t acl_pkts;
        public var aclPacketSize: UInt16 = 0
        
        /// uint16_t sco_mtu;
        public var scoMaximumTransmissionUnit: UInt16 = 0
        
        /// uint16_t sco_pkts;
        public var scoPacketSize: UInt16 = 0
        
        /// struct hci_dev_stats stat;
        public var statistics: HCIDeviceStatistics = HCIDeviceStatistics()
        
        internal init(id: UInt16) {
            self.id = id
        }
    }
}

internal extension CInterop.HCIDeviceInformation {
    
    var _name: String {
        return withUnsafePointer(to: name) {
            $0.withMemoryRebound(to: CChar.self, capacity: 8) {
                return String(cString: $0)
            }
        }
    }
}

public extension CInterop {
    
    struct HCIDeviceStatistics: Equatable, Hashable {
        
        /// uint32_t err_rx;
        public let errorRX: UInt32 = 0
        
        /// uint32_t err_tx;
        public let errorTX: UInt32 = 0
        
        /// uint32_t cmd_tx;
        public let commandTX: UInt32 = 0
        
        /// uint32_t evt_rx;
        public let eventRX: UInt32 = 0
        
        /// uint32_t acl_tx;
        public let alcTX: UInt32 = 0
        
        /// uint32_t acl_rx;
        public let alcRX: UInt32 = 0
        
        /// uint32_t sco_tx;
        public let scoTX: UInt32 = 0
        
        /// uint32_t sco_rx;
        public let scoRX: UInt32 = 0
        
        /// uint32_t byte_rx;
        public let byteRX: UInt32 = 0
        
        /// uint32_t byte_tx;
        public let byteTX: UInt32 = 0
        
        public init() { }
    }
}

public extension CInterop {
    
    struct HCIFilterSocketOption {
        
        public var typeMask: UInt32 = 0
        
        public var eventMask: (UInt32, UInt32) = (0, 0)
        
        public var opcode: UInt16 = 0
        
        public init() { }
    }
}

internal extension CInterop.HCIFilterSocketOption {
    
    enum Bits {
        
        static var filterType: CInt           { CInt(31) }
        static var event: CInt                { CInt(63) }
        static var opcodeGroupField: CInt     { CInt(63) }
        static var opcodeCommandField: CInt   { CInt(127) }
    }
        
    @usableFromInline
    mutating func setPacketType(_ type: HCIPacketType) {
        let bit = type == .vendor ? 0 : CInt(type.rawValue) & CInterop.HCIFilterSocketOption.Bits.filterType
        HCISetBit(bit, &typeMask)
    }
    
    @usableFromInline
    mutating func setEvent(_ event: UInt8) {
        let bit = (CInt(event) & CInterop.HCIFilterSocketOption.Bits.event)
        HCISetBit(bit, &eventMask.0)
    }
    
    @usableFromInline
    mutating func setEvent(
        _ event1: UInt8,
        _ event2: UInt8,
        _ event3: UInt8,
        _ event4: UInt8
    ) {
        eventMask.0 = 0
        eventMask.0 += UInt32(event4) << 0o30
        eventMask.0 += UInt32(event3) << 0o20
        eventMask.0 += UInt32(event2) << 0o10
        eventMask.0 += UInt32(event1) << 0o00
    }
}
