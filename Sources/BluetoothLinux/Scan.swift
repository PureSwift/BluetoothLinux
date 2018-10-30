//
//  Scan.swift
//  BluetoothLinux
//
//  Created by Alsey Coleman Miller on 12/6/15.
//  Copyright © 2015 PureSwift. All rights reserved.
//

#if os(Linux)
    import Glibc
#elseif os(macOS) || os(iOS)
    import Darwin.C
#endif

import Foundation
import Bluetooth
import CSwiftBluetoothLinux

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
              deviceClass: DeviceClass? = nil,
              options: BitMaskOptionSet<ScanOption> = []) throws -> [InquiryResult] {
        
        assert(duration > 0, "Scan must be longer than 0 seconds")
        assert(limit > 0, "Must scan at least one device")
        assert(limit <= 255, "Cannot be larger than UInt8.max")
        
        let flags = options.rawValue
        
        return try HCIInquiry(identifier,
                              duration: UInt8(duration),
                              scanLimit: UInt8(limit),
                              deviceClass: deviceClass,
                              flags: UInt16(flags))
    }
    
    /*
    /// Requests the remote device for its user-friendly name. 
    func requestDeviceName(deviceAddress: Address, timeout: Int = 0) throws -> String? {
        
        let maxNameLength = 248
        
        var address = bdaddr_t()
        
        let nameBuffer = UnsafeMutablePointer<CChar>.init(allocatingCapacity: maxNameLength)
        defer { nameBuffer.deallocateCapacity(maxNameLength) }
        
        guard hci_read_remote_name(internalSocket, &address, CInt(maxNameLength), nameBuffer, CInt(timeout)) == CInt(0)
            else { throw POSIXError.fromErrno! }
        
        let name = String.fromCString(nameBuffer)
        
        return name
    }*/
}

// MARK: - Supporting Types

public extension HostController {
    
    public typealias DeviceClass = (UInt8, UInt8, UInt8)
    
    /// Options for scanning Bluetooth devices
    public enum ScanOption: Int32, BitMaskOption {
        
        /// The cache of previously detected devices is flushed before performing the current inquiry. 
        /// Otherwise, if flags is set to 0, then the results of previous inquiries may be returned, 
        /// even if the devices aren't in range anymore.
        case flushCache = 0x0001
        
        public static let all: Set<ScanOption> = [.flushCache]
        
        public typealias RawValue = Int32
    }
    
    public struct InquiryResult {
        
        /// Device Address
        public var address = Address()
        
        public var pscanRepMode: UInt8 = 0
        
        public var pscanPeriodMode: UInt8 = 0
        
        public var pscanMode: UInt8 = 0
        
        public var deviceClass: DeviceClass = (0, 0, 0)
        
        public var clockOffset: UInt16 = 0
    }
}

// MARK: - Internal HCI Functions

internal func HCIInquiry(_ deviceIdentifier: UInt16,
                         duration: UInt8,
                         scanLimit: UInt8,
                         deviceClass: HostController.DeviceClass? = nil,
                         flags: UInt16) throws -> [HostController.InquiryResult] {
    
    typealias InquiryResult = HostController.InquiryResult
    
    let deviceDescriptor = socket(AF_BLUETOOTH, SOCK_RAW | SOCK_CLOEXEC, BluetoothProtocol.hci.rawValue)
    
    guard deviceDescriptor >= 0 else { throw POSIXError.fromErrno! }
    
    defer { close(deviceDescriptor) }
    
    let bufferSize = MemoryLayout<HCIInquiryRequest>.size + (MemoryLayout<InquiryResult>.size * Int(scanLimit))
    
    let buffer = UnsafeMutablePointer<UInt8>.allocate(capacity: bufferSize)
    
    defer { buffer.deallocate() }
    
    let deviceClass = deviceClass ?? (0x33, 0x8b, 0x9e)
    
    buffer.withMemoryRebound(to: HCIInquiryRequest.self, capacity: 1) { (inquiryRequest) in
        
        inquiryRequest.pointee.identifier = deviceIdentifier
        inquiryRequest.pointee.responseCount = scanLimit
        inquiryRequest.pointee.length = duration
        inquiryRequest.pointee.flags = flags
        inquiryRequest.pointee.lap = deviceClass
        return
    }
    
    guard IOControl(deviceDescriptor, HCI.IOCTL.Inquiry, UnsafeMutableRawPointer(buffer) ) >= 0
        else { throw POSIXError.fromErrno! }
    
    let resultCount = buffer.withMemoryRebound(to: HCIInquiryRequest.self, capacity: 1) { (inquiryRequest) in
        Int(inquiryRequest.pointee.responseCount)
    }
    
    let resultBufferSize = MemoryLayout<InquiryResult>.size * resultCount
    
    var results = [InquiryResult](repeating: InquiryResult(), count: resultCount)
    
    memcpy(&results, buffer.advanced(by: MemoryLayout<HCIInquiryRequest>.size), resultBufferSize)
    
    return results
}

