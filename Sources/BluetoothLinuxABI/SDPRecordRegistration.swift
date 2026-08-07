//
//  SDPRecordRegistration.swift
//  BluetoothLinux
//
//  Registering, updating and removing a service record with the local
//  SDP server.
//
//  The PDUs these send (0x75 through 0x80) are not part of the
//  Bluetooth specification — the vendored sdp.h says exactly that
//  where it defines them, calling them "some additions to support
//  service registration ... outside the scope of the Bluetooth
//  specification". There is therefore no published wire format to
//  implement against, and the layouts below were recovered from the
//  reference libbluetooth.so.3 so that a client compiled against it
//  keeps talking to the same server unchanged.
//
//  Two reference behaviours are reproduced deliberately rather than
//  corrected, because a client sees them and may depend on them; each
//  is called out at the point it appears.
//
//  All of these require a session connected to the *local* SDP server
//  (sdp_connect with BDADDR_LOCAL, which sdp_connect turns into a Unix
//  socket); a session to a remote device fails with EREMOTE.
//
//  Like the rest of the SDP session surface, none of this has been
//  exercised against a real SDP server yet.
//

import CBluetoothLinuxABI
import BluetoothABI
import Glibc

private func pduHeader(_ buffer: UnsafeMutableRawPointer) -> UnsafeMutablePointer<sdp_pdu_hdr_t> {
    buffer.assumingMemoryBound(to: sdp_pdu_hdr_t.self)
}

private let headerSize = MemoryLayout<sdp_pdu_hdr_t>.size

/// The 16-bit status of a register/update/remove response.
///
/// The reference loads it in host order rather than calling ntohs, so
/// a non-zero status reaches the caller byte-swapped. Clients were
/// written against that, and success (zero) reads the same either way,
/// so the load is left as-is rather than quietly changing the value a
/// client gets back.
private func responseStatus(_ response: UnsafeMutableRawPointer) -> Int32 {
    Int32(response.loadUnaligned(fromByteOffset: 5, as: UInt16.self))
}

/// Allocate the request and response buffers shared by all three
/// operations, and start the request PDU with its id and a fresh
/// transaction ID.
private func beginRequest(
    _ session: UnsafeMutablePointer<sdp_session_t>,
    _ pduID: Int32
) -> (request: UnsafeMutableRawPointer, response: UnsafeMutableRawPointer)? {
    guard let request = malloc(Int(SDP_REQ_BUFFER_SIZE)) else { return nil }
    guard let response = malloc(Int(SDP_RSP_BUFFER_SIZE)) else {
        free(request)
        return nil
    }
    let header = pduHeader(request)
    header.pointee.pdu_id = UInt8(pduID)
    header.pointee.tid = sdp_gen_tid(session).bigEndian
    return (request, response)
}

// MARK: - Register

