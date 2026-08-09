//
//  SDPSessionRequests.swift
//  BluetoothLinux
//
//  The three synchronous, blocking SDP requests (search, attribute
//  fetch, and the combined search+attribute fetch) and the low-level
//  send/wait-for-response primitive they're built on.
//

import CBluetoothLinuxABI
import BluetoothABI
import Glibc

private func pduHeader(_ buffer: UnsafeMutableRawPointer) -> UnsafeMutablePointer<sdp_pdu_hdr_t> {
    buffer.assumingMemoryBound(to: sdp_pdu_hdr_t.self)
}

/// `int sdp_send_req_w4_rsp(sdp_session_t *session, uint8_t *reqbuf, uint8_t *rspbuf, uint32_t reqsize, uint32_t *rspsize)`
@c(sdp_send_req_w4_rsp)
public func sdp_send_req_w4_rsp(
    _ session: UnsafeMutablePointer<sdp_session_t>?,
    _ requestBuffer: UnsafeMutablePointer<UInt8>?,
    _ responseBuffer: UnsafeMutablePointer<UInt8>?,
    _ requestSize: UInt32,
    _ responseSize: UnsafeMutablePointer<UInt32>?
) -> Int32 {
    guard let session, let requestBuffer, let responseBuffer, let responseSize else {
        errno = EINVAL
        return -1
    }
    guard sdpSendRequest(session, UnsafeRawPointer(requestBuffer), Int(requestSize)) >= 0 else { return -1 }

    let n = sdpReadResponse(session, UnsafeMutableRawPointer(responseBuffer), Int(SDP_RSP_BUFFER_SIZE))
    guard n >= 0 else { return -1 }

    let requestHeader = pduHeader(UnsafeMutableRawPointer(requestBuffer))
    let responseHeader = pduHeader(UnsafeMutableRawPointer(responseBuffer))
    guard n != 0, requestHeader.pointee.tid == responseHeader.pointee.tid else {
        errno = EPROTO
        return -1
    }

    responseSize.pointee = UInt32(n)
    return 0
}

/// `int sdp_service_search_req(sdp_session_t *session, const sdp_list_t *search, uint16_t max_rec_num, sdp_list_t **rsp)`
@c(sdp_service_search_req)
public func sdp_service_search_req(
    _ session: UnsafeMutablePointer<sdp_session_t>?,
    _ search: UnsafePointer<sdp_list_t>?,
    _ maxRecordNumber: UInt16,
    _ response: UnsafeMutablePointer<UnsafeMutablePointer<sdp_list_t>?>?
) -> Int32 {
    guard let session, let search, let response else { errno = EINVAL; return -1 }
    guard let requestBuffer = malloc(Int(SDP_REQ_BUFFER_SIZE)), let responseBuffer = malloc(Int(SDP_RSP_BUFFER_SIZE)) else {
        errno = ENOMEM
        return -1
    }
    defer { free(requestBuffer); free(responseBuffer) }

    let requestHeader = pduHeader(requestBuffer)
    requestHeader.pointee.pdu_id = UInt8(SDP_SVC_SEARCH_REQ)

    var writePointer = requestBuffer.advanced(by: MemoryLayout<sdp_pdu_hdr_t>.size)
    let baseSize = MemoryLayout<sdp_pdu_hdr_t>.size

    let seqLength = genSearchSequencePDU(writePointer, search)
    guard seqLength >= 0 else { errno = EINVAL; return -1 }
    writePointer = writePointer.advanced(by: Int(seqLength))

    writePointer.assumingMemoryBound(to: UInt16.self).pointee = maxRecordNumber.bigEndian
    writePointer = writePointer.advanced(by: MemoryLayout<UInt16>.size)

    let fixedSize = baseSize + Int(seqLength) + MemoryLayout<UInt16>.size
    var continuationState: UnsafePointer<SDPContinuationState>?
    response.pointee = nil

    repeat {
        let cstateLength = copyContinuationState(writePointer, Int(SDP_REQ_BUFFER_SIZE) - fixedSize, continuationState)
        let requestSize = fixedSize + Int(cstateLength)

        requestHeader.pointee.plen = UInt16(requestSize - baseSize).bigEndian
        requestHeader.pointee.tid = sdp_gen_tid(session).bigEndian

        var responseSize: UInt32 = 0
        guard sdp_send_req_w4_rsp(
            session,
            requestBuffer.assumingMemoryBound(to: UInt8.self),
            responseBuffer.assumingMemoryBound(to: UInt8.self),
            UInt32(requestSize),
            &responseSize
        ) >= 0 else { return -1 }

        guard responseSize >= MemoryLayout<sdp_pdu_hdr_t>.size else { errno = EPROTO; return -1 }

        let responseHeader = pduHeader(responseBuffer)
        guard responseHeader.pointee.pdu_id != UInt8(SDP_ERROR_RSP) else { return -1 }

        var scanned: UInt32 = 0
        var readPointer = responseBuffer.advanced(by: MemoryLayout<sdp_pdu_hdr_t>.size)
        var dataLength = Int(responseSize) - MemoryLayout<sdp_pdu_hdr_t>.size

        guard dataLength >= MemoryLayout<UInt16>.size * 2 else { errno = EPROTO; return -1 }
        readPointer = readPointer.advanced(by: MemoryLayout<UInt16>.size)
        scanned += UInt32(MemoryLayout<UInt16>.size)
        dataLength -= MemoryLayout<UInt16>.size

        let recordCount = readPointer.assumingMemoryBound(to: UInt16.self).pointee.bigEndian
        readPointer = readPointer.advanced(by: MemoryLayout<UInt16>.size)
        scanned += UInt32(MemoryLayout<UInt16>.size)
        dataLength -= MemoryLayout<UInt16>.size

        guard recordCount > 0 else { return -1 }

        extractRecordHandleSequence(readPointer.assumingMemoryBound(to: UInt8.self), dataLength, &response.pointee, Int(recordCount), &scanned)

        let responseLength = UInt32(responseHeader.pointee.plen.bigEndian)
        if responseLength > scanned {
            guard responseSize >= UInt32(MemoryLayout<sdp_pdu_hdr_t>.size) + scanned + 1 else { errno = EPROTO; return -1 }
            let cstatePointer = responseBuffer.advanced(by: MemoryLayout<sdp_pdu_hdr_t>.size + Int(scanned))
            let cstateLength = cstatePointer.assumingMemoryBound(to: UInt8.self).pointee
            continuationState = cstateLength > 0 ? UnsafePointer(cstatePointer.assumingMemoryBound(to: SDPContinuationState.self)) : nil
        } else {
            continuationState = nil
        }
    } while continuationState != nil

    return 0
}

