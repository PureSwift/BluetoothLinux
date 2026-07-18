//
//  Scan.swift
//  BluetoothLinux
//
//  Created by Alsey Coleman Miller on 12/6/15.
//  Copyright © 2015 PureSwift. All rights reserved.
//

import Foundation
import BluetoothHCI
@_implementationOnly import CBluetoothLinux
import SystemPackage
import Socket

// MARK: - Methods

public extension HostController {
    
    /// Scans for nearby Classic Bluetooth devices.
    ///
    /// - Parameter duration: The duration of the scan. The actual duration lasts for at most 1.28 * ``duration`` seconds
    ///
    /// - Parameter scanLimit: The maximum amount of devices to scan.
    ///
    /// - Parameter deviceClass: Device class to filter results by.
    ///
    /// - Parameter options: Array of ```ScanOption```.
    func scan(duration: Int = 8,
              limit: Int = 255,
              deviceClass: (UInt8, UInt8, UInt8)? = nil,
              options: ScanOption = []) throws -> [InquiryResult] {
        
        assert(duration > 0, "Scan must be longer than 0 seconds")
        assert(limit > 0, "Must scan at least one device")
        assert(limit <= 255, "Cannot be larger than UInt8.max")
        
        return try socket.fileDescriptor.inquiry(
            device: id,
            duration: UInt8(duration),
            limit: UInt8(limit),
            deviceClass: deviceClass,
            options: options
        )
    }
    
    /*
    /// Requests the remote device for its user-friendly name. 
    func requestDeviceName(deviceAddress: Address, timeout: Int = 0) throws -> String? {
        
        let maxNameLength = 248
        
        var address = bdaddr_t()
        
        let nameBuffer = UnsafeMutablePointer<CChar>.init(allocatingCapacity: maxNameLength)
        defer { nameBuffer.deallocateCapacity(maxNameLength) }
        
        guard hci_read_remote_name(internalSocket, &address, CInt(maxNameLength), nameBuffer, CInt(timeout)) == CInt(0)
            else { throw POSIXError.fromErrno() }
        
        let name = String.fromCString(nameBuffer)
        
        return name
    }*/
}

public extension HostController {
    
    /// Options for scanning Bluetooth devices
    struct ScanOption: OptionSet, Equatable, Hashable, Sendable {

        public let rawValue: UInt16

        public init(rawValue: UInt16) {
            self.rawValue = rawValue
        }

        /// The cache of previously detected devices is flushed before performing the current inquiry.
        /// Otherwise, if flags is set to 0, then the results of previous inquiries may be returned,
        /// even if the devices aren't in range anymore.
        public static let flushCache = ScanOption(rawValue: 0x0001)
    }
    
    struct InquiryResult {
        
        /// Device Address
        public let address: BluetoothAddress
        
        public let pscanRepMode: UInt8
        
        public let pscanPeriodMode: UInt8
        
        public let pscanMode: UInt8
        
        public let deviceClass: (UInt8, UInt8, UInt8)
        
        public let clockOffset: UInt16
    }
}

// MARK: - IOCTL

public extension HostControllerIO {
    
    struct Inquiry: IOControlValue {
        
        @_alwaysEmitIntoClient
        public static var id: HostControllerIO { .inquiry }
        
        public var device: HostController.ID
        
        public var duration: UInt8
        
        public var limit: UInt8
        
        public var deviceClass: (UInt8, UInt8, UInt8)?
        
        public var options: HostController.ScanOption
        
        public private(set) var response: [HostController.InquiryResult]
        
        public init(
            device: HostController.ID,
            duration: UInt8 = 8,
            limit: UInt8 = 255,
            deviceClass: (UInt8, UInt8, UInt8)? = nil,
            options: HostController.ScanOption = []
        ) {
            self.device = device
            self.duration = duration
            self.limit = limit
            self.deviceClass = deviceClass
            self.options = options
            self.response = []
        }
        
        public mutating func withUnsafeMutablePointer<Result>(_ body: (UnsafeMutableRawPointer) throws -> (Result)) rethrows -> Result {

            // The kernel writes inquiry results at `sizeof(struct hci_inquiry_req)`,
            // which is the stride (10), not the Swift size (9, tail padding excluded).
            let headerSize = MemoryLayout<CInterop.HCIInquiryRequest>.stride
            let elementSize = MemoryLayout<CInterop.HCIInquiryResult>.stride
            let bufferSize = headerSize + (elementSize * Int(limit))

            let buffer = UnsafeMutableRawPointer.allocate(
                byteCount: bufferSize,
                alignment: MemoryLayout<CInterop.HCIInquiryRequest>.alignment
            )
            defer { buffer.deallocate() }
            buffer.initializeMemory(as: UInt8.self, repeating: 0, count: bufferSize)

            let request = buffer.bindMemory(to: CInterop.HCIInquiryRequest.self, capacity: 1)
            request.pointee.id = self.device.rawValue
            request.pointee.lap = self.deviceClass ?? (0x33, 0x8b, 0x9e)
            request.pointee.flags = self.options.rawValue
            request.pointee.responseCount = self.limit
            request.pointee.length = self.duration

            // call ioctl
            let result = try body(buffer)

            let resultCount = Int(request.pointee.responseCount)

            self.response.removeAll(keepingCapacity: true)
            self.response.reserveCapacity(resultCount)

            for index in 0 ..< resultCount {
                let offset = headerSize + (elementSize * index)
                let bytes = buffer.loadUnaligned(fromByteOffset: offset, as: CInterop.HCIInquiryResult.self)
                let element = HostController.InquiryResult(
                    address: bytes.address,
                    pscanRepMode: bytes.pscanRepMode,
                    pscanPeriodMode: bytes.pscanPeriodMode,
                    pscanMode: bytes.pscanMode,
                    deviceClass: bytes.deviceClass,
                    clockOffset: bytes.clockOffset
                )
                self.response.append(element)
            }

            return result
        }
    }
}

// MARK: - File Descriptor

internal extension SocketDescriptor {
    
    @usableFromInline
    func inquiry(
        device id: HostController.ID,
        duration: UInt8 = 8,
        limit: UInt8 = 255,
        deviceClass: (UInt8, UInt8, UInt8)? = nil,
        options: HostController.ScanOption = []
    ) throws -> [HostController.InquiryResult] {
        var inquiry = HostControllerIO.Inquiry(
            device: id,
            duration: duration,
            limit: limit,
            deviceClass: deviceClass,
            options: options
        )
        try inputOutput(&inquiry)
        return inquiry.response
    }
}
