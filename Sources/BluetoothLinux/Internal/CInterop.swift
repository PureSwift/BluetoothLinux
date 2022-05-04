//
//  CInterop.swift
//  
//
//  Created by Alsey Coleman Miller on 16/10/21.
//

import Bluetooth
import BluetoothHCI
import SystemPackage
import Socket
@_implementationOnly import CBluetoothLinux

public extension CInterop {
    
    /// `sockaddr_hci`
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
        let l2_family: SocketAddressFamily
        var l2_psm: CUnsignedShort = 0
        var l2_bdaddr: BluetoothAddress = .zero
        var l2_cid: CUnsignedShort = 0
        var l2_bdaddr_type: UInt8 = 0
        init() {
            self.l2_family = SocketAddressFamily(Self.family.rawValue)
        }
    }
}

extension CInterop.L2CAPSocketAddress: CSocketAddress {
    
    @usableFromInline
    static var family: SocketAddressFamily { .bluetooth }
}

public extension CInterop {
    
    /// `sockaddr_rc` RFCOMM socket address
    struct RFCOMMSocketAddress: Equatable, Hashable {
        
        public let family: CInterop.SocketAddressFamily
        public var address: BluetoothAddress
        public var channel: UInt8
        
        public init(address: BluetoothAddress = .zero, channel: UInt8 = 0) {
            self.family = .init(Self.family.rawValue)
            self.address = address
            self.channel = channel
        }
    }
}

extension CInterop.RFCOMMSocketAddress: CSocketAddress {
    
    @usableFromInline
    static var family: SocketAddressFamily { .bluetooth }
}

public extension CInterop {
    
    /// `sockaddr_sco` SCO Socket Address
    struct SCOSocketAddress: Equatable, Hashable {
        public let family: CInterop.SocketAddressFamily
        public var address: BluetoothAddress
        public init(address: BluetoothAddress = .zero) {
            self.family = .init(Self.family.rawValue)
            self.address = address
        }
    }
}

extension CInterop.SCOSocketAddress: CSocketAddress {
    
    @usableFromInline
    static var family: SocketAddressFamily { .bluetooth }
}

public extension CInterop {
    
    /// `l2cap_conninfo` L2CAP Connection Information
    struct L2CAPConnectionInfo {
        public var handle: UInt16
        public var deviceClass: (UInt8, UInt8, UInt8)
        public init(handle: UInt16 = 0,
                    deviceClass: (UInt8, UInt8, UInt8) = (0,0,0)) {
            self.handle = handle
            self.deviceClass = deviceClass
        }
    }
}

public extension CInterop {
    
    /// `l2cap_options` L2CAP Socket Options
    struct L2CAPSocketOptions {
        
        public var outputMaximumTransmissionUnit: UInt16 // omtu
        public var inputMaximumTransmissionUnit: UInt16 // imtu
        public var flushTo: UInt16 // flush_to
        public var mode: UInt8
        public var fcs: UInt8
        public var maxTX: UInt8 // max_tx
        public var txwinSize: UInt8 // txwin_size
        
        public init() {
            self.outputMaximumTransmissionUnit = 0
            self.inputMaximumTransmissionUnit = 0
            self.flushTo = 0
            self.mode = 0
            self.fcs = 0
            self.maxTX = 0
            self.txwinSize = 0
        }
    }
}

public extension CInterop {
    
    /// `bt_power` Bluetooth power options
    struct BluetoothPower {
        public var forceActive: UInt8
        public init(forceActive: UInt8 = 0) {
            self.forceActive = forceActive
        }
    };
}
    
public extension CInterop {

    /// `bt_security` Bluetooth security level (not packed)
    struct BluetoothSocketSecurity: Equatable, Hashable {
        var level: UInt8 = 0
        var key_size: UInt8 = 0
        init() { }
    }
}

public extension CInterop {
    
    /// `rfcomm_conninfo` RFCOMM Connection Information
    struct RFCOMMConnectionInfo {
        public var handle: UInt16
        public var deviceClass: (UInt8, UInt8, UInt8)
        public init(handle: UInt16 = 0,
                    deviceClass: (UInt8, UInt8, UInt8) = (0,0,0)) {
            self.handle = handle
            self.deviceClass = deviceClass
        }
    }
}

public extension CInterop {
    
    /// `rfcomm_dev_req`
    struct RFCOMMDeviceRequest: Equatable, Hashable {
        
        /// int16_t        dev_id;
        public let device: UInt16
        
