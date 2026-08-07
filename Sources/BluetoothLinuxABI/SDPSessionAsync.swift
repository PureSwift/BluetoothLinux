//
//  SDPSessionAsync.swift
//  BluetoothLinux
//
//  The non-blocking half of the SDP client: the three request
//  functions that send a PDU and return immediately, and sdp_process,
//  which the caller drives from its own event loop whenever the
//  session socket becomes readable.
//
//  The division of labour is that a request function only ever builds
//  and sends; everything about the reply — reassembling a response
//  split across continuation states, resending for the next fragment,
//  and finally invoking the callback registered with sdp_set_notify —
//  belongs to sdp_process.
//
//  sdp_process's return value reads backwards until you know the
//  convention: 0 means "not finished, call me again", and -1 means the
//  transaction is over and the callback has already run. -1 is
//  therefore the normal, successful ending, and says nothing about
//  whether the transaction succeeded; that is what the callback's
//  status argument and sdp_get_error are for.
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

/// The status a caller sees when the failure was local — a short read,
/// a malformed reply, a socket error — rather than an SDP error
/// response carrying a real code. The header documents this as the
/// signal to call sdp_get_error for the actual reason.
private let sdpUnknownStatus: UInt16 = 0xFFFF

// MARK: - Request setup

/// Ready the transaction for a new request: discard whatever the
/// previous one accumulated, make sure the request buffer exists, and
/// clear it.
private func beginRequest(_ transaction: UnsafeMutablePointer<SDPTransaction>) -> UnsafeMutableRawPointer? {
    free(transaction.pointee.responseBuffer.data)
    transaction.pointee.responseBuffer = sdp_buf_t()

    if transaction.pointee.requestBuffer == nil {
        guard let buffer = malloc(Int(SDP_REQ_BUFFER_SIZE)) else {
            transaction.pointee.error = ENOMEM
            return nil
        }
        transaction.pointee.requestBuffer = buffer
    }

    // The request buffer outlives the request — sdp_process rewrites
    // its continuation state in place — so it is cleared here rather
    // than at allocation.
    let buffer = transaction.pointee.requestBuffer!
    memset(buffer, 0, Int(SDP_REQ_BUFFER_SIZE))
    return buffer
}

/// Abandon a request that could not be built or sent. The reason goes
/// into the transaction rather than errno, because the caller reads it
/// back with sdp_get_error once the callback tells it something went
/// wrong.
private func failRequest(_ transaction: UnsafeMutablePointer<SDPTransaction>, _ error: Int32) -> Int32 {
    transaction.pointee.error = error
    free(transaction.pointee.requestBuffer)
    transaction.pointee.requestBuffer = nil
    return -1
}

/// Terminate the request with an empty continuation state, fill in the
/// header length and send it.
///
/// `size` is the request length *excluding* that trailing
/// continuation-state byte, and that is what the transaction records:
/// it is the offset sdp_process overwrites when the server asks for
/// the request to be repeated with a real continuation state.
private func finishRequest(
    _ session: UnsafeMutablePointer<sdp_session_t>,
    _ transaction: UnsafeMutablePointer<SDPTransaction>,
    _ size: Int
) -> Int32 {
    let buffer = transaction.pointee.requestBuffer!
    transaction.pointee.requestSize = UInt32(size)
    storeUnaligned(UInt8(0), to: buffer, offset: size)

    let total = size + 1
    pduHeader(buffer).pointee.plen = UInt16(total - headerSize).bigEndian
    return sendRequest(session, transaction, total)
}

/// Write the whole request to the socket.
///
/// This does not go through sdpSendRequest because a failed write has
/// to land in the transaction rather than be reported through errno.
private func sendRequest(
    _ session: UnsafeMutablePointer<sdp_session_t>,
    _ transaction: UnsafeMutablePointer<SDPTransaction>,
    _ length: Int
) -> Int32 {
    let buffer = transaction.pointee.requestBuffer!
    var sent = 0
    while sent < length {
        let written = send(session.pointee.sock, buffer.advanced(by: sent), length - sent, 0)
        guard written >= 0 else { return failRequest(transaction, errno) }
        sent += written
    }
    return 0
}

