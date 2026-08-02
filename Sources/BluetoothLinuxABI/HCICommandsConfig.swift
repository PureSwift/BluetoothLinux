//
//  HCICommandsConfig.swift
//  BluetoothLinux
//
//  Controller configuration and status-parameter wrappers: class of
//  device, voice setting, inquiry access codes, stored link keys,
//  inquiry/AFH/inquiry-mode toggles, extended inquiry response, simple
//  pairing, OOB data, transmit power, link policy/supervision timeout,
//  AFH classification, and per-connection link quality/RSSI/AFH
//  map/clock queries.
//

import CBluetoothLinuxABI
import Glibc

extension read_class_of_dev_rp: HCIStatusResponse {}
extension read_voice_setting_rp: HCIStatusResponse {}
extension read_current_iac_lap_rp: HCIStatusResponse {}
extension read_inquiry_scan_type_rp: HCIStatusResponse {}
extension write_inquiry_scan_type_rp: HCIStatusResponse {}
extension read_inquiry_mode_rp: HCIStatusResponse {}
extension write_inquiry_mode_rp: HCIStatusResponse {}
extension read_afh_mode_rp: HCIStatusResponse {}
extension write_afh_mode_rp: HCIStatusResponse {}
extension read_ext_inquiry_response_rp: HCIStatusResponse {}
extension write_ext_inquiry_response_rp: HCIStatusResponse {}
extension read_simple_pairing_mode_rp: HCIStatusResponse {}
extension write_simple_pairing_mode_rp: HCIStatusResponse {}
extension read_local_oob_data_rp: HCIStatusResponse {}
extension read_inq_response_tx_power_level_rp: HCIStatusResponse {}
extension write_inquiry_transmit_power_level_rp: HCIStatusResponse {}
extension read_transmit_power_level_rp: HCIStatusResponse {}
extension read_link_policy_rp: HCIStatusResponse {}
extension write_link_policy_rp: HCIStatusResponse {}
extension read_link_supervision_timeout_rp: HCIStatusResponse {}
extension write_link_supervision_timeout_rp: HCIStatusResponse {}
extension set_afh_classification_rp: HCIStatusResponse {}
extension read_link_quality_rp: HCIStatusResponse {}
extension read_rssi_rp: HCIStatusResponse {}
extension read_afh_map_rp: HCIStatusResponse {}
extension read_clock_rp: HCIStatusResponse {}

// MARK: - Class of device

/// `int hci_read_class_of_dev(int dd, uint8_t *cls, int to)`
@c(hci_read_class_of_dev)
public func hci_read_class_of_dev(_ dd: Int32, _ deviceClass: UnsafeMutablePointer<UInt8>?, _ timeout: Int32) -> Int32 {
    guard var response = hciRequest(
        dd, ogf: Int32(OGF_HOST_CTL), ocf: Int32(OCF_READ_CLASS_OF_DEV),
        response: read_class_of_dev_rp.self, timeout: timeout
    ) else { return -1 }
    guard let deviceClass else { errno = EINVAL; return -1 }
    withUnsafeMutableBytes(of: &response.dev_class) { deviceClass.update(from: $0.bindMemory(to: UInt8.self).baseAddress!, count: 3) }
    return 0
}

/// `int hci_write_class_of_dev(int dd, uint32_t cls, int to)`
@c(hci_write_class_of_dev)
public func hci_write_class_of_dev(_ dd: Int32, _ deviceClass: UInt32, _ timeout: Int32) -> Int32 {
    var command = write_class_of_dev_cp()
    command.dev_class.0 = UInt8(deviceClass & 0xff)
    command.dev_class.1 = UInt8((deviceClass >> 8) & 0xff)
    command.dev_class.2 = UInt8((deviceClass >> 16) & 0xff)
    return hciCommand(dd, ogf: Int32(OGF_HOST_CTL), ocf: Int32(OCF_WRITE_CLASS_OF_DEV), command: command, timeout: timeout)
}

