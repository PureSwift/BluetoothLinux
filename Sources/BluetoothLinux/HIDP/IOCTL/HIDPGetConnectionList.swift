//
//  HIDPGetConnectionList.swift
//  BluetoothLinux
//

import Bluetooth
import SystemPackage
import Socket

public extension HIDPIO {

    /// HIDP Get Connection List
    struct GetConnectionList: IOControlValue {

        @_alwaysEmitIntoClient
        public static var id: HIDPIO { .getConnectionList }

        @_alwaysEmitIntoClient
        public static var maxLimit: Int { 256 }

        public var limit: Int

        public private(set) var response: [HIDPConnection]

        public init(limit: Int = Self.maxLimit) {
            precondition(limit > 0, "Must request at least one connection")
            precondition(limit <= Self.maxLimit, "Only \(Self.maxLimit) maximum connections is allowed")
            self.limit = limit
            self.response = []
        }

        public mutating func withUnsafeMutablePointer<Result>(_ body: (UnsafeMutableRawPointer) throws -> (Result)) rethrows -> Result {

            // `struct hidp_connlist_req` embeds a pointer to a caller-allocated
            // `hidp_conninfo` array rather than a flexible array member.
            let limit = self.limit
            var connections = [CInterop.HIDPConnectionInformation](
                repeating: CInterop.HIDPConnectionInformation(),
                count: limit
            )
            var count: UInt32 = 0
            let result: Result = try connections.withUnsafeMutableBufferPointer { buffer in
                var request = CInterop.HIDPConnectionListRequest(
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
                .map { HIDPConnection($0) }
            return result
        }
    }
}

// MARK: - File Descriptor

internal extension SocketDescriptor {

    @usableFromInline
    func hidpConnectionList(
        limit: Int = HIDPIO.GetConnectionList.maxLimit
    ) throws -> [HIDPConnection] {
        var request = HIDPIO.GetConnectionList(limit: limit)
        try inputOutput(&request)
        return request.response
    }
}
