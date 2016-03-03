//
//  LowEnergyCommandParameter.swift
//  BluetoothLinux
//
//  Created by Alsey Coleman Miller on 1/14/16.
//  Copyright © 2016 PureSwift. All rights reserved.
//

/*
#if os(Linux)
    import Glibc
#elseif os(OSX) || os(iOS)
    import Darwin.C
#endif

import typealias SwiftFoundation.Byte

#if os(OSX)
    public struct le_set_event_mask_cp {
        public var mask: (UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8)
        public init() { stub() }
    }
#endif

extension le_set_event_mask_cp: HCICommandParameter {
    public static var dataLength: CInt { return 8 }
}

#if os(OSX)
    public struct le_read_buffer_size_rp {
        public var status: UInt8
        public var pkt_len: UInt16
        public var max_pkt: UInt8
        public init() { stub() }
    }
#endif

extension le_read_buffer_size_rp: HCICommandParameter {
    public static var dataLength: CInt { return 4 }
}

#if os(OSX)
    public struct le_read_local_supported_features_rp {
        public var status: UInt8
        public var features: (UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8)
        public init() { stub() }
    }
#endif

extension le_read_local_supported_features_rp: HCICommandParameter {
    public static var dataLength: CInt { return 9 }
}

#if os(OSX)
    public struct le_set_random_address_cp {
        public var bdaddr: Address
        public init() { stub() }
    }
#endif

extension le_set_random_address_cp: HCICommandParameter {
    public static var dataLength: CInt { return 6 }
}

#if os(OSX)
    public struct le_set_advertising_parameters_cp {
        public var min_interval: UInt16
        public var max_interval: UInt16
        public var advtype: UInt8
        public var own_bdaddr_type: UInt8
        public var direct_bdaddr_type: UInt8
        public var direct_bdaddr: Address
        public var chan_map: UInt8
        public var filter: UInt8
        public init() { stub() }
    }
#endif

extension le_set_advertising_parameters_cp: HCICommandParameter {
    public static var dataLength: CInt { return 15 }
}

#if os(OSX)
    public struct le_read_advertising_channel_tx_power_rp {
        public var status: UInt8
        public var level: Int8
        public init() { stub() }
    }
#endif

extension le_read_advertising_channel_tx_power_rp: HCICommandParameter {
    public static var dataLength: CInt { return 2 }
}

#if os(OSX)
    public struct le_set_advertising_data_cp {
        public var length: UInt8
        public var data: LowEnergyAdvertisingData
        public init() { stub() }
    }
#endif

extension le_set_advertising_data_cp: HCICommandParameter {
    public static var dataLength: CInt { return 32 }
}

#if os(OSX)
    public struct le_set_scan_response_data_cp {
        public var length: UInt8
        public var data: LowEnergyAdvertisingData
        public init() { stub() }
    }
#endif

extension le_set_scan_response_data_cp: HCICommandParameter {
    public static var dataLength: CInt { return 32 }
}

#if os(OSX)
    public struct le_set_advertise_enable_cp {
        public var enable: UInt8
        public init() { stub() }
    }
#endif

extension le_set_advertise_enable_cp: HCICommandParameter {
    public static var dataLength: CInt { return 1 }
}

#if os(OSX)
    public struct le_set_scan_parameters_cp {
        public var type: UInt8
        public var interval: UInt16
        public var window: UInt16
        public var own_bdaddr_type: UInt8
        public var filter: UInt8
        public init() { stub() }
    }
#endif

extension le_set_scan_parameters_cp: HCICommandParameter {
    public static var dataLength: CInt { return 7 }
}

#if os(OSX)
    public struct le_set_scan_enable_cp {
        public var enable: UInt8
        public var filter_dup: UInt8
        public init() { stub() }
    }
#endif

extension le_set_scan_enable_cp: HCICommandParameter {
    public static var dataLength: CInt { return 2 }
}

#if os(OSX)
    public struct le_create_connection_cp {
        public var interval: UInt16
        public var window: UInt16
        public var initiator_filter: UInt8
        public var peer_bdaddr_type: UInt8
        public var peer_bdaddr: bdaddr_t
        public var own_bdaddr_type: UInt8
        public var min_interval: UInt16
        public var max_interval: UInt16
        public var latency: UInt16
        public var supervision_timeout: UInt16
        public var min_ce_length: UInt16
        public var max_ce_length: UInt16
        public init() { stub() }
    }
#endif

extension le_create_connection_cp: HCICommandParameter {
    public static var dataLength: CInt { return 25 }
}

#if os(OSX)
    public struct le_read_white_list_size_rp {
        public var bdaddr_type: UInt8
        public var bdaddr: bdaddr_t
        public init() { stub() }
    }
#endif

extension le_read_white_list_size_rp: HCICommandParameter {
    public static var dataLength: CInt { return 7 }
}

#if os(OSX)
    public struct le_set_host_channel_classification_cp {
        public var map: (UInt8, UInt8, UInt8, UInt8, UInt8)
        public init() { stub() }
    }
#endif

extension le_set_host_channel_classification_cp: HCICommandParameter {
    public static var dataLength: CInt { return 5 }
}

#if os(OSX)
    public struct le_read_channel_map_cp {
        public var handle: UInt16
        public init() { stub() }
    }
#endif

extension le_read_channel_map_cp: HCICommandParameter {
    public static var dataLength: CInt { return 2 }
}

#if os(OSX)
    public struct le_read_channel_map_rp {
        public var status: UInt8
        public var handle: UInt16
        public var map: (UInt8, UInt8, UInt8, UInt8, UInt8)
        public init() { stub() }
    }
#endif

extension le_read_channel_map_rp: HCICommandParameter {
    public static var dataLength: CInt { return 8 }
}

#if os(OSX)
    public struct le_read_remote_used_features_cp {
        public var handle: UInt16
        public init() { stub() }
    }
#endif

extension le_read_remote_used_features_cp: HCICommandParameter {
    public static var dataLength: CInt { return 2 }
}

#if os(OSX)
    public struct le_encrypt_cp {
        public var key: (UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8)
        public var plaintext: (UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8)
        public init() { stub() }
    }
#endif

extension le_encrypt_cp: HCICommandParameter {
    public static var dataLength: CInt { return 32 }
}

#if os(OSX)
    public struct le_encrypt_rp {
        public var status: UInt8
        public var data: (UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8)
        public init() { stub() }
    }
#endif

extension le_encrypt_rp: HCICommandParameter {
    public static var dataLength: CInt { return 17 }
}

#if os(OSX)
    public struct le_rand_rp {
        public var status: UInt8
        public var random: UInt64
        public init() { stub() }
    }
#endif

extension le_rand_rp: HCICommandParameter {
    public static var dataLength: CInt { return 9 }
}

*/