// MARK: - Voice setting

/// `int hci_read_voice_setting(int dd, uint16_t *vs, int to)`
@c(hci_read_voice_setting)
public func hci_read_voice_setting(_ dd: Int32, _ voiceSetting: UnsafeMutablePointer<UInt16>?, _ timeout: Int32) -> Int32 {
    guard let response = hciRequest(
        dd, ogf: Int32(OGF_HOST_CTL), ocf: Int32(OCF_READ_VOICE_SETTING),
        response: read_voice_setting_rp.self, timeout: timeout
    ) else { return -1 }
    voiceSetting?.pointee = response.voice_setting
    return 0
}

/// `int hci_write_voice_setting(int dd, uint16_t vs, int to)`
@c(hci_write_voice_setting)
public func hci_write_voice_setting(_ dd: Int32, _ voiceSetting: UInt16, _ timeout: Int32) -> Int32 {
    var command = write_voice_setting_cp()
    command.voice_setting = voiceSetting
    return hciCommand(dd, ogf: Int32(OGF_HOST_CTL), ocf: Int32(OCF_WRITE_VOICE_SETTING), command: command, timeout: timeout)
}

// MARK: - Current IAC LAP

/// `int hci_read_current_iac_lap(int dd, uint8_t *num_iac, uint8_t *lap, int to)`
@c(hci_read_current_iac_lap)
public func hci_read_current_iac_lap(_ dd: Int32, _ numIAC: UnsafeMutablePointer<UInt8>?, _ lap: UnsafeMutablePointer<UInt8>?, _ timeout: Int32) -> Int32 {
    guard var response = hciRequest(
        dd, ogf: Int32(OGF_HOST_CTL), ocf: Int32(OCF_READ_CURRENT_IAC_LAP),
        response: read_current_iac_lap_rp.self, timeout: timeout
    ) else { return -1 }
    guard let numIAC else { errno = EINVAL; return -1 }
    numIAC.pointee = response.num_current_iac
    if let lap {
        withUnsafeMutableBytes(of: &response.lap) { lap.update(from: $0.bindMemory(to: UInt8.self).baseAddress!, count: Int(response.num_current_iac) * 3) }
    }
    return 0
}

/// `int hci_write_current_iac_lap(int dd, uint8_t num_iac, uint8_t *lap, int to)`
@c(hci_write_current_iac_lap)
public func hci_write_current_iac_lap(_ dd: Int32, _ numIAC: UInt8, _ lap: UnsafePointer<UInt8>?, _ timeout: Int32) -> Int32 {
    guard let lap else { errno = EINVAL; return -1 }
    var command = write_current_iac_lap_cp()
    command.num_current_iac = numIAC
    withUnsafeMutableBytes(of: &command.lap) { $0.copyMemory(from: UnsafeRawBufferPointer(start: lap, count: Int(numIAC) * 3)) }
    return hciCommand(
        dd, ogf: Int32(OGF_HOST_CTL), ocf: Int32(OCF_WRITE_CURRENT_IAC_LAP),
        commandBytes: withUnsafeBytes(of: &command) { Array($0.prefix(Int(numIAC) * 3 + 1)) }, timeout: timeout
    )
}

// MARK: - Stored link keys

/// `int hci_read_stored_link_key(int dd, bdaddr_t *bdaddr, uint8_t all, int to)`
@c(hci_read_stored_link_key)
public func hci_read_stored_link_key(_ dd: Int32, _ bdaddr: UnsafeMutablePointer<bdaddr_t>?, _ all: UInt8, _ timeout: Int32) -> Int32 {
    guard let bdaddr else { errno = EINVAL; return -1 }
    var command = read_stored_link_key_cp()
    command.bdaddr = bdaddr.pointee
    command.read_all = all
    return hciCommand(dd, ogf: Int32(OGF_HOST_CTL), ocf: Int32(OCF_READ_STORED_LINK_KEY), command: command, timeout: timeout)
}