/// `sdp_record_t *sdp_service_attr_req(sdp_session_t *session, uint32_t handle, sdp_attrreq_type_t reqtype, const sdp_list_t *attrids)`
@c(sdp_service_attr_req)
public func sdp_service_attr_req(
    _ session: UnsafeMutablePointer<sdp_session_t>?,
    _ handle: UInt32,
    _ requestType: sdp_attrreq_type_t,
    _ attributeIDs: UnsafePointer<sdp_list_t>?
) -> UnsafeMutablePointer<sdp_record_t>? {
    guard requestType == SDP_ATTR_REQ_INDIVIDUAL || requestType == SDP_ATTR_REQ_RANGE else {
        errno = EINVAL
        return nil
    }
    guard let session else { errno = EINVAL; return nil }

    guard let requestBuffer = malloc(Int(SDP_REQ_BUFFER_SIZE)), let responseBuffer = malloc(Int(SDP_RSP_BUFFER_SIZE)) else {
        errno = ENOMEM
        return nil
    }

    var concatenated = sdp_buf_t()
    var record: UnsafeMutablePointer<sdp_record_t>?
    defer {
        free(requestBuffer)
        free(responseBuffer)
        free(concatenated.data)
    }

    let requestHeader = pduHeader(requestBuffer)
    requestHeader.pointee.pdu_id = UInt8(SDP_SVC_ATTR_REQ)

    var writePointer = requestBuffer.advanced(by: MemoryLayout<sdp_pdu_hdr_t>.size)
    let baseSize = MemoryLayout<sdp_pdu_hdr_t>.size

    writePointer.assumingMemoryBound(to: UInt32.self).pointee = handle.bigEndian
    writePointer = writePointer.advanced(by: MemoryLayout<UInt32>.size)

    writePointer.assumingMemoryBound(to: UInt16.self).pointee = UInt16(65535).bigEndian
    writePointer = writePointer.advanced(by: MemoryLayout<UInt16>.size)

    let attributeType: Int32 = requestType == SDP_ATTR_REQ_INDIVIDUAL ? SDP_UINT16 : SDP_UINT32
    let seqLength = genAttrIDSequencePDU(writePointer, attributeIDs, UInt8(attributeType))
    guard seqLength >= 0 else { errno = EINVAL; return nil }
    writePointer = writePointer.advanced(by: Int(seqLength))

    let fixedSize = baseSize + MemoryLayout<UInt32>.size + MemoryLayout<UInt16>.size + Int(seqLength)
    var continuationState: UnsafePointer<SDPContinuationState>?
    var attributeListLength = 0

    repeat {
        let cstateLength = copyContinuationState(writePointer, Int(SDP_REQ_BUFFER_SIZE) - fixedSize, continuationState)
        let requestSize = fixedSize + Int(cstateLength)

        requestHeader.pointee.tid = sdp_gen_tid(session).bigEndian
        requestHeader.pointee.plen = UInt16(requestSize - baseSize).bigEndian

        var responseSize: UInt32 = 0
        let status = sdp_send_req_w4_rsp(
            session,
            requestBuffer.assumingMemoryBound(to: UInt8.self),
            responseBuffer.assumingMemoryBound(to: UInt8.self),
            UInt32(requestSize),
            &responseSize
        )
        guard responseSize >= MemoryLayout<sdp_pdu_hdr_t>.size else { return nil }
        guard status >= 0 else { return nil }

        let responseHeader = pduHeader(responseBuffer)
        guard responseHeader.pointee.pdu_id != UInt8(SDP_ERROR_RSP) else { return nil }

        var readPointer = responseBuffer.advanced(by: MemoryLayout<sdp_pdu_hdr_t>.size)
        var dataLength = Int(responseSize) - MemoryLayout<sdp_pdu_hdr_t>.size
        guard dataLength >= MemoryLayout<UInt16>.size else { return nil }

        let responseCount = Int(readPointer.assumingMemoryBound(to: UInt16.self).pointee.bigEndian)
        attributeListLength += responseCount
        readPointer = readPointer.advanced(by: MemoryLayout<UInt16>.size)
        dataLength -= MemoryLayout<UInt16>.size

        guard dataLength >= responseCount + 1 else { return nil }
        let cstateLengthByte = readPointer.advanced(by: responseCount).assumingMemoryBound(to: UInt8.self).pointee

        if cstateLengthByte > 0 || concatenated.data_size != 0 {
            continuationState = cstateLengthByte > 0
                ? UnsafePointer(readPointer.advanced(by: responseCount).assumingMemoryBound(to: SDPContinuationState.self))
                : nil

            let newSize = concatenated.data_size + UInt32(responseCount)
            concatenated.data = realloc(concatenated.data, Int(newSize))?.assumingMemoryBound(to: UInt8.self)
            concatenated.buf_size = newSize
            memcpy(concatenated.data! + Int(concatenated.data_size), readPointer, responseCount)
            concatenated.data_size = newSize
        } else {
            continuationState = nil
        }
    } while continuationState != nil

    guard attributeListLength > 0 else { return nil }

    var scanned: Int32 = 0
    if concatenated.data_size != 0 {
        record = sdp_extract_pdu(concatenated.data, Int32(concatenated.data_size), &scanned)
    } else {
        // No continuation-state fragmentation occurred: the last (and
        // only) response body is still in responseBuffer.
        let readPointer = responseBuffer.advanced(by: MemoryLayout<sdp_pdu_hdr_t>.size + MemoryLayout<UInt16>.size)
        record = sdp_extract_pdu(readPointer, Int32(attributeListLength), &scanned)
    }

    return record
}

