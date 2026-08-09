//
//  HCICommandsConnection.swift
//  BluetoothLinux
//
//  Connection- and link-management HCI command wrappers: establishing
//  and tearing down ACL links, and the link-policy state changes that
//  wait for their own completion event rather than an immediate
//  command-complete (authentication, encryption, role switch, park
//  mode, link key changes).
//

import CBluetoothLinuxABI
import Glibc

extension evt_conn_complete: HCIStatusResponse {}
extension evt_disconn_complete: HCIStatusResponse {}
extension evt_auth_complete: HCIStatusResponse {}
extension evt_encrypt_change: HCIStatusResponse {}
extension evt_change_conn_link_key_complete: HCIStatusResponse {}
extension evt_role_change: HCIStatusResponse {}
extension evt_mode_change: HCIStatusResponse {}

/// `int hci_create_connection(int dd, const bdaddr_t *bdaddr, uint16_t ptype, uint16_t clkoffset, uint8_t rswitch, uint16_t *handle, int to)`
@c(hci_create_connection)
public func hci_create_connection(
    _ dd: Int32,
    _ bdaddr: UnsafePointer<bdaddr_t>?,
    _ ptype: UInt16,
    _ clockOffset: UInt16,
    _ roleSwitch: UInt8,
    _ handle: UnsafeMutablePointer<UInt16>?,
    _ timeout: Int32
) -> Int32 {
    guard let bdaddr else { errno = EINVAL; return -1 }
    var command = create_conn_cp()
    command.bdaddr = bdaddr.pointee
    command.pkt_type = ptype
    command.pscan_rep_mode = 0x02
    command.clock_offset = clockOffset
    command.role_switch = roleSwitch

    guard let response = hciRequest(
        dd, ogf: Int32(OGF_LINK_CTL), ocf: Int32(OCF_CREATE_CONN), event: Int32(EVT_CONN_COMPLETE),
        command: command, response: evt_conn_complete.self, timeout: timeout
    ) else { return -1 }
    handle?.pointee = response.handle
    return 0
}

/// `int hci_disconnect(int dd, uint16_t handle, uint8_t reason, int to)`
@c(hci_disconnect)
public func hci_disconnect(_ dd: Int32, _ handle: UInt16, _ reason: UInt8, _ timeout: Int32) -> Int32 {
    var command = disconnect_cp()
    command.handle = handle
    command.reason = reason
    guard hciRequest(
        dd, ogf: Int32(OGF_LINK_CTL), ocf: Int32(OCF_DISCONNECT), event: Int32(EVT_DISCONN_COMPLETE),
        command: command, response: evt_disconn_complete.self, timeout: timeout
    ) != nil else { return -1 }
    return 0
}

/// `int hci_authenticate_link(int dd, uint16_t handle, int to)`
@c(hci_authenticate_link)
public func hci_authenticate_link(_ dd: Int32, _ handle: UInt16, _ timeout: Int32) -> Int32 {
    var command = auth_requested_cp()
    command.handle = handle
    guard hciRequest(
        dd, ogf: Int32(OGF_LINK_CTL), ocf: Int32(OCF_AUTH_REQUESTED), event: Int32(EVT_AUTH_COMPLETE),
        command: command, response: evt_auth_complete.self, timeout: timeout
    ) != nil else { return -1 }
    return 0
}

/// `int hci_encrypt_link(int dd, uint16_t handle, uint8_t encrypt, int to)`
@c(hci_encrypt_link)
public func hci_encrypt_link(_ dd: Int32, _ handle: UInt16, _ encrypt: UInt8, _ timeout: Int32) -> Int32 {
    var command = set_conn_encrypt_cp()
    command.handle = handle
    command.encrypt = encrypt
    guard hciRequest(
        dd, ogf: Int32(OGF_LINK_CTL), ocf: Int32(OCF_SET_CONN_ENCRYPT), event: Int32(EVT_ENCRYPT_CHANGE),
        command: command, response: evt_encrypt_change.self, timeout: timeout
    ) != nil else { return -1 }
    return 0
}

/// `int hci_change_link_key(int dd, uint16_t handle, int to)`
@c(hci_change_link_key)
public func hci_change_link_key(_ dd: Int32, _ handle: UInt16, _ timeout: Int32) -> Int32 {
    var command = change_conn_link_key_cp()
    command.handle = handle
    guard hciRequest(
        dd, ogf: Int32(OGF_LINK_CTL), ocf: Int32(OCF_CHANGE_CONN_LINK_KEY), event: Int32(EVT_CHANGE_CONN_LINK_KEY_COMPLETE),
        command: command, response: evt_change_conn_link_key_complete.self, timeout: timeout
    ) != nil else { return -1 }
    return 0
}

/// `int hci_switch_role(int dd, bdaddr_t *bdaddr, uint8_t role, int to)`
@c(hci_switch_role)
public func hci_switch_role(_ dd: Int32, _ bdaddr: UnsafeMutablePointer<bdaddr_t>?, _ role: UInt8, _ timeout: Int32) -> Int32 {
    guard let bdaddr else { errno = EINVAL; return -1 }
    var command = switch_role_cp()
    command.bdaddr = bdaddr.pointee
    command.role = role
    guard hciRequest(
        dd, ogf: Int32(OGF_LINK_POLICY), ocf: Int32(OCF_SWITCH_ROLE), event: Int32(EVT_ROLE_CHANGE),
        command: command, response: evt_role_change.self, timeout: timeout
    ) != nil else { return -1 }
    return 0
}

/// `int hci_park_mode(int dd, uint16_t handle, uint16_t max_interval, uint16_t min_interval, int to)`
@c(hci_park_mode)
public func hci_park_mode(_ dd: Int32, _ handle: UInt16, _ maxInterval: UInt16, _ minInterval: UInt16, _ timeout: Int32) -> Int32 {
    var command = park_mode_cp()
    command.handle = handle
    command.max_interval = maxInterval
    command.min_interval = minInterval
    guard hciRequest(
        dd, ogf: Int32(OGF_LINK_POLICY), ocf: Int32(OCF_PARK_MODE), event: Int32(EVT_MODE_CHANGE),
        command: command, response: evt_mode_change.self, timeout: timeout
    ) != nil else { return -1 }
    return 0
}

/// `int hci_exit_park_mode(int dd, uint16_t handle, int to)`
@c(hci_exit_park_mode)
public func hci_exit_park_mode(_ dd: Int32, _ handle: UInt16, _ timeout: Int32) -> Int32 {
    var command = exit_park_mode_cp()
    command.handle = handle
    guard hciRequest(
        dd, ogf: Int32(OGF_LINK_POLICY), ocf: Int32(OCF_EXIT_PARK_MODE), event: Int32(EVT_MODE_CHANGE),
        command: command, response: evt_mode_change.self, timeout: timeout
    ) != nil else { return -1 }
    return 0
}
