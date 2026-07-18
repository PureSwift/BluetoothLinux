//
//  BNEPGetConnectionList.swift
//  BluetoothLinux
//

import Bluetooth
import SystemPackage
import Socket

public extension BNEPIO {

    /// BNEP Get Connection List
    struct GetConnectionList: IOControlValue {

        @_alwaysEmitIntoClient
        public static var id: BNEPIO { .getConnectionList }

        @_alwaysEmitIntoClient
        public static var maxLimit: Int { 256 }

        public var limit: Int

        public private(set) var response: [BNEPConnection]

        public init(limit: Int = Self.maxLimit) {
            precondition(limit > 0, "Must request at least one connection")
            precondition(limit <= Self.maxLimit, "Only \(Self.maxLimit) maximum connections is allowed")
            self.limit = limit
            self.response = []
        }

        public mutating func withUnsafeMutablePointer<Result>(_ body: (UnsafeMutableRawPointer) throws -> (Result)) rethrows -> Result {

            // Unlike other list requests, `struct bnep_connlist_req` embeds a
            // pointer to a caller-allocated `bnep_conninfo` array rather than a
            // flexible array member.
            let limit = self.limit
            var connections = [CInterop.BNEPConnectionInformation](
                repeating: CInterop.BNEPConnectionInformation(
                    flags: 0,
                    role: 0,
                    state: 0,
                    destination: .zero
                ),
                count: limit
            )
            var count: UInt32 = 0
            let result: Result = try connections.withUnsafeMutableBufferPointer { buffer in
                var request = CInterop.BNEPConnectionListRequest(
                    count: UInt32(limit),
                    connections: buffer.baseAddress
                )
                let result = try Swift.withUnsafeMutableBytes(of: &request) { requestBuffer in
                    try body(requestBuffer.baseAddress!)
                }
                count = request.count
                return result
            }
            self.response = connections
                .prefix(Int(min(count, UInt32(limit))))
                .map { BNEPConnection($0) }
            return result
        }
    }
}

// MARK: - File Descriptor

internal extension SocketDescriptor {

    @usableFromInline
    func bnepConnectionList(
        limit: Int = BNEPIO.GetConnectionList.maxLimit
    ) throws -> [BNEPConnection] {
        var request = BNEPIO.GetConnectionList(limit: limit)
        try inputOutput(&request)
        return request.response
    }
}
