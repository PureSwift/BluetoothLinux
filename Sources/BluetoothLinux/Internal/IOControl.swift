//
//  IOControl.swift
//  BluetoothLinux
//
//  Internal `ioctl` entry points for this package. These intentionally
//  shadow `Socket.SocketDescriptor.inputOutput` (same signatures) so that
//  every unqualified `inputOutput` call in this module resolves here and
//  routes through the mockable `system_ioctl` shim (see Syscalls.swift),
//  allowing unit tests to intercept ioctl calls via `MockingDriver`.
//

import SystemPackage
import Socket

internal extension SocketDescriptor {

    /// Manipulates the underlying device parameters of special files.
    @usableFromInline
    func inputOutput<T: IOControlID>(
        _ request: T,
        retryOnInterrupt: Bool = true
    ) throws(Errno) {
        try nothingOrErrno(retryOnInterrupt: retryOnInterrupt) {
            system_ioctl(rawValue, request.rawValue)
        }.get()
    }

    /// Manipulates the underlying device parameters of special files.
    @usableFromInline
    func inputOutput<T: IOControlInteger>(
        _ request: T,
        retryOnInterrupt: Bool = true
    ) throws(Errno) {
        try nothingOrErrno(retryOnInterrupt: retryOnInterrupt) {
            system_ioctl(rawValue, T.id.rawValue, request.intValue)
        }.get()
    }

    /// Manipulates the underlying device parameters of special files.
    @usableFromInline
    func inputOutput<T: IOControlValue>(
        _ request: inout T,
        retryOnInterrupt: Bool = true
    ) throws(Errno) {
        try nothingOrErrno(retryOnInterrupt: retryOnInterrupt) {
            request.withUnsafeMutablePointer { pointer in
                system_ioctl(rawValue, T.id.rawValue, pointer)
            }
        }.get()
    }
}