/// The attribute-ID data type for a request type.
///
/// Unlike the blocking requests, the asynchronous ones do not reject
/// an out-of-range value: anything that is not SDP_ATTR_REQ_INDIVIDUAL
/// is encoded as a range.
private func attributeDataType(_ requestType: sdp_attrreq_type_t) -> UInt8 {
    UInt8(requestType == SDP_ATTR_REQ_INDIVIDUAL ? SDP_UINT16 : SDP_UINT32)
}

// MARK: - Requests

/// `int sdp_service_search_async(sdp_session_t *session, const sdp_list_t *search, uint16_t max_rec_num)`
@c(sdp_service_search_async)
public func sdp_service_search_async(
    _ session: UnsafeMutablePointer<sdp_session_t>?,
    _ search: UnsafePointer<sdp_list_t>?,
    _ maxRecordNumber: UInt16
) -> Int32 {
    guard let session, let transaction = sdpTransaction(session) else { return -1 }
    guard let buffer = beginRequest(transaction) else { return -1 }

    pduHeader(buffer).pointee.pdu_id = UInt8(SDP_SVC_SEARCH_REQ)
    pduHeader(buffer).pointee.tid = sdp_gen_tid(session).bigEndian

    var offset = headerSize
    let seqLength = genSearchSequencePDU(buffer.advanced(by: offset), search)
    guard seqLength >= 0 else { return failRequest(transaction, EINVAL) }
    offset += Int(seqLength)

    storeUnaligned(maxRecordNumber.bigEndian, to: buffer, offset: offset)
    offset += MemoryLayout<UInt16>.size

    return finishRequest(session, transaction, offset)
}

/// `int sdp_service_attr_async(sdp_session_t *session, uint32_t handle, sdp_attrreq_type_t reqtype, const sdp_list_t *attrid_list)`
@c(sdp_service_attr_async)
public func sdp_service_attr_async(
    _ session: UnsafeMutablePointer<sdp_session_t>?,
    _ handle: UInt32,
    _ requestType: sdp_attrreq_type_t,
    _ attributeIDs: UnsafePointer<sdp_list_t>?
) -> Int32 {
    guard let session, let transaction = sdpTransaction(session) else { return -1 }
    guard let buffer = beginRequest(transaction) else { return -1 }

    pduHeader(buffer).pointee.pdu_id = UInt8(SDP_SVC_ATTR_REQ)
    pduHeader(buffer).pointee.tid = sdp_gen_tid(session).bigEndian

    var offset = headerSize
    storeUnaligned(handle.bigEndian, to: buffer, offset: offset)
    offset += MemoryLayout<UInt32>.size

    storeUnaligned(sdpMaxAttrLength.bigEndian, to: buffer, offset: offset)
    offset += MemoryLayout<UInt16>.size

    let seqLength = genAttrIDSequencePDU(buffer.advanced(by: offset), attributeIDs, attributeDataType(requestType))
    guard seqLength >= 0 else { return failRequest(transaction, EINVAL) }
    offset += Int(seqLength)

    return finishRequest(session, transaction, offset)
}

/// `int sdp_service_search_attr_async(sdp_session_t *session, const sdp_list_t *search, sdp_attrreq_type_t reqtype, const sdp_list_t *attrid_list)`
@c(sdp_service_search_attr_async)
public func sdp_service_search_attr_async(
    _ session: UnsafeMutablePointer<sdp_session_t>?,
    _ search: UnsafePointer<sdp_list_t>?,
    _ requestType: sdp_attrreq_type_t,
    _ attributeIDs: UnsafePointer<sdp_list_t>?
) -> Int32 {
    guard let session, let transaction = sdpTransaction(session) else { return -1 }
    guard let buffer = beginRequest(transaction) else { return -1 }

    pduHeader(buffer).pointee.pdu_id = UInt8(SDP_SVC_SEARCH_ATTR_REQ)
    pduHeader(buffer).pointee.tid = sdp_gen_tid(session).bigEndian

    var offset = headerSize
    let searchSeqLength = genSearchSequencePDU(buffer.advanced(by: offset), search)
    guard searchSeqLength >= 0 else { return failRequest(transaction, EINVAL) }
    offset += Int(searchSeqLength)

    storeUnaligned(sdpMaxAttrLength.bigEndian, to: buffer, offset: offset)
    offset += MemoryLayout<UInt16>.size

    let attrSeqLength = genAttrIDSequencePDU(buffer.advanced(by: offset), attributeIDs, attributeDataType(requestType))
    guard attrSeqLength >= 0 else { return failRequest(transaction, EINVAL) }
    offset += Int(attrSeqLength)

    return finishRequest(session, transaction, offset)
}

