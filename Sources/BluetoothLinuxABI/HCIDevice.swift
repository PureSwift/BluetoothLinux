//
//  HCIDevice.swift
//  BluetoothLinux
//
//  Swift implementations of the HCI device management family: opening
//  and closing a raw HCI socket, looking up device info/address/id,
//  enumerating devices, routing, and sending raw commands/requests.
//
//  These talk to the kernel directly via AF_BLUETOOTH/BTPROTO_HCI raw
//  sockets and the HCIGETDEVINFO/HCIGETDEVLIST ioctls, mirroring
//  lib/hci.c exactly, rather than routing through BluetoothLinux's own
//  (async, higher-level) HostController/Socket infrastructure — the
//  ABI surface has to be synchronous and match the reference's wire
//  layout precisely, which a bridge into the async engine would not
//  make any simpler.
//
//  hci_send_cmd/hci_send_req have not been exercised against a live
//  or virtual HCI device (no differential conformance harness for
//  this family yet); they're a direct, careful translation of
//  lib/hci.c's hci_send_cmd/hci_send_req.
//

import CBluetoothLinuxABI
import Glibc

// MARK: - Opcode packing (cmd_opcode_pack is a function-like macro, not imported)

private func hciOpcode(ogf: UInt16, ocf: UInt16) -> UInt16 {
    (ocf & 0x03ff) | (ogf << 10)
}

// MARK: - ioctl request codes (_IOR('H', nr, int) macros; not imported —
// ClangImporter can't evaluate function-like macros that use sizeof).
// Values confirmed against the vendored header with a small C program.

private let hciGetDeviceList: UInt = 0x800448d2
private let hciGetDeviceInfo: UInt = 0x800448d3

// MARK: - atoi-equivalent (BlueZ's hci_devid uses atoi(str + 3))

private func atoiPrefix(_ string: Substring) -> Int32 {
    var characters = string
    while let first = characters.first, first == " " || first == "\t" || first == "\n" {
        characters.removeFirst()
    }
    var sign: Int32 = 1
    if let first = characters.first, first == "+" || first == "-" {
        if first == "-" { sign = -1 }
        characters.removeFirst()
    }
    var value: Int32 = 0
    while let first = characters.first, let digit = first.wholeNumberValue, first.isASCII, digit <= 9 {
        value = value &* 10 &+ Int32(digit)
        characters.removeFirst()
    }
    return sign &* value
}

// MARK: - Open / close

/// `int hci_open_dev(int dev_id)`
@c(hci_open_dev)
public func hci_open_dev(_ devID: Int32) -> Int32 {
    guard devID >= 0 else {
        errno = ENODEV
        return -1
    }
    let dd = socket(Int32(AF_BLUETOOTH), Int32(SOCK_RAW.rawValue) | Int32(SOCK_CLOEXEC.rawValue), Int32(BTPROTO_HCI))
    guard dd >= 0 else { return dd }

    var address = sockaddr_hci(hci_family: sa_family_t(AF_BLUETOOTH), hci_dev: UInt16(devID), hci_channel: 0)
    let result = withUnsafeMutablePointer(to: &address) { pointer -> Int32 in
        pointer.withMemoryRebound(to: sockaddr.self, capacity: 1) { sockaddrPointer in
            bind(dd, sockaddrPointer, socklen_t(MemoryLayout<sockaddr_hci>.size))
        }
    }
    guard result >= 0 else {
        let savedError = errno
        close(dd)
        errno = savedError
        return -1
    }
    return dd
}

/// `int hci_close_dev(int dd)`
@c(hci_close_dev)
public func hci_close_dev(_ dd: Int32) -> Int32 {
    close(dd)
}

// MARK: - Device info / address / id

/// `int hci_devinfo(int dev_id, struct hci_dev_info *di)`
@c(hci_devinfo)
public func hci_devinfo(_ devID: Int32, _ info: UnsafeMutablePointer<hci_dev_info>?) -> Int32 {
    guard let info else { return -1 }
    let dd = socket(Int32(AF_BLUETOOTH), Int32(SOCK_RAW.rawValue) | Int32(SOCK_CLOEXEC.rawValue), Int32(BTPROTO_HCI))
    guard dd >= 0 else { return dd }

    memset(info, 0, MemoryLayout<hci_dev_info>.size)
    info.pointee.dev_id = UInt16(devID)
    let result = ioctl(dd, numericCast(hciGetDeviceInfo), info)

    let savedError = errno
    close(dd)
    errno = savedError
    return result
}

