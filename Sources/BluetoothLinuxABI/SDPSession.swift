//
//  SDPSession.swift
//  BluetoothLinux
//
//  The SDP client session lifecycle: creating a session over an
//  existing socket, connecting (over L2CAP to a remote device, or a
//  local Unix-domain socket to a local SDP server), closing it, and
//  the small per-session bookkeeping (transaction ID, last error,
//  async notification callback).
//
//  `sdp_session_t` is a plain, non-opaque struct (see the vendored
//  sdp_lib.h) — some callers do read its fields directly rather than
//  going through sdp_get_socket, so this keeps them populated with
//  real values rather than treating the struct as opaque.
//
//  The one piece of state the public struct *doesn't* hold —
//  `session->priv`, BlueZ's `struct sdp_transaction` — is private to
//  sdp.c and not part of any vendored header. It's reimplemented here
//  as SDPTransaction: the async callback/userdata, the outstanding
//  request buffer (kept around so a continuation-state follow-up can
//  resend it with a new transaction ID), and a growable buffer that
//  concatenates a response split across multiple continuation-state
//  fragments.
//
//  None of this has been exercised against a real or virtual SDP
//  server; see HCIDevice.swift's note on hci_send_cmd/hci_send_req for
//  the same caveat applying here.
//

import CBluetoothLinuxABI
import BluetoothABI
import Glibc

// MARK: - Transaction state (BlueZ's private `struct sdp_transaction`)

internal struct SDPTransaction {
    var callback: sdp_callback_t?
    var userData: UnsafeMutableRawPointer?
    var requestBuffer: UnsafeMutableRawPointer?
    var requestSize: UInt32 = 0
    var responseBuffer: sdp_buf_t = sdp_buf_t()
    var error: Int32 = 0
}

// SDP_MAX_ATTR_LEN and SDP_LARGE_L2CAP_MTU — defined locally in
// BlueZ's sdp.c, not in any vendored header.
internal let sdpMaxAttrLength: UInt16 = 65535
private let sdpLargeL2CAPMTU: UInt16 = 1013

internal func sdpTransaction(_ session: UnsafeMutablePointer<sdp_session_t>) -> UnsafeMutablePointer<SDPTransaction>? {
    session.pointee.priv?.assumingMemoryBound(to: SDPTransaction.self)
}

// MARK: - Session lifecycle

/// `sdp_session_t *sdp_create(int sk, uint32_t flags)`
@c(sdp_create)
public func sdp_create(_ socket: Int32, _ flags: UInt32) -> UnsafeMutablePointer<sdp_session_t>? {
    guard let session = bt_malloc0(MemoryLayout<sdp_session_t>.size)?.assumingMemoryBound(to: sdp_session_t.self) else {
        errno = ENOMEM
        return nil
    }
    session.pointee.flags = Int32(bitPattern: flags)
    session.pointee.sock = socket

    let transaction = UnsafeMutablePointer<SDPTransaction>.allocate(capacity: 1)
    transaction.initialize(to: SDPTransaction())
    session.pointee.priv = UnsafeMutableRawPointer(transaction)

    return session
}

/// `int sdp_close(sdp_session_t *session)`
@c(sdp_close)
public func sdp_close(_ session: UnsafeMutablePointer<sdp_session_t>?) -> Int32 {
    guard let session else { return -1 }
    let result = close(session.pointee.sock)
    if let transaction = sdpTransaction(session) {
        free(transaction.pointee.requestBuffer)
        free(transaction.pointee.responseBuffer.data)
        transaction.deinitialize(count: 1)
        transaction.deallocate()
    }
    free(session)
    return result
}

private func sdpIsLocal(_ device: UnsafePointer<bdaddr_t>) -> Bool {
    var local = bdaddr_t(b: (0, 0, 0, 0xff, 0xff, 0xff))
    return bacmp(device, &local) == 0
}

private func sdpConnectLocal(_ session: UnsafeMutablePointer<sdp_session_t>) -> Int32 {
    let sock = socket(Int32(AF_UNIX), Int32(SOCK_STREAM.rawValue) | Int32(SOCK_CLOEXEC.rawValue), 0)
    guard sock >= 0 else { return -1 }
    session.pointee.sock = sock
    session.pointee.local = 1

    var address = sockaddr_un()
    address.sun_family = sa_family_t(AF_UNIX)
    let path = "/var/run/sdp"
    withUnsafeMutableBytes(of: &address.sun_path) { buffer in
        path.utf8CString.withUnsafeBytes { source in
            buffer.copyMemory(from: UnsafeRawBufferPointer(start: source.baseAddress, count: source.count))
        }
    }

    return withUnsafePointer(to: &address) { pointer -> Int32 in
        pointer.withMemoryRebound(to: sockaddr.self, capacity: 1) { sockaddrPointer in
            connect(sock, sockaddrPointer, socklen_t(MemoryLayout<sockaddr_un>.size))
        }
    }
}

