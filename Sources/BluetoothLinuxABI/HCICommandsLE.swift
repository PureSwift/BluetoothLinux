//
//  HCICommandsLE.swift
//  BluetoothLinux
//
//  LE controller commands: the white list and resolving list (both
//  used for LE connection/scan filtering), scan and advertising
//  control, and LE connection establishment/update.
//

import CBluetoothLinuxABI
import Glibc

extension evt_le_connection_complete: HCIStatusResponse {}
extension evt_le_connection_update_complete: HCIStatusResponse {}
extension evt_le_read_remote_used_features_complete: HCIStatusResponse {}
extension le_read_white_list_size_rp: HCIStatusResponse {}
extension le_read_resolv_list_size_rp: HCIStatusResponse {}

/// `int hci_le_add_white_list(int dd, const bdaddr_t *bdaddr, uint8_t type, int to)`
@c(hci_le_add_white_list)
public func hci_le_add_white_list(_ dd: Int32, _ bdaddr: UnsafePointer<bdaddr_t>?, _ type: UInt8, _ timeout: Int32) -> Int32 {
    guard let bdaddr else { errno = EINVAL; return -1 }
    var command = le_add_device_to_white_list_cp()
    command.bdaddr_type = type
    command.bdaddr = bdaddr.pointee
    return hciStatus(dd, ogf: Int32(OGF_LE_CTL), ocf: Int32(OCF_LE_ADD_DEVICE_TO_WHITE_LIST), command: command, timeout: timeout)
}

/// `int hci_le_rm_white_list(int dd, const bdaddr_t *bdaddr, uint8_t type, int to)`
@c(hci_le_rm_white_list)
public func hci_le_rm_white_list(_ dd: Int32, _ bdaddr: UnsafePointer<bdaddr_t>?, _ type: UInt8, _ timeout: Int32) -> Int32 {
    guard let bdaddr else { errno = EINVAL; return -1 }
    var command = le_remove_device_from_white_list_cp()
    command.bdaddr_type = type
    command.bdaddr = bdaddr.pointee
    return hciStatus(dd, ogf: Int32(OGF_LE_CTL), ocf: Int32(OCF_LE_REMOVE_DEVICE_FROM_WHITE_LIST), command: command, timeout: timeout)
}

/// `int hci_le_read_white_list_size(int dd, uint8_t *size, int to)`
@c(hci_le_read_white_list_size)
public func hci_le_read_white_list_size(_ dd: Int32, _ size: UnsafeMutablePointer<UInt8>?, _ timeout: Int32) -> Int32 {
    guard let response = hciRequest(
        dd, ogf: Int32(OGF_LE_CTL), ocf: Int32(OCF_LE_READ_WHITE_LIST_SIZE),
        response: le_read_white_list_size_rp.self, timeout: timeout
    ) else { return -1 }
    size?.pointee = response.size
    return 0
}

/// `int hci_le_clear_white_list(int dd, int to)`
@c(hci_le_clear_white_list)
public func hci_le_clear_white_list(_ dd: Int32, _ timeout: Int32) -> Int32 {
    hciStatus(dd, ogf: Int32(OGF_LE_CTL), ocf: Int32(OCF_LE_CLEAR_WHITE_LIST), timeout: timeout)
}

/// `int hci_le_add_resolving_list(int dd, const bdaddr_t *bdaddr, uint8_t type, uint8_t *peer_irk, uint8_t *local_irk, int to)`
@c(hci_le_add_resolving_list)
public func hci_le_add_resolving_list(
    _ dd: Int32,
    _ bdaddr: UnsafePointer<bdaddr_t>?,
    _ type: UInt8,
    _ peerIRK: UnsafePointer<UInt8>?,
    _ localIRK: UnsafePointer<UInt8>?,
    _ timeout: Int32
) -> Int32 {
    guard let bdaddr else { errno = EINVAL; return -1 }
    var command = le_add_device_to_resolv_list_cp()
    command.bdaddr_type = type
    command.bdaddr = bdaddr.pointee
    if let peerIRK {
        withUnsafeMutableBytes(of: &command.peer_irk) { $0.copyMemory(from: UnsafeRawBufferPointer(start: peerIRK, count: 16)) }
    }
    if let localIRK {
        withUnsafeMutableBytes(of: &command.local_irk) { $0.copyMemory(from: UnsafeRawBufferPointer(start: localIRK, count: 16)) }
    }
    return hciStatus(dd, ogf: Int32(OGF_LE_CTL), ocf: Int32(OCF_LE_ADD_DEVICE_TO_RESOLV_LIST), command: command, timeout: timeout)
}