/// `int hci_devba(int dev_id, bdaddr_t *bdaddr)`
@c(hci_devba)
public func hci_devba(_ devID: Int32, _ bdaddr: UnsafeMutablePointer<bdaddr_t>?) -> Int32 {
    var info = hci_dev_info()
    guard hci_devinfo(devID, &info) >= 0 else { return -1 }
    guard hci_test_bit(Int32(HCI_UP), &info.flags) != 0 else {
        errno = ENETDOWN
        return -1
    }
    bdaddr?.pointee = info.bdaddr
    return 0
}

/// `int hci_devid(const char *str)`
@c(hci_devid)
public func hci_devid(_ str: UnsafePointer<CChar>?) -> Int32 {
    guard let str else { return -1 }
    let string = String(cString: str)
    var id: Int32 = -1
    if string.hasPrefix("hci"), string.utf8.count >= 4 {
        id = atoiPrefix(string.dropFirst(3))
        var address = bdaddr_t(b: (0, 0, 0, 0, 0, 0))
        guard hci_devba(id, &address) >= 0 else { return -1 }
    } else {
        errno = ENODEV
        var address = bdaddr_t(b: (0, 0, 0, 0, 0, 0))
        str2ba(str, &address)
        id = withUnsafeMutablePointer(to: &address) {
            hci_for_each_dev(Int32(HCI_UP), sameBDAddress, Int(bitPattern: $0))
        }
    }
    return id
}

// MARK: - Enumeration / routing

private func sameBDAddress(_ dd: Int32, _ devID: Int32, _ arg: Int) -> Int32 {
    var info = hci_dev_info()
    info.dev_id = UInt16(devID)
    guard ioctl(dd, numericCast(hciGetDeviceInfo), &info) == 0 else { return 0 }
    guard let target = UnsafeRawPointer(bitPattern: arg)?.assumingMemoryBound(to: bdaddr_t.self) else { return 0 }
    return bacmp(target, &info.bdaddr) == 0 ? 1 : 0
}

private func otherBDAddress(_ dd: Int32, _ devID: Int32, _ arg: Int) -> Int32 {
    var info = hci_dev_info()
    info.dev_id = UInt16(devID)
    guard ioctl(dd, numericCast(hciGetDeviceInfo), &info) == 0 else { return 0 }
    guard hci_test_bit(Int32(HCI_RAW), &info.flags) == 0 else { return 0 }
    guard let target = UnsafeRawPointer(bitPattern: arg)?.assumingMemoryBound(to: bdaddr_t.self) else { return 0 }
    return Int32(bacmp(target, &info.bdaddr))
}

/// `int hci_for_each_dev(int flag, int(*func)(int dd, int dev_id, long arg), long arg)`
@c(hci_for_each_dev)
public func hci_for_each_dev(
    _ flag: Int32,
    _ callback: (@convention(c) (Int32, Int32, Int) -> Int32)?,
    _ arg: Int
) -> Int32 {
    let sk = socket(Int32(AF_BLUETOOTH), Int32(SOCK_RAW.rawValue) | Int32(SOCK_CLOEXEC.rawValue), Int32(BTPROTO_HCI))
    guard sk >= 0 else { return -1 }

    let maxDevices = Int(HCI_MAX_DEV)
    let headerSize = MemoryLayout<hci_dev_list_req>.size
    let entrySize = MemoryLayout<hci_dev_req>.size
    let byteCount = headerSize + maxDevices * entrySize
    let buffer = UnsafeMutableRawPointer.allocate(
        byteCount: byteCount,
        alignment: MemoryLayout<hci_dev_list_req>.alignment
    )
    defer { buffer.deallocate() }
    buffer.initializeMemory(as: UInt8.self, repeating: 0, count: byteCount)

    let listRequest = buffer.assumingMemoryBound(to: hci_dev_list_req.self)
    listRequest.pointee.dev_num = UInt16(maxDevices)

    var deviceID: Int32 = -1
    var savedError: Int32 = 0

    if ioctl(sk, numericCast(hciGetDeviceList), buffer) < 0 {
        savedError = errno
    } else {
        let deviceRequests = buffer.advanced(by: headerSize).assumingMemoryBound(to: hci_dev_req.self)
        let count = Int(listRequest.pointee.dev_num)
        for i in 0 ..< count {
            var options = deviceRequests[i].dev_opt
            guard hci_test_bit(flag, &options) != 0 else { continue }
            let id = Int32(deviceRequests[i].dev_id)
            if callback == nil || callback!(sk, id, arg) != 0 {
                deviceID = id
                break
            }
        }
        if deviceID < 0 {
            savedError = Int32(ENODEV)
        }
    }

    close(sk)
    errno = savedError
    return deviceID
}

