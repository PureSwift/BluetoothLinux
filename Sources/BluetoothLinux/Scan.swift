//
//  Scan.swift
//  BluetoothLinux
//
//  Created by Alsey Coleman Miller on 12/6/15.
//  Copyright © 2015 PureSwift. All rights reserved.
//

#if os(Linux)
    import Glibc
    import CSwiftBluetoothLinux
#elseif os(OSX) || os(iOS)
    import Darwin.C
#endif

import SwiftFoundation
import Bluetooth

// MARK: - Methods

public extension Adapter {
    
    /// Scans for nearby Bluetooth devices.
    ///
    /// - Parameter duration: The duration of the scan. The actual duration lasts for at most 1.28 * ``duration`` seconds
    ///
    /// - Parameter scanLimit: The maximum amount of devices to scan.
    ///
    /// - Parameter deviceClass: Device class to filter results by.
    ///
    /// - Parameter options: Array of ```ScanOption```.
    func scan(duration: Int = 8, scanLimit: Int = 255, deviceClass: DeviceClass? = nil, options: [ScanOption] = []) throws -> [InquiryResult] {
        
        assert(duration > 0, "Scan must be longer than 0 seconds")
        assert(scanLimit > 0, "Must scan at least one device")
        assert(scanLimit <= 255, "Cannot be larger than UInt8.max")
        
        let flags = options.optionsBitmask()
        
        return try HCIInquiry(identifier, duration: duration, scanLimit: scanLimit, deviceClass: deviceClass, flags: flags)
    }
    
    /*
    /// Requests the remote device for its user-friendly name. 
    func requestDeviceName(deviceAddress: Address, timeout: Int = 0) throws -> String? {
        
        let maxNameLength = 248
        
        var address = bdaddr_t()
        
        let nameBuffer = UnsafeMutablePointer<CChar>.alloc(maxNameLength)
        defer { nameBuffer.dealloc(maxNameLength) }
        
        guard hci_read_remote_name(internalSocket, &address, CInt(maxNameLength), nameBuffer, CInt(timeout)) == CInt(0)
            else { throw POSIXError.fromErrorNumber! }
        
        let name = String.fromCString(nameBuffer)
        
        return name
    }*/
}

// MARK: - Supporting Types

public extension Adapter {
    
    public typealias DeviceClass = (Byte, Byte, Byte)
    
    /// Options for scanning Bluetooth devices
    public enum ScanOption: Int32, BitMaskOption {
        
        /// The cache of previously detected devices is flushed before performing the current inquiry. 
        /// Otherwise, if flags is set to 0, then the results of previous inquiries may be returned, 
        /// even if the devices aren't in range anymore.
        case FlushCache = 0x0001
        
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

internal func HCIInquiry(deviceIdentifier: CInt, duration: Int, scanLimit: Int, deviceClass: Adapter.DeviceClass? = nil, flags: CInt) throws -> [Adapter.InquiryResult] {
    
    typealias InquiryResult = Adapter.InquiryResult
    
    let deviceDescriptor = socket(AF_BLUETOOTH, SOCK_RAW | SOCK_CLOEXEC, BluetoothProtocol.HCI.rawValue)
    
    guard deviceDescriptor >= 0 else { throw POSIXError.fromErrorNumber! }
    
    defer { close(deviceDescriptor) }
    
    let bufferSize = sizeof(HCIInquiryRequest) + (sizeof(InquiryResult) * scanLimit)
    
    let buffer = UnsafeMutablePointer<UInt8>.alloc(bufferSize)
    
    defer { buffer.dealloc(bufferSize) }
    
    let deviceClass = deviceClass ?? (0x33, 0x8b, 0x9e)
    
    let inquiryRequest = UnsafeMutablePointer<HCIInquiryRequest>(buffer)
    
    inquiryRequest.memory.identifier = UInt16(deviceIdentifier)
    inquiryRequest.memory.responseCount = UInt8(scanLimit)
    inquiryRequest.memory.length = UInt8(duration)
    inquiryRequest.memory.flags = UInt16(flags)
    inquiryRequest.memory.lap = deviceClass
    
    guard swift_bluetooth_ioctl(deviceDescriptor, HCI.IOCTL.Inquiry, buffer) >= 0
        else { throw POSIXError.fromErrorNumber! }
    
    let resultCount = Int(inquiryRequest.memory.responseCount)
    
    let resultBufferSize = sizeof(InquiryResult) * resultCount
    
    var results = [InquiryResult](count: resultCount, repeatedValue: InquiryResult())
    
    memcpy(&results, buffer.advancedBy(sizeof(HCIInquiryRequest)), resultBufferSize)
    
    return results
}