        /// uint32_t    flags;
        public var flags: UInt32
        
        /// bdaddr_t    src;
        public var source: BluetoothAddress
        
        /// bdaddr_t    dst;
        public var destination: BluetoothAddress
        
        /// uint8_t    channel;
        public var channel: UInt8
        
        public init(
            device: UInt16,
            flags: UInt32,
            source: BluetoothAddress,
            destination: BluetoothAddress,
            channel: UInt8
        ) {
            self.device = device
            self.flags = flags
            self.source = source
            self.destination = destination
            self.channel = channel
        }
    }
}

public extension CInterop {
    
    /// `rfcomm_dev_info`
    struct RFCOMMDeviceInformation: Equatable, Hashable {
                
        /// int16_t        id;
        public let id: UInt16
        
        /// uint32_t    flags;
        public var flags: UInt32
        
        /// uint16_t    state;
        public var state: UInt16
        
        /// bdaddr_t    src;
        public var source: BluetoothAddress
        
        /// bdaddr_t    dst;
        public var destination: BluetoothAddress
        
        /// uint8_t        channel;
        public var channel: UInt8
        
        public init(
            id: UInt16,
            flags: UInt32,
            state: UInt16,
            source: BluetoothAddress,
            destination: BluetoothAddress,
            channel: UInt8
        ) {
            self.id = id
            self.flags = flags
            self.state = state
            self.source = source
            self.destination = destination
            self.channel = channel
        }
        
        @usableFromInline
        internal init(id: UInt16) {
            self.id = id
            self.flags = 0
            self.state = 0
            self.source = .zero
            self.destination = .zero
            self.channel = 0
        }
    }
}

public extension CInterop {
    
    /// `rfcomm_dev_list_req`
    struct RFCOMMDeviceListRequest {
        
        public var count: UInt16
        
        public init(count: UInt16) {
            self.count = count
        }
    }
}

public extension CInterop {
    
    /// `sco_conninfo` SCO Connection Information
    struct SCOConnectionInfo {
        
        public var handle: UInt16
        public var deviceClass: (UInt8, UInt8, UInt8)
        
        public init(handle: UInt16 = 0,
                    deviceClass: (UInt8, UInt8, UInt8) = (0,0,0)) {
            self.handle = handle
            self.deviceClass = deviceClass
        }
    }
}

public extension CInterop {
    
    /// `hci_dev_list_req`
    struct HCIDeviceList {
        
        /// uint16_t dev_num;
        public private(set) var numberOfDevices: UInt16
        
        /// struct hci_dev_req dev_req[0];    /* hci_dev_req structures */
        /// 16 elements
        public private(set) var list: (Element, Element, Element, Element, Element, Element, Element, Element, Element, Element, Element, Element, Element, Element, Element, Element)
        
        public init() {
            self.numberOfDevices = 0
            self.list = (Element(), Element(), Element(), Element(), Element(), Element(), Element(), Element(), Element(), Element(), Element(), Element(), Element(), Element(), Element(), Element())
        }
        
        @usableFromInline
        internal static func request(count: UInt16 = UInt16(Self.capacity)) -> Self {
            var value = self.init()
            value.numberOfDevices = count
            return value
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
        
        assert(index < Self.capacity, "HCIDeviceList can only contain up to \(Self.capacity) devices")
        
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
    
    public static var capacity: Int {
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
    
    struct HCIInquiryResult {
        
        /// Device Address
        public let address: BluetoothAddress
        
        public let pscanRepMode: UInt8
        
        public let pscanPeriodMode: UInt8
        
        public let pscanMode: UInt8
        
        public let deviceClass: (UInt8, UInt8, UInt8)
        
        public let clockOffset: UInt16
        
        public init() {
            self.address = .zero
            self.pscanRepMode = 0
            self.pscanPeriodMode = 0
            self.pscanMode = 0
            self.deviceClass = (0, 0, 0)
            self.clockOffset = 0
        }
    }
}

public extension CInterop {
    
    /// `hci_dev_info`
    struct HCIDeviceInformation {
        
        /// uint16_t dev_id;
        public let id: UInt16
        
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
        
        internal init() { }
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
    
    @usableFromInline
    mutating func setPacketType(_ type: HCIPacketType) {
        let bit = type == .vendor ? 0 : CInt(type.rawValue) & 31
        HCISetBit(bit, &typeMask)
    }
    
    @usableFromInline
    mutating func setEvent(_ event: UInt8) {
        let bit = (CInt(event) & 63)
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
