//
//  RFCOMMGetDeviceList.swift
//  
//
//  Created by Alsey Coleman Miller on 27/10/21.
//

import Bluetooth
import SystemPackage
import Socket

public extension RFCOMMIO {
    
    /// RFCOMM Get Device List
    struct GetDeviceList: Equatable, Hashable, IOControlValue {
        
        @_alwaysEmitIntoClient
        public static var id: RFCOMMIO { .getDeviceList }
        
        @_alwaysEmitIntoClient
        public static var maxLimit: Int { 256 }
        
        public var limit: Int
        
        public private(set) var response: [RFCOMMDevice]
        
        public init(limit: Int = Self.maxLimit) {
            precondition(limit <= Self.maxLimit, "Only \(Self.maxLimit) maximum devices is allowed")
            self.limit = limit
            self.response = []
        }
        
        public mutating func withUnsafeMutablePointer<Result>(_ body: (UnsafeMutableRawPointer) throws -> (Result)) rethrows -> Result {

            // The kernel's `struct rfcomm_dev_list_req` places the flexible
            // `dev_info[]` array at the C struct size, i.e. the 2-byte count
            // padded up to the element alignment (4), not the Swift size (2).
            let elementAlignment = MemoryLayout<CInterop.RFCOMMDeviceInformation>.alignment
            let headerSize = (MemoryLayout<CInterop.RFCOMMDeviceListRequest>.size + elementAlignment - 1)
                & ~(elementAlignment - 1)
            let elementSize = MemoryLayout<CInterop.RFCOMMDeviceInformation>.stride
            let bufferSize = headerSize + (elementSize * self.limit)

            let buffer = UnsafeMutableRawPointer.allocate(
                byteCount: bufferSize,
                alignment: elementAlignment
            )
            defer { buffer.deallocate() }
            buffer.initializeMemory(as: UInt8.self, repeating: 0, count: bufferSize)

            let request = buffer.bindMemory(to: CInterop.RFCOMMDeviceListRequest.self, capacity: 1)
            request.pointee.count = numericCast(self.limit)

            // call ioctl
            let result = try body(buffer)

            let resultCount = Int(request.pointee.count)

            self.response.removeAll(keepingCapacity: true)
            self.response.reserveCapacity(resultCount)

            for index in 0 ..< resultCount {
                let offset = headerSize + (elementSize * index)
                let bytes = buffer.loadUnaligned(fromByteOffset: offset, as: CInterop.RFCOMMDeviceInformation.self)
                self.response.append(RFCOMMDevice(bytes))
            }

            return result
        }
    }
}

// MARK: - File Descriptor

internal extension SocketDescriptor {
    
    @usableFromInline
    func rfcommListDevices(
        limit: Int = RFCOMMIO.GetDeviceList.maxLimit
    ) throws -> [RFCOMMDevice] {
        var request = RFCOMMIO.GetDeviceList(limit: limit)
        try inputOutput(&request)
        return request.response
    }
}
