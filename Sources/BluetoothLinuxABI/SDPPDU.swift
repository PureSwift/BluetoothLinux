//
//  SDPPDU.swift
//  BluetoothLinux
//
//  Request-PDU assembly helpers shared by the synchronous and
//  asynchronous SDP request functions: encoding a search pattern or
//  attribute ID list as a data element sequence, and appending a
//  continuation state. These mirror lib/sdp.c's private
//  gen_searchseq_pdu/gen_attridseq_pdu/copy_cstate — none of which are
//  part of the exported symbol surface, so they're reimplemented here
//  rather than linked against.
//

import CBluetoothLinuxABI
import BluetoothABI
import Glibc

/// BlueZ's private `sdp_cstate_t`:
/// `typedef struct { uint8_t length; unsigned char data[16]; } __attribute__((packed)) sdp_cstate_t;`
/// — internal to sdp.c, not part of any vendored header. All fields
/// are byte-sized, so this Swift struct's natural layout already
/// matches the packed C one with no padding to worry about.
internal struct SDPContinuationState {
    var length: UInt8
    var data: (UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8)
}

/// `static int copy_cstate(uint8_t *pdata, int pdata_len, const sdp_cstate_t *cstate)`
internal func copyContinuationState(_ destination: UnsafeMutableRawPointer, _ availableLength: Int, _ cstate: UnsafePointer<SDPContinuationState>?) -> Int32 {
    guard let cstate else {
        destination.assumingMemoryBound(to: UInt8.self).pointee = 0
        return 1
    }
    var length = cstate.pointee.length
    if Int(length) >= availableLength {
        length = UInt8(availableLength - 1)
    }
    let bytes = destination.assumingMemoryBound(to: UInt8.self)
    bytes.pointee = length
    _ = withUnsafeBytes(of: cstate.pointee.data) { source in
        memcpy(bytes + 1, source.baseAddress!, Int(length))
    }
    return Int32(length) + 1
}

/// A stable address for the (per-call, single-valued) data-type-descriptor
/// byte that `sdp_seq_alloc` expects one pointer-per-element to. BlueZ
/// reuses the address of one stack variable for every element; this
/// does the same, kept alive for the whole encode by running entirely
/// inside `withUnsafeMutablePointer`.
private func encodeSequence(
    dataType: UInt8,
    count: Int,
    elementValue: (_ index: Int) -> UnsafeMutableRawPointer?,
    into destination: UnsafeMutableRawPointer
) -> Int32 {
    guard count > 0 else { return -1 }
    var dtd = dataType
    return withUnsafeMutablePointer(to: &dtd) { dtdPointer -> Int32 in
        var dtds = [UnsafeMutableRawPointer?](repeating: nil, count: count)
        var values = [UnsafeMutableRawPointer?](repeating: nil, count: count)
        for index in 0 ..< count {
            dtds[index] = UnsafeMutableRawPointer(dtdPointer)
            values[index] = elementValue(index)
        }

        guard let sequence = dtds.withUnsafeMutableBufferPointer({ dtdBuffer in
            values.withUnsafeMutableBufferPointer { valueBuffer in
                sdp_seq_alloc(dtdBuffer.baseAddress, valueBuffer.baseAddress, Int32(count))
            }
        }) else { return -1 }
        defer { sdp_data_free(sequence) }

        // Scratch buffer for sdp_gen_pdu's write pass. The reference
        // pre-sizes this with sdp_gen_buffer (private, not exported);
        // since only the exact data_size sdp_gen_pdu reports back is
        // ever copied out, a generous flat over-estimate per element
        // is just as safe and much simpler for the flat (non-nested)
        // sequences built here — a UUID is at most 16 bytes, an
        // attribute ID at most 4, so 24 bytes/element plus the outer
        // sequence envelope leaves ample headroom.
        let scratchSize = count * 24 + 16
        guard let scratch = malloc(scratchSize) else { return -1 }
        defer { free(scratch) }

        var buf = sdp_buf_t()
        buf.data = scratch.assumingMemoryBound(to: UInt8.self)
        buf.buf_size = UInt32(scratchSize)

        let written = withUnsafeMutablePointer(to: &buf) { sdp_gen_pdu($0, sequence) }
        guard written >= 0 else { return -1 }

        memcpy(destination, buf.data, Int(buf.data_size))
        return written
    }
}