// MARK: - Response processing

/// End the transaction: hand the caller's callback whatever response
/// there is and report "finished".
///
/// Once any fragment has been accumulated, that buffer is what the
/// callback sees, whatever the immediate caller passed here — an error
/// arriving mid-transaction still delivers the bytes gathered so far.
private func notify(
    _ transaction: UnsafeMutablePointer<SDPTransaction>,
    type: UInt8,
    status: UInt16,
    data: UnsafeMutableRawPointer,
    size: Int
) -> Int32 {
    var data = data
    var size = size
    let accumulated = transaction.pointee.responseBuffer
    if accumulated.data_size != 0, let buffer = accumulated.data {
        data = UnsafeMutableRawPointer(buffer)
        size = Int(accumulated.data_size)
    }
    if let callback = transaction.pointee.callback {
        callback(type, status, data.assumingMemoryBound(to: UInt8.self), size, transaction.pointee.userData)
    }
    return -1
}

/// Which bytes of this response carry payload, and how long the body
/// is excluding the continuation state.
private struct SDPResponseFragment {
    /// Start of the bytes to append to the accumulated response.
    var payload: UnsafeMutableRawPointer
    /// How many of them there are.
    var length: Int
    /// The body length the two consistency checks are stated in terms
    /// of: `length` plus whichever fixed fields precede it in this PDU.
    var bodyLength: Int
}

