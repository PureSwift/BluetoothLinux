//
//  HCIInquiry.swift
//  BluetoothLinux
//
//  hci_inquiry doesn't go through hci_send_req at all — it's a single
//  ioctl(HCIINQUIRY) call whose input (the inquiry parameters) and
//  output (the resulting inquiry_info records) share one kernel
//  buffer, the same "fixed header immediately followed by a run of
//  fixed-size records" shape as HCIGETDEVLIST in HCIDevice.swift.
//

import CBluetoothLinuxABI
import Glibc

// _IOR('H', 240, int) — see HCIDevice.swift's hciGetDeviceInfo/hciGetDeviceList
// for why this can't be imported directly.
private let hciInquiryRequest: UInt = 0x800448f0

/// `int hci_inquiry(int dev_id, int len, int nrsp, const uint8_t *lap, inquiry_info **ii, long flags)`
@c(hci_inquiry)
public func hci_inquiry(
    _ deviceID: Int32,
    _ len: Int32,
    _ numberOfResponses: Int32,
    _ lap: UnsafePointer<UInt8>?,
    _ inquiryInfo: UnsafeMutablePointer<UnsafeMutablePointer<inquiry_info>?>?,
    _ flags: Int
) -> Int32 {
    guard let inquiryInfo else { errno = EINVAL; return -1 }

    var requestedResponses = numberOfResponses
    let numberOfResponsesField: UInt8 = numberOfResponses > 0 ? UInt8(numberOfResponses) : 0
    if numberOfResponses <= 0 {
        requestedResponses = 255
    }

    var deviceID = deviceID
    if deviceID < 0 {
        deviceID = hci_get_route(nil)
        guard deviceID >= 0 else {
            errno = ENODEV
            return -1
        }
    }

    let dd = socket(Int32(AF_BLUETOOTH), Int32(SOCK_RAW.rawValue) | Int32(SOCK_CLOEXEC.rawValue), Int32(BTPROTO_HCI))
    guard dd >= 0 else { return dd }

    let headerSize = MemoryLayout<hci_inquiry_req>.size
    let entrySize = MemoryLayout<inquiry_info>.size
    let byteCount = headerSize + entrySize * Int(requestedResponses)
    let buffer = UnsafeMutableRawPointer.allocate(
        byteCount: byteCount,
        alignment: MemoryLayout<hci_inquiry_req>.alignment
    )
    defer { buffer.deallocate() }
    buffer.initializeMemory(as: UInt8.self, repeating: 0, count: byteCount)

    let request = buffer.assumingMemoryBound(to: hci_inquiry_req.self)
    request.pointee.dev_id = UInt16(deviceID)
    request.pointee.num_rsp = numberOfResponsesField
    request.pointee.length = UInt8(truncatingIfNeeded: len)
    request.pointee.flags = UInt16(truncatingIfNeeded: flags)
    if let lap {
        request.pointee.lap.0 = lap[0]
        request.pointee.lap.1 = lap[1]
        request.pointee.lap.2 = lap[2]
    } else {
        request.pointee.lap.0 = 0x33
        request.pointee.lap.1 = 0x8b
        request.pointee.lap.2 = 0x9e
    }

    let ioctlResult = ioctl(dd, numericCast(hciInquiryRequest), buffer)
    guard ioctlResult >= 0 else {
        let savedError = errno
        close(dd)
        errno = savedError
        return -1
    }

    let responseCount = Int(request.pointee.num_rsp)
    let resultByteCount = entrySize * responseCount

    var result: Int32
    if inquiryInfo.pointee == nil {
        inquiryInfo.pointee = UnsafeMutablePointer<inquiry_info>.allocate(capacity: responseCount)
    }
    if let destination = inquiryInfo.pointee {
        let source = buffer.advanced(by: headerSize)
        UnsafeMutableRawPointer(destination).copyMemory(from: source, byteCount: resultByteCount)
        result = Int32(responseCount)
    } else {
        result = -1
    }

    let savedError = errno
    close(dd)
    errno = savedError
    return result
}