/// `int sdp_service_search_attr_req(sdp_session_t *session, const sdp_list_t *search, sdp_attrreq_type_t reqtype, const sdp_list_t *attrids, sdp_list_t **rsp)`
@c(sdp_service_search_attr_req)
public func sdp_service_search_attr_req(
    _ session: UnsafeMutablePointer<sdp_session_t>?,
    _ search: UnsafePointer<sdp_list_t>?,
    _ requestType: sdp_attrreq_type_t,
    _ attributeIDs: UnsafePointer<sdp_list_t>?,
    _ response: UnsafeMutablePointer<UnsafeMutablePointer<sdp_list_t>?>?
) -> Int32 {
    guard requestType == SDP_ATTR_REQ_INDIVIDUAL || requestType == SDP_ATTR_REQ_RANGE else {
        errno = EINVAL
        return -1
    }
    guard let session, let search, let response else { errno = EINVAL; return -1 }

    guard let requestBuffer = malloc(Int(SDP_REQ_BUFFER_SIZE)), let responseBuffer = malloc(Int(SDP_RSP_BUFFER_SIZE)) else {
        errno = ENOMEM
        return -1
    }
    var concatenated = sdp_buf_t()
    defer {
        free(requestBuffer)
        free(responseBuffer)
        free(concatenated.data)
    }

    let requestHeader = pduHeader(requestBuffer)
    requestHeader.pointee.pdu_id = UInt8(SDP_SVC_SEARCH_ATTR_REQ)

    var writePointer = requestBuffer.advanced(by: MemoryLayout<sdp_pdu_hdr_t>.size)
    let baseSize = MemoryLayout<sdp_pdu_hdr_t>.size

    let searchSeqLength = genSearchSequencePDU(writePointer, search)
    guard searchSeqLength >= 0 else { errno = EINVAL; return -1 }
    writePointer = writePointer.advanced(by: Int(searchSeqLength))

    writePointer.assumingMemoryBound(to: UInt16.self).pointee = sdpMaxAttrLength.bigEndian
    writePointer = writePointer.advanced(by: MemoryLayout<UInt16>.size)

    let attributeType: Int32 = requestType == SDP_ATTR_REQ_INDIVIDUAL ? SDP_UINT16 : SDP_UINT32
    let attrSeqLength = genAttrIDSequencePDU(writePointer, attributeIDs, UInt8(attributeType))
    guard attrSeqLength >= 0 else { errno = EINVAL; return -1 }
    writePointer = writePointer.advanced(by: Int(attrSeqLength))

    response.pointee = nil
    let fixedSize = baseSize + Int(searchSeqLength) + MemoryLayout<UInt16>.size + Int(attrSeqLength)
    var continuationState: UnsafePointer<SDPContinuationState>?
    var attributeListLength = 0

    repeat {
        requestHeader.pointee.tid = sdp_gen_tid(session).bigEndian

        let cstateLength = copyContinuationState(writePointer, Int(SDP_REQ_BUFFER_SIZE) - fixedSize, continuationState)
        let requestSize = fixedSize + Int(cstateLength)
        requestHeader.pointee.plen = UInt16(requestSize - baseSize).bigEndian

        var responseSize: UInt32 = 0
        let status = sdp_send_req_w4_rsp(
            session,
            requestBuffer.assumingMemoryBound(to: UInt8.self),
            responseBuffer.assumingMemoryBound(to: UInt8.self),
            UInt32(requestSize),
            &responseSize
        )
        guard responseSize >= MemoryLayout<sdp_pdu_hdr_t>.size else { return -1 }
        guard status >= 0 else { return -1 }

        let responseHeader = pduHeader(responseBuffer)
        guard responseHeader.pointee.pdu_id != UInt8(SDP_ERROR_RSP) else { return -1 }

        var readPointer = responseBuffer.advanced(by: MemoryLayout<sdp_pdu_hdr_t>.size)
        var dataLength = Int(responseSize) - MemoryLayout<sdp_pdu_hdr_t>.size
        guard dataLength >= MemoryLayout<UInt16>.size else { errno = EPROTO; return -1 }

        let responseCount = Int(readPointer.assumingMemoryBound(to: UInt16.self).pointee.bigEndian)
        attributeListLength += responseCount
        readPointer = readPointer.advanced(by: MemoryLayout<UInt16>.size)
        dataLength -= MemoryLayout<UInt16>.size

        guard dataLength >= responseCount + 1 else { errno = EPROTO; return -1 }
        let cstateLengthByte = readPointer.advanced(by: responseCount).assumingMemoryBound(to: UInt8.self).pointee

        if cstateLengthByte > 0 || concatenated.data_size != 0 {
            continuationState = cstateLengthByte > 0
                ? UnsafePointer(readPointer.advanced(by: responseCount).assumingMemoryBound(to: SDPContinuationState.self))
                : nil

            let newSize = concatenated.data_size + UInt32(responseCount)
            concatenated.data = realloc(concatenated.data, Int(newSize))?.assumingMemoryBound(to: UInt8.self)
            concatenated.buf_size = newSize
            memcpy(concatenated.data! + Int(concatenated.data_size), readPointer, responseCount)
            concatenated.data_size = newSize
        } else {
            continuationState = nil
        }
    } while continuationState != nil

    guard attributeListLength > 0 else { return 0 }

    var readPointer: UnsafeMutableRawPointer
    var remaining: Int
    if concatenated.data_size != 0 {
        readPointer = UnsafeMutableRawPointer(concatenated.data!)
        remaining = Int(concatenated.data_size)
    } else {
        readPointer = responseBuffer.advanced(by: MemoryLayout<sdp_pdu_hdr_t>.size + MemoryLayout<UInt16>.size)
        remaining = attributeListLength
    }

    var dataType: UInt8 = 0
    var outerSeqLength: Int32 = 0
    let outerScanned = sdp_extract_seqtype(readPointer, Int32(remaining), &dataType, &outerSeqLength)
    guard outerScanned != 0, outerSeqLength != 0 else { return 0 }

    readPointer = readPointer.advanced(by: Int(outerScanned))
    remaining -= Int(outerScanned)
    var totalScanned = Int(outerScanned)
    var records: UnsafeMutablePointer<sdp_list_t>?

    repeat {
        var recordSize: Int32 = 0
        guard let record = sdp_extract_pdu(readPointer, Int32(remaining), &recordSize) else {
            errno = EPROTO
            return -1
        }
        guard recordSize > 0 else {
            sdp_record_free(record)
            break
        }
        totalScanned += Int(recordSize)
        readPointer = readPointer.advanced(by: Int(recordSize))
        remaining -= Int(recordSize)
        records = sdp_list_append(records, record)
    } while totalScanned < attributeListLength && remaining > 0

    response.pointee = records
    return 0
}