/// `int hci_write_stored_link_key(int dd, bdaddr_t *bdaddr, uint8_t *key, int to)`
@c(hci_write_stored_link_key)
public func hci_write_stored_link_key(_ dd: Int32, _ bdaddr: UnsafeMutablePointer<bdaddr_t>?, _ key: UnsafeMutablePointer<UInt8>?, _ timeout: Int32) -> Int32 {
    guard let bdaddr, let key else { errno = EINVAL; return -1 }
    var bytes = [UInt8](repeating: 0, count: 1 + 6 + 16)
    bytes[0] = 1
    let address = bdaddr.pointee.b
    bytes[1] = address.0
    bytes[2] = address.1
    bytes[3] = address.2
    bytes[4] = address.3
    bytes[5] = address.4
    bytes[6] = address.5
    for index in 0 ..< 16 { bytes[7 + index] = key[index] }
    return hciCommand(dd, ogf: Int32(OGF_HOST_CTL), ocf: Int32(OCF_WRITE_STORED_LINK_KEY), commandBytes: bytes, timeout: timeout)
}

/// `int hci_delete_stored_link_key(int dd, bdaddr_t *bdaddr, uint8_t all, int to)`
@c(hci_delete_stored_link_key)
public func hci_delete_stored_link_key(_ dd: Int32, _ bdaddr: UnsafeMutablePointer<bdaddr_t>?, _ all: UInt8, _ timeout: Int32) -> Int32 {
    guard let bdaddr else { errno = EINVAL; return -1 }
    var command = delete_stored_link_key_cp()
    command.bdaddr = bdaddr.pointee
    command.delete_all = all
    return hciCommand(dd, ogf: Int32(OGF_HOST_CTL), ocf: Int32(OCF_DELETE_STORED_LINK_KEY), command: command, timeout: timeout)
}

// MARK: - Inquiry scan type

/// `int hci_read_inquiry_scan_type(int dd, uint8_t *type, int to)`
@c(hci_read_inquiry_scan_type)
public func hci_read_inquiry_scan_type(_ dd: Int32, _ type: UnsafeMutablePointer<UInt8>?, _ timeout: Int32) -> Int32 {
    guard let response = hciRequest(
        dd, ogf: Int32(OGF_HOST_CTL), ocf: Int32(OCF_READ_INQUIRY_SCAN_TYPE),
        response: read_inquiry_scan_type_rp.self, timeout: timeout
    ) else { return -1 }
    type?.pointee = response.type
    return 0
}

/// `int hci_write_inquiry_scan_type(int dd, uint8_t type, int to)`
@c(hci_write_inquiry_scan_type)
public func hci_write_inquiry_scan_type(_ dd: Int32, _ type: UInt8, _ timeout: Int32) -> Int32 {
    var command = write_inquiry_scan_type_cp()
    command.type = type
    guard hciRequest(
        dd, ogf: Int32(OGF_HOST_CTL), ocf: Int32(OCF_WRITE_INQUIRY_SCAN_TYPE),
        command: command, response: write_inquiry_scan_type_rp.self, timeout: timeout
    ) != nil else { return -1 }
    return 0
}

// MARK: - Inquiry mode

/// `int hci_read_inquiry_mode(int dd, uint8_t *mode, int to)`
@c(hci_read_inquiry_mode)
public func hci_read_inquiry_mode(_ dd: Int32, _ mode: UnsafeMutablePointer<UInt8>?, _ timeout: Int32) -> Int32 {
    guard let response = hciRequest(
        dd, ogf: Int32(OGF_HOST_CTL), ocf: Int32(OCF_READ_INQUIRY_MODE),
        response: read_inquiry_mode_rp.self, timeout: timeout
    ) else { return -1 }
    mode?.pointee = response.mode
    return 0
}