private func setL2CAPMTU(_ sock: Int32, _ mtu: UInt16) -> Int32 {
    var options = l2cap_options()
    var length = socklen_t(MemoryLayout<l2cap_options>.size)
    guard getsockopt(sock, Int32(SOL_L2CAP), Int32(L2CAP_OPTIONS), &options, &length) >= 0 else { return -1 }
    options.imtu = mtu
    options.omtu = mtu
    return setsockopt(sock, Int32(SOL_L2CAP), Int32(L2CAP_OPTIONS), &options, socklen_t(MemoryLayout<l2cap_options>.size))
}

private func sdpConnectL2CAP(_ source: UnsafePointer<bdaddr_t>, _ destination: UnsafePointer<bdaddr_t>, _ session: UnsafeMutablePointer<sdp_session_t>) -> Int32 {
    let flags = UInt32(bitPattern: session.pointee.flags)
    var socketFlags = Int32(SOCK_SEQPACKET.rawValue) | Int32(SOCK_CLOEXEC.rawValue)
    if flags & UInt32(SDP_NON_BLOCKING) != 0 {
        socketFlags |= Int32(SOCK_NONBLOCK.rawValue)
    }

    let sock = socket(Int32(AF_BLUETOOTH), socketFlags, Int32(BTPROTO_L2CAP))
    guard sock >= 0 else { return -1 }
    session.pointee.sock = sock
    session.pointee.local = 0

    var address = sockaddr_l2()
    address.l2_family = sa_family_t(AF_BLUETOOTH)
    address.l2_psm = 0

    var anyAddress = bdaddr_t(b: (0, 0, 0, 0, 0, 0))
    if bacmp(source, &anyAddress) != 0 {
        address.l2_bdaddr = source.pointee
        let bindResult = withUnsafePointer(to: &address) { pointer -> Int32 in
            pointer.withMemoryRebound(to: sockaddr.self, capacity: 1) { bind(sock, $0, socklen_t(MemoryLayout<sockaddr_l2>.size)) }
        }
        guard bindResult >= 0 else { return -1 }
    }

    if flags & UInt32(SDP_WAIT_ON_CLOSE) != 0 {
        var lingerOption = linger(l_onoff: 1, l_linger: 1)
        guard setsockopt(sock, Int32(SOL_SOCKET), SO_LINGER, &lingerOption, socklen_t(MemoryLayout<linger>.size)) >= 0 else { return -1 }
    }

    if flags & UInt32(SDP_LARGE_MTU) != 0, setL2CAPMTU(sock, sdpLargeL2CAPMTU) < 0 {
        return -1
    }

    address.l2_psm = UInt16(SDP_PSM)
    address.l2_bdaddr = destination.pointee

    repeat {
        let result = withUnsafePointer(to: &address) { pointer -> Int32 in
            pointer.withMemoryRebound(to: sockaddr.self, capacity: 1) { connect(sock, $0, socklen_t(MemoryLayout<sockaddr_l2>.size)) }
        }
        if result == 0 { return 0 }
        if result < 0, flags & UInt32(SDP_NON_BLOCKING) != 0, (errno == EAGAIN || errno == EINPROGRESS) {
            return 0
        }
    } while errno == EBUSY && flags & UInt32(SDP_RETRY_IF_BUSY) != 0

    return -1
}

/// `sdp_session_t *sdp_connect(const bdaddr_t *src, const bdaddr_t *dst, uint32_t flags)`
@c(sdp_connect)
public func sdp_connect(_ source: UnsafePointer<bdaddr_t>?, _ destination: UnsafePointer<bdaddr_t>?, _ flags: UInt32) -> UnsafeMutablePointer<sdp_session_t>? {
    guard let source, let destination else { errno = EINVAL; return nil }
    if flags & UInt32(SDP_RETRY_IF_BUSY) != 0, flags & UInt32(SDP_NON_BLOCKING) != 0 {
        errno = EINVAL
        return nil
    }

    guard let session = sdp_create(-1, flags) else { return nil }

    let connected: Int32
    if sdpIsLocal(destination) {
        connected = sdpConnectLocal(session)
    } else {
        connected = sdpConnectL2CAP(source, destination, session)
    }

    guard connected >= 0 else {
        let savedError = errno
        if session.pointee.sock >= 0 { close(session.pointee.sock) }
        free(session.pointee.priv)
        free(session)
        errno = savedError
        return nil
    }

    return session
}