/// `int hci_get_route(bdaddr_t *bdaddr)`
@c(hci_get_route)
public func hci_get_route(_ bdaddr: UnsafeMutablePointer<bdaddr_t>?) -> Int32 {
    func route(with target: UnsafeMutablePointer<bdaddr_t>) -> Int32 {
        let arg = Int(bitPattern: target)
        var deviceID = hci_for_each_dev(Int32(HCI_UP), otherBDAddress, arg)
        if deviceID < 0 {
            deviceID = hci_for_each_dev(Int32(HCI_UP), sameBDAddress, arg)
        }
        return deviceID
    }
    if let bdaddr {
        return route(with: bdaddr)
    }
    var any = bdaddr_t(b: (0, 0, 0, 0, 0, 0))
    return withUnsafeMutablePointer(to: &any) { route(with: $0) }
}

// MARK: - Sending commands / requests

/// `int hci_send_cmd(int dd, uint16_t ogf, uint16_t ocf, uint8_t plen, void *param)`
@c(hci_send_cmd)
public func hci_send_cmd(_ dd: Int32, _ ogf: UInt16, _ ocf: UInt16, _ plen: UInt8, _ param: UnsafeMutableRawPointer?) -> Int32 {
    var packetType = UInt8(HCI_COMMAND_PKT)
    var header = hci_command_hdr(opcode: hciOpcode(ogf: ogf, ocf: ocf), plen: plen)

    return withUnsafeMutableBytes(of: &packetType) { typeBuffer -> Int32 in
        withUnsafeMutableBytes(of: &header) { headerBuffer -> Int32 in
            var vectors = [
                iovec(iov_base: typeBuffer.baseAddress, iov_len: 1),
                iovec(iov_base: headerBuffer.baseAddress, iov_len: headerBuffer.count)
            ]
            if plen > 0 {
                vectors.append(iovec(iov_base: param, iov_len: Int(plen)))
            }
            while true {
                let written = writev(dd, &vectors, Int32(vectors.count))
                if written < 0 {
                    if errno == EAGAIN || errno == EINTR { continue }
                    return -1
                }
                return 0
            }
        }
    }
}