/// `int hci_write_inquiry_mode(int dd, uint8_t mode, int to)`
@c(hci_write_inquiry_mode)
public func hci_write_inquiry_mode(_ dd: Int32, _ mode: UInt8, _ timeout: Int32) -> Int32 {
    var command = write_inquiry_mode_cp()
    command.mode = mode
    guard hciRequest(
        dd, ogf: Int32(OGF_HOST_CTL), ocf: Int32(OCF_WRITE_INQUIRY_MODE),
        command: command, response: write_inquiry_mode_rp.self, timeout: timeout
    ) != nil else { return -1 }
    return 0
}

// MARK: - AFH mode

/// `int hci_read_afh_mode(int dd, uint8_t *mode, int to)`
@c(hci_read_afh_mode)
public func hci_read_afh_mode(_ dd: Int32, _ mode: UnsafeMutablePointer<UInt8>?, _ timeout: Int32) -> Int32 {
    guard let response = hciRequest(
        dd, ogf: Int32(OGF_HOST_CTL), ocf: Int32(OCF_READ_AFH_MODE),
        response: read_afh_mode_rp.self, timeout: timeout
    ) else { return -1 }
    mode?.pointee = response.mode
    return 0
}

/// `int hci_write_afh_mode(int dd, uint8_t mode, int to)`
@c(hci_write_afh_mode)
public func hci_write_afh_mode(_ dd: Int32, _ mode: UInt8, _ timeout: Int32) -> Int32 {
    var command = write_afh_mode_cp()
    command.mode = mode
    guard hciRequest(
        dd, ogf: Int32(OGF_HOST_CTL), ocf: Int32(OCF_WRITE_AFH_MODE),
        command: command, response: write_afh_mode_rp.self, timeout: timeout
    ) != nil else { return -1 }
    return 0
}

// MARK: - Extended inquiry response

/// `int hci_read_ext_inquiry_response(int dd, uint8_t *fec, uint8_t *data, int to)`
@c(hci_read_ext_inquiry_response)
public func hci_read_ext_inquiry_response(_ dd: Int32, _ fec: UnsafeMutablePointer<UInt8>?, _ data: UnsafeMutablePointer<UInt8>?, _ timeout: Int32) -> Int32 {
    guard var response = hciRequest(
        dd, ogf: Int32(OGF_HOST_CTL), ocf: Int32(OCF_READ_EXT_INQUIRY_RESPONSE),
        response: read_ext_inquiry_response_rp.self, timeout: timeout
    ) else { return -1 }
    guard let fec, let data else { errno = EINVAL; return -1 }
    fec.pointee = response.fec
    withUnsafeMutableBytes(of: &response.data) { data.update(from: $0.bindMemory(to: UInt8.self).baseAddress!, count: Int(HCI_MAX_EIR_LENGTH)) }
    return 0
}

/// `int hci_write_ext_inquiry_response(int dd, uint8_t fec, uint8_t *data, int to)`
@c(hci_write_ext_inquiry_response)
public func hci_write_ext_inquiry_response(_ dd: Int32, _ fec: UInt8, _ data: UnsafeMutablePointer<UInt8>?, _ timeout: Int32) -> Int32 {
    guard let data else { errno = EINVAL; return -1 }
    var command = write_ext_inquiry_response_cp()
    command.fec = fec
    withUnsafeMutableBytes(of: &command.data) { $0.copyMemory(from: UnsafeRawBufferPointer(start: data, count: Int(HCI_MAX_EIR_LENGTH))) }
    guard hciRequest(
        dd, ogf: Int32(OGF_HOST_CTL), ocf: Int32(OCF_WRITE_EXT_INQUIRY_RESPONSE),
        command: command, response: write_ext_inquiry_response_rp.self, timeout: timeout
    ) != nil else { return -1 }
    return 0
}

// MARK: - Simple pairing mode

