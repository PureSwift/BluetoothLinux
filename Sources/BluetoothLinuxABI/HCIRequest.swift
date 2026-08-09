//
//  HCIRequest.swift
//  BluetoothLinux
//
//  Shared plumbing for the HCI command wrapper family: every wrapper in
//  lib/hci.c follows one of a small number of shapes — build a command
//  struct, call hci_send_req, check a status byte, optionally copy
//  fields out of the response. These helpers capture those shapes once
//  so each wrapper function is a short, direct transcription of its
//  reference instead of repeating the send/check boilerplate.
//
//  None of this has been exercised against a real or virtual HCI
//  device; see HCIDevice.swift's note on hci_send_cmd/hci_send_req.
//

import CBluetoothLinuxABI
import Glibc

/// A response struct whose first field is the standard one-byte HCI
/// command status (0 = success). Nearly every `*_rp`/`evt_*` struct in
/// hci.h has this shape; conforming a type only asserts that its first
/// byte is the status, which the C struct layout already guarantees.
internal protocol HCIStatusResponse {
    init()
    var status: UInt8 { get }
}

/// Placeholder for commands that take no parameters.
internal struct HCIEmptyCommand {}

/// Sends `command` and returns `hci_send_req`'s raw result, with no
/// response payload (`rparam`/`rlen` left at zero) — mirrors the
/// wrappers that call `hci_send_req` directly and return its result
/// (or check nothing at all).
@discardableResult
internal func hciCommand<Command>(
    _ dd: Int32,
    ogf: Int32,
    ocf: Int32,
    event: Int32 = 0,
    command: Command,
    timeout: Int32
) -> Int32 {
    var command = command
    var request = hci_request()
    request.ogf = UInt16(ogf)
    request.ocf = UInt16(ocf)
    request.event = event
    request.clen = Int32(MemoryLayout<Command>.size)
    return withUnsafeMutableBytes(of: &command) { commandBuffer -> Int32 in
        request.cparam = MemoryLayout<Command>.size > 0 ? commandBuffer.baseAddress : nil
        return withUnsafeMutablePointer(to: &request) { hci_send_req(dd, $0, timeout) }
    }
}

@discardableResult
internal func hciCommand(_ dd: Int32, ogf: Int32, ocf: Int32, event: Int32 = 0, timeout: Int32) -> Int32 {
    hciCommand(dd, ogf: ogf, ocf: ocf, event: event, command: HCIEmptyCommand(), timeout: timeout)
}

/// Sends `commandBytes` verbatim as the command parameter — for the
/// handful of wrappers whose parameter is a hand-assembled, variable
/// length byte buffer rather than a fixed C struct.
@discardableResult
internal func hciCommand(_ dd: Int32, ogf: Int32, ocf: Int32, event: Int32 = 0, commandBytes: [UInt8], timeout: Int32) -> Int32 {
    var bytes = commandBytes
    var request = hci_request()
    request.ogf = UInt16(ogf)
    request.ocf = UInt16(ocf)
    request.event = event
    request.clen = Int32(bytes.count)
    return bytes.withUnsafeMutableBytes { buffer -> Int32 in
        request.cparam = buffer.baseAddress
        return withUnsafeMutablePointer(to: &request) { hci_send_req(dd, $0, timeout) }
    }
}

/// Sends `command` and reads back a single status byte — the pattern
/// used by every `hci_le_*` wrapper that doesn't decode a response
/// struct (BlueZ declares a bare `uint8_t status;` local for these
/// rather than a named `_rp` type).
internal func hciStatus<Command>(_ dd: Int32, ogf: Int32, ocf: Int32, command: Command, timeout: Int32) -> Int32 {
    var command = command
    var status: UInt8 = 0
    var request = hci_request()
    request.ogf = UInt16(ogf)
    request.ocf = UInt16(ocf)
    request.clen = Int32(MemoryLayout<Command>.size)
    request.rlen = 1
    let result: Int32 = withUnsafeMutableBytes(of: &command) { commandBuffer in
        withUnsafeMutableBytes(of: &status) { statusBuffer -> Int32 in
            request.cparam = MemoryLayout<Command>.size > 0 ? commandBuffer.baseAddress : nil
            request.rparam = statusBuffer.baseAddress
            return withUnsafeMutablePointer(to: &request) { hci_send_req(dd, $0, timeout) }
        }
    }
    guard result >= 0 else { return -1 }
    guard status == 0 else {
        errno = EIO
        return -1
    }
    return 0
}

internal func hciStatus(_ dd: Int32, ogf: Int32, ocf: Int32, timeout: Int32) -> Int32 {
    hciStatus(dd, ogf: ogf, ocf: ocf, command: HCIEmptyCommand(), timeout: timeout)
}

/// Sends `command`, decodes the response into `Response`, and checks
/// its `status` field. Returns `nil` (with `errno` set) on failure —
/// the shape used by nearly every `hci_read_*`/`hci_write_*` wrapper.
internal func hciRequest<Command, Response: HCIStatusResponse>(
    _ dd: Int32,
    ogf: Int32,
    ocf: Int32,
    event: Int32 = 0,
    command: Command,
    response: Response.Type,
    timeout: Int32
) -> Response? {
    var command = command
    var response = Response()
    var request = hci_request()
    request.ogf = UInt16(ogf)
    request.ocf = UInt16(ocf)
    request.event = event
    request.clen = Int32(MemoryLayout<Command>.size)
    request.rlen = Int32(MemoryLayout<Response>.size)
    let result: Int32 = withUnsafeMutableBytes(of: &command) { commandBuffer in
        withUnsafeMutableBytes(of: &response) { responseBuffer -> Int32 in
            request.cparam = MemoryLayout<Command>.size > 0 ? commandBuffer.baseAddress : nil
            request.rparam = responseBuffer.baseAddress
            return withUnsafeMutablePointer(to: &request) { hci_send_req(dd, $0, timeout) }
        }
    }
    guard result >= 0 else { return nil }
    guard response.status == 0 else {
        errno = EIO
        return nil
    }
    return response
}

internal func hciRequest<Response: HCIStatusResponse>(
    _ dd: Int32,
    ogf: Int32,
    ocf: Int32,
    event: Int32 = 0,
    response: Response.Type,
    timeout: Int32
) -> Response? {
    hciRequest(dd, ogf: ogf, ocf: ocf, event: event, command: HCIEmptyCommand(), response: response, timeout: timeout)
}