/// `int sdp_process(sdp_session_t *session)`
///
/// Returns 0 when a continuation request has been sent and the caller
/// should wait for the socket to become readable again, and -1 when
/// the transaction is over — at which point the notify callback has
/// already run. See the note at the top of this file.
@c(sdp_process)
public func sdp_process(_ session: UnsafeMutablePointer<sdp_session_t>?) -> Int32 {
    guard let session, let transaction = sdpTransaction(session) else { return -1 }
    guard let responseBuffer = bt_malloc0(Int(SDP_RSP_BUFFER_SIZE)) else { return -1 }
    defer { free(responseBuffer) }

    let body = responseBuffer.advanced(by: headerSize)

    /// Every failure below ends the transaction the same way: record
    /// why, then let the callback see it.
    func fail(_ error: Int32, type: UInt8, status: UInt16 = sdpUnknownStatus) -> Int32 {
        transaction.pointee.error = error
        return notify(transaction, type: type, status: status, data: body, size: 0)
    }

    let responseSize = sdpReadResponse(session, responseBuffer, Int(SDP_RSP_BUFFER_SIZE))
    guard responseSize >= 0 else { return fail(errno, type: 0) }

    // A reply that does not answer the request in flight, or whose
    // header disagrees with how much actually arrived, is not worth
    // parsing.
    guard let requestBuffer = transaction.pointee.requestBuffer,
        pduHeader(requestBuffer).pointee.tid == pduHeader(responseBuffer).pointee.tid
    else {
        return fail(EPROTO, type: 0)
    }
    let payloadLength = Int(UInt16(bigEndian: pduHeader(responseBuffer).pointee.plen))
    guard payloadLength + headerSize == responseSize else { return fail(EPROTO, type: 0) }

    let pduID = responseBuffer.load(as: UInt8.self)
    let accumulated = Int(transaction.pointee.responseBuffer.data_size)
    let fragment: SDPResponseFragment

    switch Int32(pduID) {
    case SDP_ERROR_RSP:
        // Carries a real status code, so it is reported as-is rather
        // than through sdp_get_error.
        let status = UInt16(bigEndian: responseBuffer.loadUnaligned(fromByteOffset: 5, as: UInt16.self))
        return notify(transaction, type: pduID, status: status, data: body, size: payloadLength)

    case SDP_SVC_SEARCH_RSP:
        let total = UInt16(bigEndian: responseBuffer.loadUnaligned(fromByteOffset: 5, as: UInt16.self))
        // Kept in network order: it is added to the stored count below
        // without being swapped.
        let current = responseBuffer.loadUnaligned(fromByteOffset: 7, as: UInt16.self)
        let currentCount = Int(UInt16(bigEndian: current))
        guard Int(total) >= currentCount else { return fail(EPROTO, type: pduID) }

        let handles = currentCount * MemoryLayout<UInt32>.size
        if accumulated == 0 {
            // First fragment: keep the two count fields, so what
            // accumulates looks like one whole search response.
            fragment = SDPResponseFragment(payload: body, length: handles + 4, bodyLength: handles + 4)
        } else {
            guard accumulated > 3, let stored = transaction.pointee.responseBuffer.data else {
                return fail(EPROTO, type: pduID)
            }
            // Fold this fragment's record count into the count already
            // stored in that header. The reference adds the two values
            // without byte-swapping either — so a total that carries
            // out of the low byte comes out wrong — but this is what a
            // client reads back, so it is reproduced rather than
            // corrected.
            let countField = UnsafeMutableRawPointer(stored).advanced(by: 2)
            let running = countField.loadUnaligned(as: UInt16.self)
            storeUnaligned(running &+ current, to: countField, offset: 0)

            fragment = SDPResponseFragment(
                payload: responseBuffer.advanced(by: headerSize + 4),
                length: handles,
                bodyLength: handles + 4
            )
        }

    case SDP_SVC_ATTR_RSP, SDP_SVC_SEARCH_ATTR_RSP:
        let count = Int(UInt16(bigEndian: responseBuffer.loadUnaligned(fromByteOffset: 5, as: UInt16.self)))
        // A first fragment has to carry an actual attribute list; a
        // continuation may legitimately add nothing.
        guard accumulated != 0 || count > 1 else {
            return fail(EPROTO, type: pduID, status: UInt16(SDP_INVALID_PDU_SIZE))
        }
        fragment = SDPResponseFragment(
            payload: responseBuffer.advanced(by: headerSize + MemoryLayout<UInt16>.size),
            length: count,
            bodyLength: count + MemoryLayout<UInt16>.size
        )

    default:
        return fail(EPROTO, type: pduID)
    }

    // There has to be room after the body for a continuation state,
    // and the two lengths have to agree with what arrived, before any
    // of it is trusted enough to copy.
    guard responseSize - 4 > fragment.bodyLength + 1 else { return fail(EPROTO, type: pduID) }
    let continuationState = fragment.payload.advanced(by: fragment.length)
    let continuationLength = Int(continuationState.load(as: UInt8.self))
    guard responseSize - 5 == fragment.bodyLength + continuationLength + 1 else {
        return fail(EPROTO, type: pduID)
    }

    // Append this fragment to the accumulated response.
    let newSize = accumulated + fragment.length
    guard let grown = realloc(transaction.pointee.responseBuffer.data, newSize) else {
        return fail(ENOMEM, type: pduID)
    }
    transaction.pointee.responseBuffer.data = grown.assumingMemoryBound(to: UInt8.self)
    transaction.pointee.responseBuffer.buf_size = UInt32(newSize)
    memcpy(grown.advanced(by: accumulated), fragment.payload, fragment.length)
    transaction.pointee.responseBuffer.data_size = UInt32(newSize)

    guard continuationLength > 0 else {
        // No continuation state: that was the last fragment.
        return notify(transaction, type: pduID, status: 0, data: body, size: 0)
    }

    // Repeat the request with the server's continuation state
    // appended. requestSize excludes the empty continuation byte the
    // request function wrote, so each round overwrites the previous
    // one in place and the request never grows.
    pduHeader(requestBuffer).pointee.tid = sdp_gen_tid(session).bigEndian

    let requestSize = Int(transaction.pointee.requestSize)
    let available = Int(SDP_REQ_BUFFER_SIZE) - requestSize
    // Truncating an oversized continuation state produces a request
    // the server will reject, but that is the reference's behaviour
    // and is preferable to overrunning the buffer.
    let stateLength = available <= continuationLength ? max(0, available - 1) : continuationLength

    storeUnaligned(UInt8(stateLength), to: requestBuffer, offset: requestSize)
    memcpy(requestBuffer.advanced(by: requestSize + 1), continuationState.advanced(by: 1), stateLength)

    let total = requestSize + stateLength + 1
    pduHeader(requestBuffer).pointee.plen = UInt16(total - headerSize).bigEndian

    var sent = 0
    while sent < total {
        let written = send(session.pointee.sock, requestBuffer.advanced(by: sent), total - sent, 0)
        guard written >= 0 else { return fail(errno, type: pduID) }
        sent += written
    }
    return 0
}