/// `int hci_read_simple_pairing_mode(int dd, uint8_t *mode, int to)`
@c(hci_read_simple_pairing_mode)
public func hci_read_simple_pairing_mode(_ dd: Int32, _ mode: UnsafeMutablePointer<UInt8>?, _ timeout: Int32) -> Int32 {
    guard let response = hciRequest(
        dd, ogf: Int32(OGF_HOST_CTL), ocf: Int32(OCF_READ_SIMPLE_PAIRING_MODE),
        response: read_simple_pairing_mode_rp.self, timeout: timeout
    ) else { return -1 }
    mode?.pointee = response.mode
    return 0
}

/// `int hci_write_simple_pairing_mode(int dd, uint8_t mode, int to)`
@c(hci_write_simple_pairing_mode)
public func hci_write_simple_pairing_mode(_ dd: Int32, _ mode: UInt8, _ timeout: Int32) -> Int32 {
    var command = write_simple_pairing_mode_cp()
    command.mode = mode
    guard hciRequest(
        dd, ogf: Int32(OGF_HOST_CTL), ocf: Int32(OCF_WRITE_SIMPLE_PAIRING_MODE),
        command: command, response: write_simple_pairing_mode_rp.self, timeout: timeout
    ) != nil else { return -1 }
    return 0
}

// MARK: - Out-of-band data

/// `int hci_read_local_oob_data(int dd, uint8_t *hash, uint8_t *randomizer, int to)`
@c(hci_read_local_oob_data)
public func hci_read_local_oob_data(_ dd: Int32, _ hash: UnsafeMutablePointer<UInt8>?, _ randomizer: UnsafeMutablePointer<UInt8>?, _ timeout: Int32) -> Int32 {
    guard var response = hciRequest(
        dd, ogf: Int32(OGF_HOST_CTL), ocf: Int32(OCF_READ_LOCAL_OOB_DATA),
        response: read_local_oob_data_rp.self, timeout: timeout
    ) else { return -1 }
    guard let hash, let randomizer else { errno = EINVAL; return -1 }
    withUnsafeMutableBytes(of: &response.hash) { hash.update(from: $0.bindMemory(to: UInt8.self).baseAddress!, count: 16) }
    withUnsafeMutableBytes(of: &response.randomizer) { randomizer.update(from: $0.bindMemory(to: UInt8.self).baseAddress!, count: 16) }
    return 0
}

// MARK: - Transmit power

/// `int hci_read_inq_response_tx_power_level(int dd, int8_t *level, int to)`
@c(hci_read_inq_response_tx_power_level)
public func hci_read_inq_response_tx_power_level(_ dd: Int32, _ level: UnsafeMutablePointer<Int8>?, _ timeout: Int32) -> Int32 {
    guard let response = hciRequest(
        dd, ogf: Int32(OGF_HOST_CTL), ocf: Int32(OCF_READ_INQ_RESPONSE_TX_POWER_LEVEL),
        response: read_inq_response_tx_power_level_rp.self, timeout: timeout
    ) else { return -1 }
    level?.pointee = response.level
    return 0
}

/// `int hci_read_inquiry_transmit_power_level(int dd, int8_t *level, int to)`
@c(hci_read_inquiry_transmit_power_level)
public func hci_read_inquiry_transmit_power_level(_ dd: Int32, _ level: UnsafeMutablePointer<Int8>?, _ timeout: Int32) -> Int32 {
    hci_read_inq_response_tx_power_level(dd, level, timeout)
}

/// `int hci_write_inquiry_transmit_power_level(int dd, int8_t level, int to)`
@c(hci_write_inquiry_transmit_power_level)
public func hci_write_inquiry_transmit_power_level(_ dd: Int32, _ level: Int8, _ timeout: Int32) -> Int32 {
    var command = write_inquiry_transmit_power_level_cp()
    command.level = level
    guard hciRequest(
        dd, ogf: Int32(OGF_HOST_CTL), ocf: Int32(OCF_WRITE_INQUIRY_TRANSMIT_POWER_LEVEL),
        command: command, response: write_inquiry_transmit_power_level_rp.self, timeout: timeout
    ) != nil else { return -1 }
    return 0
}