/// `static int gen_searchseq_pdu(uint8_t *dst, const sdp_list_t *seq)`
///
/// Every entry is a `uuid_t *`; the data type is the *first* entry's
/// UUID width (16/32/128-bit), applied uniformly — matching the
/// reference exactly, including not validating that the rest of the
/// list shares that width.
internal func genSearchSequencePDU(_ destination: UnsafeMutableRawPointer, _ search: UnsafePointer<sdp_list_t>?) -> Int32 {
    guard let search, let firstData = search.pointee.data else { return -1 }
    let dataType = firstData.assumingMemoryBound(to: uuid_t.self).pointee.type

    var count = 0
    var node: UnsafePointer<sdp_list_t>? = search
    while let n = node { count += 1; node = n.pointee.next.map { UnsafePointer($0) } }

    var nodes = [UnsafePointer<sdp_list_t>]()
    nodes.reserveCapacity(count)
    node = search
    while let n = node { nodes.append(n); node = n.pointee.next.map { UnsafePointer($0) } }

    // `value` is a union — ClangImporter exposes it as a computed
    // property, so `&uuid.pointee.value` would materialize a
    // temporary valid only for an immediate call. `uuid` itself is a
    // genuinely stable pointer (into the caller's list nodes, alive
    // for this whole synchronous call), so take its raw address and
    // advance by `value`'s known offset instead — safe to store in
    // `values` and dereference later when sdp_seq_alloc runs.
    let valueOffset = MemoryLayout<uuid_t>.offset(of: \.value)!
    return encodeSequence(dataType: dataType, count: count, elementValue: { index in
        let uuid = nodes[index].pointee.data!.assumingMemoryBound(to: uuid_t.self)
        return UnsafeMutableRawPointer(uuid).advanced(by: valueOffset)
    }, into: destination)
}

/// `static int gen_attridseq_pdu(uint8_t *dst, const sdp_list_t *seq, uint8_t dataType)`
///
/// Every entry's `data` pointer already points directly at a raw
/// `uint16_t` (individual attribute ID) or `uint32_t` (attribute ID
/// range), owned by the caller.
internal func genAttrIDSequencePDU(_ destination: UnsafeMutableRawPointer, _ attributeIDs: UnsafePointer<sdp_list_t>?, _ dataType: UInt8) -> Int32 {
    var count = 0
    var node: UnsafePointer<sdp_list_t>? = attributeIDs
    while let n = node { count += 1; node = n.pointee.next.map { UnsafePointer($0) } }

    var nodes = [UnsafePointer<sdp_list_t>]()
    nodes.reserveCapacity(count)
    node = attributeIDs
    while let n = node { nodes.append(n); node = n.pointee.next.map { UnsafePointer($0) } }

    return encodeSequence(dataType: dataType, count: count, elementValue: { index in
        nodes[index].pointee.data
    }, into: destination)
}

/// `static void extract_record_handle_seq(uint8_t *pdu, int bufsize, sdp_list_t **seq, int count, unsigned int *scanned)`
internal func extractRecordHandleSequence(_ pdu: UnsafePointer<UInt8>, _ bufferSize: Int, _ list: inout UnsafeMutablePointer<sdp_list_t>?, _ count: Int, _ scanned: inout UInt32) {
    var remaining = bufferSize
    var pointer = pdu
    for _ in 0 ..< count {
        guard remaining >= MemoryLayout<UInt32>.size else { break }
        guard let handle = malloc(MemoryLayout<UInt32>.size)?.assumingMemoryBound(to: UInt32.self) else { break }
        handle.pointee = pointer.withMemoryRebound(to: UInt8.self, capacity: 4) { bt_get_be32($0) }
        list = sdp_list_append(list, handle)
        pointer += 4
        scanned += 4
        remaining -= 4
    }
}