/// `int hci_send_req(int dd, struct hci_request *req, int timeout)`
@c(hci_send_req)
public func hci_send_req(_ dd: Int32, _ request: UnsafeMutablePointer<hci_request>?, _ timeout: Int32) -> Int32 {
    guard let request else {
        errno = EINVAL
        return -1
    }
    let opcode = hciOpcode(ogf: request.pointee.ogf, ocf: request.pointee.ocf)

    var oldFilter = hci_filter()
    var oldFilterLength = socklen_t(MemoryLayout<hci_filter>.size)
    guard getsockopt(dd, Int32(SOL_HCI), Int32(HCI_FILTER), &oldFilter, &oldFilterLength) >= 0 else {
        return -1
    }

    var newFilter = hci_filter()
    hci_filter_clear(&newFilter)
    hci_filter_set_ptype(Int32(HCI_EVENT_PKT), &newFilter)
    hci_filter_set_event(Int32(EVT_CMD_STATUS), &newFilter)
    hci_filter_set_event(Int32(EVT_CMD_COMPLETE), &newFilter)
    hci_filter_set_event(Int32(EVT_LE_META_EVENT), &newFilter)
    hci_filter_set_event(request.pointee.event, &newFilter)
    hci_filter_set_opcode(Int32(opcode), &newFilter)
    guard setsockopt(dd, Int32(SOL_HCI), Int32(HCI_FILTER), &newFilter, socklen_t(MemoryLayout<hci_filter>.size)) >= 0 else {
        return -1
    }

    func restoreFilterAndFail() -> Int32 {
        let savedError = errno
        var restore = oldFilter
        var finalError = savedError
        if setsockopt(dd, Int32(SOL_HCI), Int32(HCI_FILTER), &restore, socklen_t(MemoryLayout<hci_filter>.size)) < 0 {
            finalError = errno
        }
        errno = finalError
        return -1
    }

    func restoreFilterAndSucceed() -> Int32 {
        var restore = oldFilter
        guard setsockopt(dd, Int32(SOL_HCI), Int32(HCI_FILTER), &restore, socklen_t(MemoryLayout<hci_filter>.size)) >= 0 else {
            return -1
        }
        return 0
    }

    guard hci_send_cmd(
        dd,
        request.pointee.ogf,
        request.pointee.ocf,
        UInt8(truncatingIfNeeded: request.pointee.clen),
        request.pointee.cparam
    ) >= 0 else {
        return restoreFilterAndFail()
    }

    var buffer = [UInt8](repeating: 0, count: Int(HCI_MAX_EVENT_SIZE))
    var remainingTimeout = timeout
    var attempts = 10

    while attempts > 0 {
        attempts -= 1

        if remainingTimeout != 0 {
            var pfd = pollfd(fd: dd, events: Int16(POLLIN), revents: 0)
            var pollResult: Int32
            repeat {
                pollResult = poll(&pfd, 1, remainingTimeout)
            } while pollResult < 0 && (errno == EAGAIN || errno == EINTR)

            if pollResult < 0 {
                return restoreFilterAndFail()
            }
            if pollResult == 0 {
                errno = ETIMEDOUT
                return restoreFilterAndFail()
            }

            remainingTimeout -= 10
            if remainingTimeout < 0 { remainingTimeout = 0 }
        }

        var bytesRead: Int
        repeat {
            bytesRead = buffer.withUnsafeMutableBytes { read(dd, $0.baseAddress, $0.count) }
        } while bytesRead < 0 && (errno == EAGAIN || errno == EINTR)

        if bytesRead < 0 {
            return restoreFilterAndFail()
        }

        let dataOffset = 1 + Int(HCI_EVENT_HDR_SIZE)
        guard bytesRead >= dataOffset else { continue }

        let eventCode = Int32(buffer[1])
        let length = bytesRead - dataOffset

        switch eventCode {
        case Int32(EVT_CMD_STATUS):
            guard length >= MemoryLayout<evt_cmd_status>.size else { continue }
            let status: evt_cmd_status = buffer.withUnsafeBytes { $0.loadUnaligned(fromByteOffset: dataOffset, as: evt_cmd_status.self) }
            guard status.opcode == opcode else { continue }
            if request.pointee.event != Int32(EVT_CMD_STATUS) {
                if status.status != 0 {
                    errno = EIO
                    return restoreFilterAndFail()
                }
            } else {
                let resultLength = min(length, Int(request.pointee.rlen))
                request.pointee.rlen = Int32(resultLength)
                if let rparam = request.pointee.rparam {
                    _ = buffer.withUnsafeBytes { memcpy(rparam, $0.baseAddress!.advanced(by: dataOffset), resultLength) }
                }
                return restoreFilterAndSucceed()
            }

        case Int32(EVT_CMD_COMPLETE):
            guard length >= MemoryLayout<evt_cmd_complete>.size else { continue }
            let complete: evt_cmd_complete = buffer.withUnsafeBytes { $0.loadUnaligned(fromByteOffset: dataOffset, as: evt_cmd_complete.self) }
            guard complete.opcode == opcode else { continue }
            let paramOffset = dataOffset + Int(EVT_CMD_COMPLETE_SIZE)
            let paramLength = length - Int(EVT_CMD_COMPLETE_SIZE)
            let resultLength = min(paramLength, Int(request.pointee.rlen))
            request.pointee.rlen = Int32(resultLength)
            if let rparam = request.pointee.rparam, resultLength > 0 {
                _ = buffer.withUnsafeBytes { memcpy(rparam, $0.baseAddress!.advanced(by: paramOffset), resultLength) }
            }
            return restoreFilterAndSucceed()

        case Int32(EVT_REMOTE_NAME_REQ_COMPLETE):
            guard eventCode == request.pointee.event else { break }
            guard length >= MemoryLayout<evt_remote_name_req_complete>.size else { continue }
            let addressOffset = dataOffset + 1
            var remoteAddress: bdaddr_t = buffer.withUnsafeBytes { $0.loadUnaligned(fromByteOffset: addressOffset, as: bdaddr_t.self) }
            if let cparam = request.pointee.cparam {
                var commandAddress = cparam.loadUnaligned(as: bdaddr_t.self)
                guard bacmp(&remoteAddress, &commandAddress) == 0 else { continue }
            }
            let resultLength = min(length, Int(request.pointee.rlen))
            request.pointee.rlen = Int32(resultLength)
            if let rparam = request.pointee.rparam {
                _ = buffer.withUnsafeBytes { memcpy(rparam, $0.baseAddress!.advanced(by: dataOffset), resultLength) }
            }
            return restoreFilterAndSucceed()

        case Int32(EVT_LE_META_EVENT):
            guard length >= 1 else { continue }
            let subevent = Int32(buffer[dataOffset])
            guard subevent == request.pointee.event else { continue }
            let metaLength = length - 1
            let resultLength = min(metaLength, Int(request.pointee.rlen))
            request.pointee.rlen = Int32(resultLength)
            if let rparam = request.pointee.rparam {
                _ = buffer.withUnsafeBytes { memcpy(rparam, $0.baseAddress!.advanced(by: dataOffset + 1), resultLength) }
            }
            return restoreFilterAndSucceed()

        default:
            guard eventCode == request.pointee.event else { break }
            let resultLength = min(length, Int(request.pointee.rlen))
            request.pointee.rlen = Int32(resultLength)
            if let rparam = request.pointee.rparam {
                _ = buffer.withUnsafeBytes { memcpy(rparam, $0.baseAddress!.advanced(by: dataOffset), resultLength) }
            }
            return restoreFilterAndSucceed()
        }
    }

    errno = ETIMEDOUT
    return restoreFilterAndFail()
}