/// `int sdp_device_record_register_binary(sdp_session_t *session, bdaddr_t *device, uint8_t *data, uint32_t size, uint8_t flags, uint32_t *handle)`
@c(sdp_device_record_register_binary)
public func sdp_device_record_register_binary(
    _ session: UnsafeMutablePointer<sdp_session_t>?,
    _ device: UnsafeMutablePointer<bdaddr_t>?,
    _ data: UnsafeMutablePointer<UInt8>?,
    _ size: UInt32,
    _ flags: UInt8,
    _ handle: UnsafeMutablePointer<UInt32>?
) -> Int32 {
    // The reference dereferences these without checking; refusing a
    // null pointer can only turn a crash into an error return.
    guard let session, let device, let data else { errno = EINVAL; return -1 }
    guard session.pointee.local != 0 else { errno = EREMOTE; return -1 }

    guard let (requestBuffer, responseBuffer) = beginRequest(session, SDP_SVC_REGISTER_REQ) else {
        errno = ENOMEM
        return -1
    }
    defer { free(requestBuffer); free(responseBuffer) }

    // A record registered on behalf of a specific remote device
    // carries that address between the flags byte and the record
    // itself, and sets SDP_DEVICE_RECORD so the server knows to expect
    // it. Registering for this host omits both.
    var anyAddress = bdaddr_t(b: (0, 0, 0, 0, 0, 0))
    let recordOffset: Int
    if bacmp(device, &anyAddress) != 0 {
        storeUnaligned(flags | UInt8(SDP_DEVICE_RECORD), to: requestBuffer, offset: 5)
        withUnsafeBytes(of: device.pointee) { source in
            requestBuffer.advanced(by: 6).copyMemory(from: source.baseAddress!, byteCount: MemoryLayout<bdaddr_t>.size)
        }
        recordOffset = 6 + MemoryLayout<bdaddr_t>.size
    } else {
        storeUnaligned(flags, to: requestBuffer, offset: 5)
        recordOffset = 6
    }

    // The reference leaves this to _FORTIFY_SOURCE, so an oversized
    // record aborts the process there. Refusing it is strictly safer
    // and cannot break a caller that was already working.
    guard Int(size) <= Int(SDP_REQ_BUFFER_SIZE) - recordOffset else { errno = EINVAL; return -1 }
    memcpy(requestBuffer.advanced(by: recordOffset), data, Int(size))

    let requestSize = recordOffset + Int(size)
    pduHeader(requestBuffer).pointee.plen = UInt16(requestSize - headerSize).bigEndian

    var responseSize: UInt32 = 0
    let status = sdp_send_req_w4_rsp(
        session,
        requestBuffer.assumingMemoryBound(to: UInt8.self),
        responseBuffer.assumingMemoryBound(to: UInt8.self),
        UInt32(requestSize),
        &responseSize
    )
    guard status >= 0 else { return status }
    guard responseSize > 4 else { errno = EPROTO; return -1 }

    switch Int32(responseBuffer.load(as: UInt8.self)) {
    case SDP_ERROR_RSP:
        errno = EINVAL
        return -1
    case SDP_SVC_REGISTER_RSP:
        // The assigned handle follows the header; a response too short
        // to hold one is malformed even though the id was right.
        guard responseSize > 8 else { errno = EPROTO; return -1 }
        handle?.pointee = UInt32(bigEndian: responseBuffer.loadUnaligned(fromByteOffset: 5, as: UInt32.self))
        return status
    default:
        errno = EPROTO
        return -1
    }
}

/// `int sdp_device_record_register(sdp_session_t *session, bdaddr_t *device, sdp_record_t *rec, uint8_t flags)`
@c(sdp_device_record_register)
public func sdp_device_record_register(
    _ session: UnsafeMutablePointer<sdp_session_t>?,
    _ device: UnsafeMutablePointer<bdaddr_t>?,
    _ record: UnsafeMutablePointer<sdp_record_t>?,
    _ flags: UInt8
) -> Int32 {
    guard let record else { errno = EINVAL; return -1 }

    // A record that already names a handle keeps it, with the
    // attribute rewritten so the encoded PDU agrees with the struct
    // field. Zero means "server assigns one" and all-ones is reserved,
    // so neither is sent.
    let requested = record.pointee.handle
    if requested != 0, requested != .max {
        var value = requested
        sdp_attr_replace(record, UInt16(SDP_ATTR_RECORD_HANDLE), sdp_data_alloc(UInt8(SDP_UINT32), &value))
    }

    var pdu = sdp_buf_t()
    guard sdp_gen_record_pdu(record, &pdu) >= 0 else { errno = ENOMEM; return -1 }

    var assigned: UInt32 = 0
    let status = sdp_device_record_register_binary(session, device, pdu.data, pdu.data_size, flags, &assigned)
    free(pdu.data)
    guard status == 0 else { return status }

    // Write the handle the server picked back into both the struct
    // field and the record's own attribute, so a later update or
    // unregister of the same record refers to the right one.
    let data = sdp_data_alloc(UInt8(SDP_UINT32), &assigned)
    record.pointee.handle = assigned
    sdp_attr_replace(record, UInt16(SDP_ATTR_RECORD_HANDLE), data)
    return status
}

