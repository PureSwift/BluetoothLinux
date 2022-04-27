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
            
            let bufferSize = MemoryLayout<CInterop.RFCOMMDeviceListRequest>.size
                + (MemoryLayout<CInterop.RFCOMMDeviceInformation>.size * self.limit)
            
            let buffer = UnsafeMutablePointer<UInt8>.allocate(capacity: bufferSize)
            defer { buffer.deallocate() }
            
            buffer.withMemoryRebound(to: CInterop.RFCOMMDeviceListRequest.self, capacity: 1) {
                $0.pointee.count = numericCast(self.limit)
            }
            
            // call ioctl
            let result = try body(buffer)
            
            let resultCount = buffer.withMemoryRebound(to: CInterop.RFCOMMDeviceListRequest.self, capacity: 1) {
                Int($0.pointee.count)
            }
            
            self.response.removeAll(keepingCapacity: true)
            self.response.reserveCapacity(resultCount)
            
            for index in 0 ..< resultCount {
                let offset = MemoryLayout<CInterop.RFCOMMDeviceListRequest>.size + (MemoryLayout<CInterop.RFCOMMDeviceInformation>.size * index)
                buffer.advanced(by: offset).withMemoryRebound(to: CInterop.RFCOMMDeviceInformation.self, capacity: 1) {
                    let element = RFCOMMDevice($0.pointee)
                    self.response.append(element)
                }
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
