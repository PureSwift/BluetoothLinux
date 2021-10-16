//
//  Darwin.swift
//  BluetoothLinux
//
//  Created by Alsey Coleman Miller on 2/28/16.
//  Copyright © 2016 PureSwift. All rights reserved.
//

import SystemPackage

#if !os(Linux)
#warning("This module will only run on Linux")
internal func stub(function: StaticString = #function) -> Never {
    fatalError("\(function) not implemented. This code only runs on Linux.")
}

internal extension SocketAddressFamily {
    
    @usableFromInline
    static var bluetooth: SocketAddressFamily { stub() }
}

internal extension FileDescriptor {
    static func socket<T: SocketProtocol>(
        _ protocolID: T,
        flags: SocketFlags,
        retryOnInterrupt: Bool = true
    ) throws -> FileDescriptor {
        stub()
    }
}

internal struct SocketFlags: OptionSet, Hashable, Codable {
    
    /// The raw C file events.
    @_alwaysEmitIntoClient
    public let rawValue: CInt

    /// Create a strongly-typed file events from a raw C value.
    @_alwaysEmitIntoClient
    public init(rawValue: CInt) { self.rawValue = rawValue }

    @_alwaysEmitIntoClient
    private init(_ raw: CInt) { self.init(rawValue: numericCast(raw)) }
}

extension SocketFlags {
    
    /// Set the `O_NONBLOCK` file status flag on the open file description referred to by the new file
    /// descriptor.  Using this flag saves extra calls to `fcntl()` to achieve the same result.
    static var nonBlocking: SocketFlags { stub() }
    
    /// Set the close-on-exec (`FD_CLOEXEC`) flag on the new file descriptor.
    static var closeOnExec: SocketFlags { stub() }
}

#endif

#if os(Android)
#warning("Android does not use BlueZ kernel module")
#endif