/// `int sdp_record_register(sdp_session_t *session, sdp_record_t *rec, uint8_t flags)`
@c(sdp_record_register)
public func sdp_record_register(
    _ session: UnsafeMutablePointer<sdp_session_t>?,
    _ record: UnsafeMutablePointer<sdp_record_t>?,
    _ flags: UInt8
) -> Int32 {
    var anyAddress = bdaddr_t(b: (0, 0, 0, 0, 0, 0))
    return sdp_device_record_register(session, &anyAddress, record, flags)
}

// MARK: - Unregister

/// `int sdp_device_record_unregister_binary(sdp_session_t *session, bdaddr_t *device, uint32_t handle)`
///
/// `device` is part of the signature but, as in the reference, never
/// read: a remove request carries only the record handle.
@c(sdp_device_record_unregister_binary)
public func sdp_device_record_unregister_binary(
    _ session: UnsafeMutablePointer<sdp_session_t>?,
    _ device: UnsafeMutablePointer<bdaddr_t>?,
    _ handle: UInt32
) -> Int32 {
    guard handle != 0 else { errno = EINVAL; return -1 }
    guard let session else { errno = EINVAL; return -1 }
    guard session.pointee.local != 0 else { errno = EREMOTE; return -1 }

    guard let (requestBuffer, responseBuffer) = beginRequest(session, SDP_SVC_REMOVE_REQ) else {
        errno = ENOMEM
        return -1
    }
    defer { free(requestBuffer); free(responseBuffer) }

    storeUnaligned(handle.bigEndian, to: requestBuffer, offset: 5)
    let requestSize = 5 + MemoryLayout<UInt32>.size
    pduHeader(requestBuffer).pointee.plen = UInt16(requestSize - headerSize).bigEndian

    var responseSize: UInt32 = 0
    let status = sdp_send_req_w4_rsp(
        session,
        requestBuffer.assumingMemoryBound(to: UInt8.self),
        responseBuffer.assumingMemoryBound(to: UInt8.self),
        UInt32(requestSize),
        &responseSize
    )
    guard status >= 0 else { return status }
    guard responseSize > 6 else { errno = EPROTO; return -1 }

    switch Int32(responseBuffer.load(as: UInt8.self)) {
    case SDP_ERROR_RSP:
        errno = EINVAL
        return -1
    case SDP_SVC_REMOVE_RSP:
        return responseStatus(responseBuffer)
    default:
        errno = EPROTO
        return -1
    }
}

/// `int sdp_device_record_unregister(sdp_session_t *session, bdaddr_t *device, sdp_record_t *rec)`
///
/// Frees the record on success — the caller must not touch it again.
@c(sdp_device_record_unregister)
public func sdp_device_record_unregister(
    _ session: UnsafeMutablePointer<sdp_session_t>?,
    _ device: UnsafeMutablePointer<bdaddr_t>?,
    _ record: UnsafeMutablePointer<sdp_record_t>?
) -> Int32 {
    guard let record else { errno = EINVAL; return -1 }
    let status = sdp_device_record_unregister_binary(session, device, record.pointee.handle)
    if status == 0 {
        sdp_record_free(record)
    }
    return status
}

/// `int sdp_record_unregister(sdp_session_t *session, sdp_record_t *rec)`
@c(sdp_record_unregister)
public func sdp_record_unregister(
    _ session: UnsafeMutablePointer<sdp_session_t>?,
    _ record: UnsafeMutablePointer<sdp_record_t>?
) -> Int32 {
    var anyAddress = bdaddr_t(b: (0, 0, 0, 0, 0, 0))
    return sdp_device_record_unregister(session, &anyAddress, record)
}