/// `int hci_read_transmit_power_level(int dd, uint16_t handle, uint8_t type, int8_t *level, int to)`
@c(hci_read_transmit_power_level)
public func hci_read_transmit_power_level(_ dd: Int32, _ handle: UInt16, _ type: UInt8, _ level: UnsafeMutablePointer<Int8>?, _ timeout: Int32) -> Int32 {
    var command = read_transmit_power_level_cp()
    command.handle = handle
    command.type = type
    guard let response = hciRequest(
        dd, ogf: Int32(OGF_HOST_CTL), ocf: Int32(OCF_READ_TRANSMIT_POWER_LEVEL),
        command: command, response: read_transmit_power_level_rp.self, timeout: timeout
    ) else { return -1 }
    level?.pointee = response.level
    return 0
}

// MARK: - Link policy / supervision timeout

/// `int hci_read_link_policy(int dd, uint16_t handle, uint16_t *policy, int to)`
@c(hci_read_link_policy)
public func hci_read_link_policy(_ dd: Int32, _ handle: UInt16, _ policy: UnsafeMutablePointer<UInt16>?, _ timeout: Int32) -> Int32 {
    guard let response = hciRequest(
        dd, ogf: Int32(OGF_LINK_POLICY), ocf: Int32(OCF_READ_LINK_POLICY),
        command: handle, response: read_link_policy_rp.self, timeout: timeout
    ) else { return -1 }
    policy?.pointee = response.policy
    return 0
}

/// `int hci_write_link_policy(int dd, uint16_t handle, uint16_t policy, int to)`
@c(hci_write_link_policy)
public func hci_write_link_policy(_ dd: Int32, _ handle: UInt16, _ policy: UInt16, _ timeout: Int32) -> Int32 {
    var command = write_link_policy_cp()
    command.handle = handle
    command.policy = policy
    guard hciRequest(
        dd, ogf: Int32(OGF_LINK_POLICY), ocf: Int32(OCF_WRITE_LINK_POLICY),
        command: command, response: write_link_policy_rp.self, timeout: timeout
    ) != nil else { return -1 }
    return 0
}

/// `int hci_read_link_supervision_timeout(int dd, uint16_t handle, uint16_t *timeout, int to)`
@c(hci_read_link_supervision_timeout)
public func hci_read_link_supervision_timeout(_ dd: Int32, _ handle: UInt16, _ linkTimeout: UnsafeMutablePointer<UInt16>?, _ timeout: Int32) -> Int32 {
    guard let response = hciRequest(
        dd, ogf: Int32(OGF_HOST_CTL), ocf: Int32(OCF_READ_LINK_SUPERVISION_TIMEOUT),
        command: handle, response: read_link_supervision_timeout_rp.self, timeout: timeout
    ) else { return -1 }
    linkTimeout?.pointee = response.timeout
    return 0
}

/// `int hci_write_link_supervision_timeout(int dd, uint16_t handle, uint16_t timeout, int to)`
@c(hci_write_link_supervision_timeout)
public func hci_write_link_supervision_timeout(_ dd: Int32, _ handle: UInt16, _ linkTimeout: UInt16, _ timeout: Int32) -> Int32 {
    var command = write_link_supervision_timeout_cp()
    command.handle = handle
    command.timeout = linkTimeout
    guard hciRequest(
        dd, ogf: Int32(OGF_HOST_CTL), ocf: Int32(OCF_WRITE_LINK_SUPERVISION_TIMEOUT),
        command: command, response: write_link_supervision_timeout_rp.self, timeout: timeout
    ) != nil else { return -1 }
    return 0
}

// MARK: - AFH classification