/// `int hci_le_rm_resolving_list(int dd, const bdaddr_t *bdaddr, uint8_t type, int to)`
@c(hci_le_rm_resolving_list)
public func hci_le_rm_resolving_list(_ dd: Int32, _ bdaddr: UnsafePointer<bdaddr_t>?, _ type: UInt8, _ timeout: Int32) -> Int32 {
    guard let bdaddr else { errno = EINVAL; return -1 }
    var command = le_remove_device_from_resolv_list_cp()
    command.bdaddr_type = type
    command.bdaddr = bdaddr.pointee
    return hciStatus(dd, ogf: Int32(OGF_LE_CTL), ocf: Int32(OCF_LE_REMOVE_DEVICE_FROM_RESOLV_LIST), command: command, timeout: timeout)
}

/// `int hci_le_clear_resolving_list(int dd, int to)`
@c(hci_le_clear_resolving_list)
public func hci_le_clear_resolving_list(_ dd: Int32, _ timeout: Int32) -> Int32 {
    hciStatus(dd, ogf: Int32(OGF_LE_CTL), ocf: Int32(OCF_LE_CLEAR_RESOLV_LIST), timeout: timeout)
}

/// `int hci_le_read_resolving_list_size(int dd, uint8_t *size, int to)`
@c(hci_le_read_resolving_list_size)
public func hci_le_read_resolving_list_size(_ dd: Int32, _ size: UnsafeMutablePointer<UInt8>?, _ timeout: Int32) -> Int32 {
    guard let response = hciRequest(
        dd, ogf: Int32(OGF_LE_CTL), ocf: Int32(OCF_LE_READ_RESOLV_LIST_SIZE),
        response: le_read_resolv_list_size_rp.self, timeout: timeout
    ) else { return -1 }
    size?.pointee = response.size
    return 0
}

/// `int hci_le_set_address_resolution_enable(int dd, uint8_t enable, int to)`
@c(hci_le_set_address_resolution_enable)
public func hci_le_set_address_resolution_enable(_ dd: Int32, _ enable: UInt8, _ timeout: Int32) -> Int32 {
    var command = le_set_address_resolution_enable_cp()
    command.enable = enable
    return hciStatus(dd, ogf: Int32(OGF_LE_CTL), ocf: Int32(OCF_LE_SET_ADDRESS_RESOLUTION_ENABLE), command: command, timeout: timeout)
}

/// `int hci_le_set_scan_enable(int dd, uint8_t enable, uint8_t filter_dup, int to)`
@c(hci_le_set_scan_enable)
public func hci_le_set_scan_enable(_ dd: Int32, _ enable: UInt8, _ filterDuplicates: UInt8, _ timeout: Int32) -> Int32 {
    var command = le_set_scan_enable_cp()
    command.enable = enable
    command.filter_dup = filterDuplicates
    return hciStatus(dd, ogf: Int32(OGF_LE_CTL), ocf: Int32(OCF_LE_SET_SCAN_ENABLE), command: command, timeout: timeout)
}

/// `int hci_le_set_scan_parameters(int dd, uint8_t type, uint16_t interval, uint16_t window, uint8_t own_type, uint8_t filter, int to)`
@c(hci_le_set_scan_parameters)
public func hci_le_set_scan_parameters(
    _ dd: Int32,
    _ type: UInt8,
    _ interval: UInt16,
    _ window: UInt16,
    _ ownType: UInt8,
    _ filter: UInt8,
    _ timeout: Int32
) -> Int32 {
    var command = le_set_scan_parameters_cp()
    command.type = type
    command.interval = interval
    command.window = window
    command.own_bdaddr_type = ownType
    command.filter = filter
    return hciStatus(dd, ogf: Int32(OGF_LE_CTL), ocf: Int32(OCF_LE_SET_SCAN_PARAMETERS), command: command, timeout: timeout)
}

