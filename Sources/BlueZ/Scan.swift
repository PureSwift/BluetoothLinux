//
//  Scan.swift
//  BlueZ
//
//  Created by Alsey Coleman Miller on 12/6/15.
//  Copyright © 2015 PureSwift. All rights reserved.
//

#if os(Linux)
    import CBlueZ
    import Glibc
#elseif os(OSX) || os(iOS)
    import Darwin.C
#endif

import SwiftFoundation

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
    func scan(duration: Int = 8, scanLimit: Int = 255, deviceClass: DeviceClass? = nil, options: [ScanOption] = []) throws -> [inquiry_info] {
        
        assert(duration > 0, "Scan must be longer than 0 seconds")
        assert(scanLimit > 0, "Must scan at least one device")
        assert(scanLimit <= 255, "Should not scan more then 255 devices for memory allocation purposes")
        
        let flags = options.optionsBitmask()
        
        let inquiryInfoPointers = UnsafeMutablePointer<UnsafeMutablePointer<inquiry_info>>.alloc(scanLimit)
        defer { inquiryInfoPointers.dealloc(scanLimit) }
        
        let deviceClassPointer: UnsafeMutablePointer<UInt8>
        
        defer { if deviceClass != nil { deviceClassPointer.dealloc(3) } }
        
        if let deviceClass = deviceClass {
            
            deviceClassPointer = UnsafeMutablePointer<UInt8>.alloc(3)
            
            deviceClassPointer[0] = deviceClass.0
            deviceClassPointer[1] = deviceClass.1
            deviceClassPointer[2] = deviceClass.2
        }
        else { deviceClassPointer = nil }
        
        let foundDevicesCount = hci_inquiry(identifier, CInt(duration), CInt(scanLimit), deviceClassPointer, inquiryInfoPointers, Int(flags))
        
        guard foundDevicesCount >= 0 else { throw POSIXError.fromErrorNumber! }
        
        var results = [inquiry_info]()
        
        for i in 0 ..< Int(foundDevicesCount) {
            
            let infoPointer = inquiryInfoPointers[i]
            
            results.append(infoPointer.memory)
        }
        
        return results
    }
    
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
    }
}

// MARK: - Supporting Types

public extension Adapter {
    
    /// Options for scanning Bluetooth devices
    public enum ScanOption: Int32, BitMaskOption {
        
        /// The cache of previously detected devices is flushed before performing the current inquiry. 
        /// Otherwise, if flags is set to 0, then the results of previous inquiries may be returned, 
        /// even if the devices aren't in range anymore.
        case FlushCache = 0x0001
        
    }
}

public typealias DeviceClass = (Byte, Byte, Byte)

// MARK: - Darwin Stubs

#if os(OSX) || os(iOS)
    
    public struct inquiry_info {
        
        /// Device Address
        var bdaddr: bdaddr_t
        
        var pscan_rep_mode: UInt8
        
        var pscan_period_mode: UInt8
        
        var pscan_mode: UInt8
        
        var dev_class: (UInt8, UInt8, UInt8)
        
        var clock_offset: UInt16
    }
    
    func hci_inquiry(dev_id: CInt, _ len: CInt, _ max_rsp: CInt, _ lap: UnsafeMutablePointer<UInt8>,
        _ inquiryInfo: UnsafeMutablePointer<UnsafeMutablePointer<inquiry_info>>, _ flags: Int) -> CInt { stub() }
    
    func hci_read_remote_name(sock: CInt, _ ba: UnsafeMutablePointer<bdaddr_t>, _ len: CInt, _ name: UnsafeMutablePointer<CChar>, _ timeout: CInt) -> CInt { stub() }
    
#endif

