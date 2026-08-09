//
//  HCICommandsInfo.swift
//  BluetoothLinux
//
//  Local controller information/identity: version, supported
//  commands/features, address, and the local device name.
//

import CBluetoothLinuxABI
import Glibc

extension read_local_version_rp: HCIStatusResponse {}
extension read_local_commands_rp: HCIStatusResponse {}
extension read_local_features_rp: HCIStatusResponse {}
extension read_local_ext_features_rp: HCIStatusResponse {}
extension read_bd_addr_rp: HCIStatusResponse {}
extension read_local_name_rp: HCIStatusResponse {}

/// `int hci_read_local_version(int dd, struct hci_version *ver, int to)`
@c(hci_read_local_version)
public func hci_read_local_version(_ dd: Int32, _ version: UnsafeMutablePointer<hci_version>?, _ timeout: Int32) -> Int32 {
    guard let version else { errno = EINVAL; return -1 }
    guard let response = hciRequest(
        dd, ogf: Int32(OGF_INFO_PARAM), ocf: Int32(OCF_READ_LOCAL_VERSION),
        response: read_local_version_rp.self, timeout: timeout
    ) else { return -1 }
    version.pointee.manufacturer = response.manufacturer
    version.pointee.hci_ver = response.hci_ver
    version.pointee.hci_rev = response.hci_rev
    version.pointee.lmp_ver = response.lmp_ver
    version.pointee.lmp_subver = response.lmp_subver
    return 0
}

/// `int hci_read_local_commands(int dd, uint8_t *commands, int to)`
@c(hci_read_local_commands)
public func hci_read_local_commands(_ dd: Int32, _ commands: UnsafeMutablePointer<UInt8>?, _ timeout: Int32) -> Int32 {
    guard var response = hciRequest(
        dd, ogf: Int32(OGF_INFO_PARAM), ocf: Int32(OCF_READ_LOCAL_COMMANDS),
        response: read_local_commands_rp.self, timeout: timeout
    ) else { return -1 }
    if let commands {
        withUnsafeMutableBytes(of: &response.commands) { commands.update(from: $0.bindMemory(to: UInt8.self).baseAddress!, count: 64) }
    }
    return 0
}

/// `int hci_read_local_features(int dd, uint8_t *features, int to)`
@c(hci_read_local_features)
public func hci_read_local_features(_ dd: Int32, _ features: UnsafeMutablePointer<UInt8>?, _ timeout: Int32) -> Int32 {
    guard var response = hciRequest(
        dd, ogf: Int32(OGF_INFO_PARAM), ocf: Int32(OCF_READ_LOCAL_FEATURES),
        response: read_local_features_rp.self, timeout: timeout
    ) else { return -1 }
    if let features {
        withUnsafeMutableBytes(of: &response.features) { features.update(from: $0.bindMemory(to: UInt8.self).baseAddress!, count: 8) }
    }
    return 0
}

/// `int hci_read_local_ext_features(int dd, uint8_t page, uint8_t *max_page, uint8_t *features, int to)`
@c(hci_read_local_ext_features)
public func hci_read_local_ext_features(
    _ dd: Int32,
    _ page: UInt8,
    _ maxPage: UnsafeMutablePointer<UInt8>?,
    _ features: UnsafeMutablePointer<UInt8>?,
    _ timeout: Int32
) -> Int32 {
    var command = read_local_ext_features_cp()
    command.page_num = page
    guard var response = hciRequest(
        dd, ogf: Int32(OGF_INFO_PARAM), ocf: Int32(OCF_READ_LOCAL_EXT_FEATURES),
        command: command, response: read_local_ext_features_rp.self, timeout: timeout
    ) else { return -1 }
    maxPage?.pointee = response.max_page_num
    if let features {
        withUnsafeMutableBytes(of: &response.features) { features.update(from: $0.bindMemory(to: UInt8.self).baseAddress!, count: 8) }
    }
    return 0
}

/// `int hci_read_bd_addr(int dd, bdaddr_t *bdaddr, int to)`
@c(hci_read_bd_addr)
public func hci_read_bd_addr(_ dd: Int32, _ bdaddr: UnsafeMutablePointer<bdaddr_t>?, _ timeout: Int32) -> Int32 {
    guard let response = hciRequest(
        dd, ogf: Int32(OGF_INFO_PARAM), ocf: Int32(OCF_READ_BD_ADDR),
        response: read_bd_addr_rp.self, timeout: timeout
    ) else { return -1 }
    bdaddr?.pointee = response.bdaddr
    return 0
}

/// `int hci_read_local_name(int dd, int len, char *name, int to)`
@c(hci_read_local_name)
public func hci_read_local_name(_ dd: Int32, _ len: Int32, _ name: UnsafeMutablePointer<CChar>?, _ timeout: Int32) -> Int32 {
    guard let name, len > 0 else { errno = EINVAL; return -1 }
    guard var response = hciRequest(
        dd, ogf: Int32(OGF_HOST_CTL), ocf: Int32(OCF_READ_LOCAL_NAME),
        response: read_local_name_rp.self, timeout: timeout
    ) else { return -1 }
    withUnsafeMutableBytes(of: &response.name) { buffer in
        buffer[247] = 0
        _ = strncpy(name, buffer.bindMemory(to: CChar.self).baseAddress!, Int(len))
    }
    return 0
}

/// `int hci_write_local_name(int dd, const char *name, int to)`
@c(hci_write_local_name)
public func hci_write_local_name(_ dd: Int32, _ name: UnsafePointer<CChar>?, _ timeout: Int32) -> Int32 {
    guard let name else { errno = EINVAL; return -1 }
    var command = change_local_name_cp()
    withUnsafeMutableBytes(of: &command.name) { buffer in
        _ = strncpy(buffer.bindMemory(to: CChar.self).baseAddress!, name, buffer.count - 1)
    }
    return hciCommand(dd, ogf: Int32(OGF_HOST_CTL), ocf: Int32(OCF_CHANGE_LOCAL_NAME), command: command, timeout: timeout)
}
