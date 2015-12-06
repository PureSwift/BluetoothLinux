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
#elseif os(OSX)
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
        
        let deviceClassPointer = UnsafeMutablePointer<UInt8>.alloc(3)
        defer { inquiryInfoPointers.dealloc(3) }
        
        if let deviceClass = deviceClass {
            
            deviceClassPointer.memory = deviceClass
        }
        
        let foundDevicesCount = hci_inquiry(deviceIdentifier, CInt(duration), CInt(scanLimit), deviceClassPointer, inquiryInfoPointers, flags)
        
        guard foundDevicesCount >= 0 else { throw POSIXError.fromErrorNumber! }
        
        var results = [inquiry_info]()
        
        for i in 0..<foundDevicesCount {
            
            let infoPointer = inquiryInfoPointers[i]
            
            results.append(infoPointer.memory)
        }
        
        return results
    }
    
    func requestDeviceName(deviceAddress: Address) throws -> String? {
        
        fatalError("Not implemented")
    }
}

// MARK: - Supporting Types

public extension Adapter {
    
    /// Options for scanning Bluetooth devices
    public enum ScanOption: CLong, BitMaskOption {
        
        /// The cache of previously detected devices is flushed before performing the current inquiry. Otherwise, if flags is set to 0, then the results of previous inquiries may be returned, even if the devices aren't in range anymore. 
        case FlushCache
        
        public init?(rawValue: CLong) {
            
            switch rawValue {
                
            case IREQ_CACHE_FLUSH: self = .FlushCache
                
            default: return nil
            }
        }
        
        public var rawValue: CLong {
            
            switch self {
                
            case .FlushCache: return IREQ_CACHE_FLUSH
            }
        }
    }
}

public typealias DeviceClass = (Byte, Byte, Byte)

// MARK: - Darwin Stubs

#if os(OSX)
    
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
        _ inquiryInfo: UnsafeMutablePointer<UnsafeMutablePointer<inquiry_info>>, _ flags: CLong) -> CInt { stub() }
    
    let IREQ_CACHE_FLUSH: CInt = 0x0001
    
#endif

