//
//  HCICommandsRemote.swift
//  BluetoothLinux
//
//  Wrappers that query a *remote* device over an existing link: name,
//  version, features, and clock offset. These wait for the matching
//  completion event rather than an immediate command-complete.
//

import CBluetoothLinuxABI
import Glibc

extension evt_remote_name_req_complete: HCIStatusResponse {}
extension evt_read_remote_version_complete: HCIStatusResponse {}
extension evt_read_remote_features_complete: HCIStatusResponse {}
extension evt_read_remote_ext_features_complete: HCIStatusResponse {}
extension evt_read_clock_offset_complete: HCIStatusResponse {}

/// `int hci_read_remote_name_with_clock_offset(int dd, const bdaddr_t *bdaddr, uint8_t pscan_rep_mode, uint16_t clkoffset, int len, char *name, int to)`
@c(hci_read_remote_name_with_clock_offset)
public func hci_read_remote_name_with_clock_offset(
    _ dd: Int32,
    _ bdaddr: UnsafePointer<bdaddr_t>?,
    _ pscanRepMode: UInt8,
    _ clockOffset: UInt16,
    _ len: Int32,
    _ name: UnsafeMutablePointer<CChar>?,
    _ timeout: Int32
) -> Int32 {
    guard let bdaddr, let name, len > 0 else { errno = EINVAL; return -1 }
    var command = remote_name_req_cp()
    command.bdaddr = bdaddr.pointee
    command.pscan_rep_mode = pscanRepMode
    command.clock_offset = clockOffset

    guard let response = hciRequest(
        dd, ogf: Int32(OGF_LINK_CTL), ocf: Int32(OCF_REMOTE_NAME_REQ), event: Int32(EVT_REMOTE_NAME_REQ_COMPLETE),
        command: command, response: evt_remote_name_req_complete.self, timeout: timeout
    ) else { return -1 }

    var responseName = response.name
    withUnsafeMutableBytes(of: &responseName) { buffer in
        buffer[247] = 0
        let source = buffer.bindMemory(to: CChar.self)
        _ = strncpy(name, source.baseAddress!, Int(len))
    }
    return 0
}

/// `int hci_read_remote_name(int dd, const bdaddr_t *bdaddr, int len, char *name, int to)`
@c(hci_read_remote_name)
public func hci_read_remote_name(
    _ dd: Int32,
    _ bdaddr: UnsafePointer<bdaddr_t>?,
    _ len: Int32,
    _ name: UnsafeMutablePointer<CChar>?,
    _ timeout: Int32
) -> Int32 {
    hci_read_remote_name_with_clock_offset(dd, bdaddr, 0x02, 0x0000, len, name, timeout)
}

/// `int hci_read_remote_name_cancel(int dd, const bdaddr_t *bdaddr, int to)`
@c(hci_read_remote_name_cancel)
public func hci_read_remote_name_cancel(_ dd: Int32, _ bdaddr: UnsafePointer<bdaddr_t>?, _ timeout: Int32) -> Int32 {
    guard let bdaddr else { errno = EINVAL; return -1 }
    var command = remote_name_req_cancel_cp()
    command.bdaddr = bdaddr.pointee
    return hciCommand(dd, ogf: Int32(OGF_LINK_CTL), ocf: Int32(OCF_REMOTE_NAME_REQ_CANCEL), command: command, timeout: timeout)
}

/// `int hci_read_remote_version(int dd, uint16_t handle, struct hci_version *ver, int to)`
@c(hci_read_remote_version)
public func hci_read_remote_version(_ dd: Int32, _ handle: UInt16, _ version: UnsafeMutablePointer<hci_version>?, _ timeout: Int32) -> Int32 {
    guard let version else { errno = EINVAL; return -1 }
    var command = read_remote_version_cp()
    command.handle = handle
    guard let response = hciRequest(
        dd, ogf: Int32(OGF_LINK_CTL), ocf: Int32(OCF_READ_REMOTE_VERSION), event: Int32(EVT_READ_REMOTE_VERSION_COMPLETE),
        command: command, response: evt_read_remote_version_complete.self, timeout: timeout
    ) else { return -1 }
    version.pointee.manufacturer = response.manufacturer
    version.pointee.lmp_ver = response.lmp_ver
    version.pointee.lmp_subver = response.lmp_subver
    return 0
}

/// `int hci_read_remote_features(int dd, uint16_t handle, uint8_t *features, int to)`
@c(hci_read_remote_features)
public func hci_read_remote_features(_ dd: Int32, _ handle: UInt16, _ features: UnsafeMutablePointer<UInt8>?, _ timeout: Int32) -> Int32 {
    var command = read_remote_features_cp()
    command.handle = handle
    guard var response = hciRequest(
        dd, ogf: Int32(OGF_LINK_CTL), ocf: Int32(OCF_READ_REMOTE_FEATURES), event: Int32(EVT_READ_REMOTE_FEATURES_COMPLETE),
        command: command, response: evt_read_remote_features_complete.self, timeout: timeout
    ) else { return -1 }
    if let features {
        withUnsafeMutableBytes(of: &response.features) { features.update(from: $0.bindMemory(to: UInt8.self).baseAddress!, count: 8) }
    }
    return 0
}

/// `int hci_read_remote_ext_features(int dd, uint16_t handle, uint8_t page, uint8_t *max_page, uint8_t *features, int to)`
@c(hci_read_remote_ext_features)
public func hci_read_remote_ext_features(
    _ dd: Int32,
    _ handle: UInt16,
    _ page: UInt8,
    _ maxPage: UnsafeMutablePointer<UInt8>?,
    _ features: UnsafeMutablePointer<UInt8>?,
    _ timeout: Int32
) -> Int32 {
    var command = read_remote_ext_features_cp()
    command.handle = handle
    command.page_num = page
    guard var response = hciRequest(
        dd, ogf: Int32(OGF_LINK_CTL), ocf: Int32(OCF_READ_REMOTE_EXT_FEATURES), event: Int32(EVT_READ_REMOTE_EXT_FEATURES_COMPLETE),
        command: command, response: evt_read_remote_ext_features_complete.self, timeout: timeout
    ) else { return -1 }
    maxPage?.pointee = response.max_page_num
    if let features {
        withUnsafeMutableBytes(of: &response.features) { features.update(from: $0.bindMemory(to: UInt8.self).baseAddress!, count: 8) }
    }
    return 0
}

/// `int hci_read_clock_offset(int dd, uint16_t handle, uint16_t *clkoffset, int to)`
@c(hci_read_clock_offset)
public func hci_read_clock_offset(_ dd: Int32, _ handle: UInt16, _ clockOffset: UnsafeMutablePointer<UInt16>?, _ timeout: Int32) -> Int32 {
    var command = read_clock_offset_cp()
    command.handle = handle
    guard let response = hciRequest(
        dd, ogf: Int32(OGF_LINK_CTL), ocf: Int32(OCF_READ_CLOCK_OFFSET), event: Int32(EVT_READ_CLOCK_OFFSET_COMPLETE),
        command: command, response: evt_read_clock_offset_complete.self, timeout: timeout
    ) else { return -1 }
    clockOffset?.pointee = response.clock_offset
    return 0
}
