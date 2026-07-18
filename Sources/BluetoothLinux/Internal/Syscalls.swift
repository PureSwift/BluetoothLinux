//
//  Syscalls.swift
//  BluetoothLinux
//
//  Mockable syscall shims, modeled after Swift System's
//  `Sources/System/Internals/Syscalls.swift`.
//
//  Every direct syscall this package makes should go through a `system_`
//  wrapper here so unit tests can intercept it via `MockingDriver`
//  (see Mocking.swift). In release builds these compile down to the
//  plain syscall.
//

import SystemPackage

#if canImport(Glibc)
import Glibc
#elseif canImport(Darwin)
import Darwin
#endif

// ioctl
internal func system_ioctl(
    _ fd: CInt,
    _ request: CUnsignedLong
) -> CInt {
    #if ENABLE_MOCKING
    if mockingEnabled { return _mockIOCTL(fd, request, nil, arguments: [fd, request]) }
    #endif
    return ioctl(fd, request)
}

// ioctl
internal func system_ioctl(
    _ fd: CInt,
    _ request: CUnsignedLong,
    _ value: CInt
) -> CInt {
    #if ENABLE_MOCKING
    if mockingEnabled { return _mockIOCTL(fd, request, nil, arguments: [fd, request, value]) }
    #endif
    return ioctl(fd, request, value)
}

// ioctl
internal func system_ioctl(
    _ fd: CInt,
    _ request: CUnsignedLong,
    _ pointer: UnsafeMutableRawPointer
) -> CInt {
    #if ENABLE_MOCKING
    if mockingEnabled { return _mockIOCTL(fd, request, pointer, arguments: [fd, request]) }
    #endif
    return ioctl(fd, request, pointer)
}

/// Run a syscall returning `-1` on failure, mapping the result into
/// `Result<(), Errno>` and retrying on `EINTR` if requested.
internal func nothingOrErrno(
    retryOnInterrupt: Bool,
    _ syscall: () -> CInt
) -> Result<(), Errno> {
    repeat {
        switch syscall() {
        case -1:
            let error = Errno(rawValue: errno)
            guard retryOnInterrupt && error == .interrupted else {
                return .failure(error)
            }
        default:
            return .success(())
        }
    } while true
}