// MARK: - Update

/// `int sdp_device_record_update_binary(sdp_session_t *session, bdaddr_t *device, uint32_t handle, uint8_t *data, uint32_t size)`
///
/// Exported but not implemented in the reference either: it returns -1
/// immediately, without touching errno and without sending anything.
/// Callers reach the update path through sdp_device_record_update,
/// which encodes the record itself.
@c(sdp_device_record_update_binary)
public func sdp_device_record_update_binary(
    _ session: UnsafeMutablePointer<sdp_session_t>?,
    _ device: UnsafeMutablePointer<bdaddr_t>?,
    _ handle: UInt32,
    _ data: UnsafeMutablePointer<UInt8>?,
    _ size: UInt32
) -> Int32 {
    -1
}

/// `int sdp_device_record_update(sdp_session_t *session, bdaddr_t *device, const sdp_record_t *rec)`
///
/// `device` is part of the signature but, as in the reference, never
/// read: the update request identifies the record by handle alone.
@c(sdp_device_record_update)
public func sdp_device_record_update(
    _ session: UnsafeMutablePointer<sdp_session_t>?,
    _ device: UnsafeMutablePointer<bdaddr_t>?,
    _ record: UnsafePointer<sdp_record_t>?
) -> Int32 {
    guard let session, let record else { errno = EINVAL; return -1 }
    let handle = record.pointee.handle
    // An unregistered record has no handle to update.
    guard handle != 0 else { errno = EINVAL; return -1 }
    guard session.pointee.local != 0 else { errno = EREMOTE; return -1 }

    guard let (requestBuffer, responseBuffer) = beginRequest(session, SDP_SVC_UPDATE_REQ) else {
        errno = ENOMEM
        return -1
    }
    defer { free(requestBuffer); free(responseBuffer) }

    storeUnaligned(handle.bigEndian, to: requestBuffer, offset: 5)
    let recordOffset = 5 + MemoryLayout<UInt32>.size

    var pdu = sdp_buf_t()
    guard sdp_gen_record_pdu(record, &pdu) >= 0 else { errno = ENOMEM; return -1 }
    defer { free(pdu.data) }

    // As in the register path, the reference leaves the bound to
    // _FORTIFY_SOURCE; refusing the write is safer and equivalent for
    // any record that fit before.
    guard Int(pdu.data_size) <= Int(SDP_REQ_BUFFER_SIZE) - recordOffset else { errno = EINVAL; return -1 }
    memcpy(requestBuffer.advanced(by: recordOffset), pdu.data, Int(pdu.data_size))

    let requestSize = recordOffset + Int(pdu.data_size)
    pduHeader(requestBuffer).pointee.plen = UInt16(requestSize - headerSize).bigEndian

    var responseSize: UInt32 = 0
    let status = sdp_send_req_w4_rsp(
        session,
        requestBuffer.assumingMemoryBound(to: UInt8.self),
        responseBuffer.assumingMemoryBound(to: UInt8.self),
        UInt32(requestSize),
        &responseSize
    )
    guard status >= 0 else { return status }
    guard responseSize > 6 else { errno = EPROTO; return -1 }

    switch Int32(responseBuffer.load(as: UInt8.self)) {
    case SDP_ERROR_RSP:
        errno = EINVAL
        return -1
    case SDP_SVC_UPDATE_RSP:
        return responseStatus(responseBuffer)
    default:
        errno = EPROTO
        return -1
    }
}

/// `int sdp_record_update(sdp_session_t *sess, const sdp_record_t *rec)`
@c(sdp_record_update)
public func sdp_record_update(
    _ session: UnsafeMutablePointer<sdp_session_t>?,
    _ record: UnsafePointer<sdp_record_t>?
) -> Int32 {
    var anyAddress = bdaddr_t(b: (0, 0, 0, 0, 0, 0))
    return sdp_device_record_update(session, &anyAddress, record)
}