/// `int hci_set_afh_classification(int dd, uint8_t *map, int to)`
@c(hci_set_afh_classification)
public func hci_set_afh_classification(_ dd: Int32, _ map: UnsafeMutablePointer<UInt8>?, _ timeout: Int32) -> Int32 {
    guard let map else { errno = EINVAL; return -1 }
    var command = set_afh_classification_cp()
    withUnsafeMutableBytes(of: &command.map) { $0.copyMemory(from: UnsafeRawBufferPointer(start: map, count: 10)) }
    guard hciRequest(
        dd, ogf: Int32(OGF_HOST_CTL), ocf: Int32(OCF_SET_AFH_CLASSIFICATION),
        command: command, response: set_afh_classification_rp.self, timeout: timeout
    ) != nil else { return -1 }
    return 0
}

// MARK: - Status parameters (link quality / RSSI / AFH map / clock)

/// `int hci_read_link_quality(int dd, uint16_t handle, uint8_t *link_quality, int to)`
@c(hci_read_link_quality)
public func hci_read_link_quality(_ dd: Int32, _ handle: UInt16, _ linkQuality: UnsafeMutablePointer<UInt8>?, _ timeout: Int32) -> Int32 {
    guard let response = hciRequest(
        dd, ogf: Int32(OGF_STATUS_PARAM), ocf: Int32(OCF_READ_LINK_QUALITY),
        command: handle, response: read_link_quality_rp.self, timeout: timeout
    ) else { return -1 }
    linkQuality?.pointee = response.link_quality
    return 0
}

/// `int hci_read_rssi(int dd, uint16_t handle, int8_t *rssi, int to)`
@c(hci_read_rssi)
public func hci_read_rssi(_ dd: Int32, _ handle: UInt16, _ rssi: UnsafeMutablePointer<Int8>?, _ timeout: Int32) -> Int32 {
    guard let response = hciRequest(
        dd, ogf: Int32(OGF_STATUS_PARAM), ocf: Int32(OCF_READ_RSSI),
        command: handle, response: read_rssi_rp.self, timeout: timeout
    ) else { return -1 }
    rssi?.pointee = response.rssi
    return 0
}

/// `int hci_read_afh_map(int dd, uint16_t handle, uint8_t *mode, uint8_t *map, int to)`
@c(hci_read_afh_map)
public func hci_read_afh_map(_ dd: Int32, _ handle: UInt16, _ mode: UnsafeMutablePointer<UInt8>?, _ map: UnsafeMutablePointer<UInt8>?, _ timeout: Int32) -> Int32 {
    guard var response = hciRequest(
        dd, ogf: Int32(OGF_STATUS_PARAM), ocf: Int32(OCF_READ_AFH_MAP),
        command: handle, response: read_afh_map_rp.self, timeout: timeout
    ) else { return -1 }
    guard let mode, let map else { errno = EINVAL; return -1 }
    mode.pointee = response.mode
    withUnsafeMutableBytes(of: &response.map) { map.update(from: $0.bindMemory(to: UInt8.self).baseAddress!, count: 10) }
    return 0
}

/// `int hci_read_clock(int dd, uint16_t handle, uint8_t which, uint32_t *clock, uint16_t *accuracy, int to)`
@c(hci_read_clock)
public func hci_read_clock(
    _ dd: Int32,
    _ handle: UInt16,
    _ which: UInt8,
    _ clock: UnsafeMutablePointer<UInt32>?,
    _ accuracy: UnsafeMutablePointer<UInt16>?,
    _ timeout: Int32
) -> Int32 {
    var command = read_clock_cp()
    command.handle = handle
    command.which_clock = which
    guard let response = hciRequest(
        dd, ogf: Int32(OGF_STATUS_PARAM), ocf: Int32(OCF_READ_CLOCK),
        command: command, response: read_clock_rp.self, timeout: timeout
    ) else { return -1 }
    clock?.pointee = response.clock
    accuracy?.pointee = response.accuracy
    return 0
}