/// `int hci_le_set_advertise_enable(int dd, uint8_t enable, int to)`
@c(hci_le_set_advertise_enable)
public func hci_le_set_advertise_enable(_ dd: Int32, _ enable: UInt8, _ timeout: Int32) -> Int32 {
    var command = le_set_advertise_enable_cp()
    command.enable = enable
    return hciStatus(dd, ogf: Int32(OGF_LE_CTL), ocf: Int32(OCF_LE_SET_ADVERTISE_ENABLE), command: command, timeout: timeout)
}

/// `int hci_le_create_conn(int dd, uint16_t interval, uint16_t window, uint8_t initiator_filter, uint8_t peer_bdaddr_type, bdaddr_t peer_bdaddr, uint8_t own_bdaddr_type, uint16_t min_interval, uint16_t max_interval, uint16_t latency, uint16_t supervision_timeout, uint16_t min_ce_length, uint16_t max_ce_length, uint16_t *handle, int to)`
@c(hci_le_create_conn)
public func hci_le_create_conn(
    _ dd: Int32,
    _ interval: UInt16,
    _ window: UInt16,
    _ initiatorFilter: UInt8,
    _ peerAddressType: UInt8,
    _ peerAddress: bdaddr_t,
    _ ownAddressType: UInt8,
    _ minInterval: UInt16,
    _ maxInterval: UInt16,
    _ latency: UInt16,
    _ supervisionTimeout: UInt16,
    _ minCELength: UInt16,
    _ maxCELength: UInt16,
    _ handle: UnsafeMutablePointer<UInt16>?,
    _ timeout: Int32
) -> Int32 {
    var command = le_create_connection_cp()
    command.interval = interval
    command.window = window
    command.initiator_filter = initiatorFilter
    command.peer_bdaddr_type = peerAddressType
    command.peer_bdaddr = peerAddress
    command.own_bdaddr_type = ownAddressType
    command.min_interval = minInterval
    command.max_interval = maxInterval
    command.latency = latency
    command.supervision_timeout = supervisionTimeout
    command.min_ce_length = minCELength
    command.max_ce_length = maxCELength

    guard let response = hciRequest(
        dd, ogf: Int32(OGF_LE_CTL), ocf: Int32(OCF_LE_CREATE_CONN), event: Int32(EVT_LE_CONN_COMPLETE),
        command: command, response: evt_le_connection_complete.self, timeout: timeout
    ) else { return -1 }
    handle?.pointee = response.handle
    return 0
}

/// `int hci_le_conn_update(int dd, uint16_t handle, uint16_t min_interval, uint16_t max_interval, uint16_t latency, uint16_t supervision_timeout, int to)`
@c(hci_le_conn_update)
public func hci_le_conn_update(
    _ dd: Int32,
    _ handle: UInt16,
    _ minInterval: UInt16,
    _ maxInterval: UInt16,
    _ latency: UInt16,
    _ supervisionTimeout: UInt16,
    _ timeout: Int32
) -> Int32 {
    var command = le_connection_update_cp()
    command.handle = handle
    command.min_interval = minInterval
    command.max_interval = maxInterval
    command.latency = latency
    command.supervision_timeout = supervisionTimeout
    command.min_ce_length = 0x0001
    command.max_ce_length = 0x0001

    guard hciRequest(
        dd, ogf: Int32(OGF_LE_CTL), ocf: Int32(OCF_LE_CONN_UPDATE), event: Int32(EVT_LE_CONN_UPDATE_COMPLETE),
        command: command, response: evt_le_connection_update_complete.self, timeout: timeout
    ) != nil else { return -1 }
    return 0
}

/// `int hci_le_read_remote_features(int dd, uint16_t handle, uint8_t *features, int to)`
@c(hci_le_read_remote_features)
public func hci_le_read_remote_features(_ dd: Int32, _ handle: UInt16, _ features: UnsafeMutablePointer<UInt8>?, _ timeout: Int32) -> Int32 {
    var command = le_read_remote_used_features_cp()
    command.handle = handle
    guard var response = hciRequest(
        dd, ogf: Int32(OGF_LE_CTL), ocf: Int32(OCF_LE_READ_REMOTE_USED_FEATURES), event: Int32(EVT_LE_READ_REMOTE_USED_FEATURES_COMPLETE),
        command: command, response: evt_le_read_remote_used_features_complete.self, timeout: timeout
    ) else { return -1 }
    if let features {
        withUnsafeMutableBytes(of: &response.features) { features.update(from: $0.bindMemory(to: UInt8.self).baseAddress!, count: 8) }
    }
    return 0
}