/// `int sdp_get_socket(const sdp_session_t *session)`
@c(sdp_get_socket)
public func sdp_get_socket(_ session: UnsafePointer<sdp_session_t>?) -> Int32 {
    session?.pointee.sock ?? -1
}

/// `uint16_t sdp_gen_tid(sdp_session_t *session)`
@c(sdp_gen_tid)
public func sdp_gen_tid(_ session: UnsafeMutablePointer<sdp_session_t>?) -> UInt16 {
    guard let session else { return 0 }
    let tid = session.pointee.tid
    session.pointee.tid &+= 1
    return tid
}

/// `int sdp_get_error(sdp_session_t *session)`
@c(sdp_get_error)
public func sdp_get_error(_ session: UnsafeMutablePointer<sdp_session_t>?) -> Int32 {
    guard let session, let transaction = sdpTransaction(session) else { return -1 }
    return transaction.pointee.error
}

/// `int sdp_set_notify(sdp_session_t *session, sdp_callback_t *func, void *udata)`
@c(sdp_set_notify)
public func sdp_set_notify(_ session: UnsafeMutablePointer<sdp_session_t>?, _ callback: sdp_callback_t?, _ userData: UnsafeMutableRawPointer?) -> Int32 {
    guard let session, let transaction = sdpTransaction(session) else { return -1 }
    transaction.pointee.callback = callback
    transaction.pointee.userData = userData
    return 0
}

/// `int sdp_general_inquiry(inquiry_info *ii, int num_dev, int duration, uint8_t *found)`
@c(sdp_general_inquiry)
public func sdp_general_inquiry(_ inquiryInfo: UnsafeMutablePointer<inquiry_info>?, _ numberOfDevices: Int32, _ duration: Int32, _ found: UnsafeMutablePointer<UInt8>?) -> Int32 {
    guard let found else { errno = EINVAL; return -1 }
    var results = inquiryInfo
    let count = withUnsafeMutablePointer(to: &results) { hci_inquiry(-1, 10, numberOfDevices, nil, $0, 0) }
    guard count >= 0 else { return -1 }
    found.pointee = UInt8(truncatingIfNeeded: count)
    return 0
}

// MARK: - Wire I/O

/// `static int sdp_send_req(sdp_session_t *session, uint8_t *buf, uint32_t size)`
internal func sdpSendRequest(_ session: UnsafeMutablePointer<sdp_session_t>, _ buffer: UnsafeRawPointer, _ size: Int) -> Int32 {
    var sent = 0
    while sent < size {
        let n = send(session.pointee.sock, buffer.advanced(by: sent), size - sent, 0)
        guard n >= 0 else { return -1 }
        sent += n
    }
    return 0
}

/// `static int sdp_read_rsp(sdp_session_t *session, uint8_t *buf, uint32_t size)`
///
/// FD_ZERO/FD_SET are C macros (not imported); this sets the single
/// descriptor's bit directly instead.
internal func sdpReadResponse(_ session: UnsafeMutablePointer<sdp_session_t>, _ buffer: UnsafeMutableRawPointer, _ size: Int) -> Int {
    let sock = session.pointee.sock
    var readSet = fd_set()
    withUnsafeMutableBytes(of: &readSet) { raw -> Void in
        raw.initializeMemory(as: UInt8.self, repeating: 0)
        let index = Int(sock) / (MemoryLayout<Int>.size * 8)
        let bit = Int(sock) % (MemoryLayout<Int>.size * 8)
        let longs = raw.bindMemory(to: Int.self)
        longs[index] |= (1 << bit)
    }

    var timeout = timeval(tv_sec: __time_t(SDP_RESPONSE_TIMEOUT), tv_usec: 0)
    let ready = withUnsafeMutablePointer(to: &readSet) { setPointer -> Int32 in
        select(sock + 1, setPointer, nil, nil, &timeout)
    }
    guard ready != 0 else {
        errno = ETIMEDOUT
        return -1
    }
    return recv(sock, buffer, size, 0)
}
