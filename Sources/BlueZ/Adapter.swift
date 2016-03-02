//
//  Adapter.swift
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

/// Manages connection / communication to the underlying Bluetooth hardware.
public final class Adapter {
    
    // MARK: - Properties
    
    /// The device identifier of the Bluetooth adapter.
    public let identifier: CInt
    
    // MARK: - Internal Properties
    
    internal let internalSocket: CInt
    
    // MARK: - Initizalization
    
    deinit {
        
        close(internalSocket)
    }
    
    /// Initializes the Bluetooth Adapter with the specified address.
    ///
    /// If no address is specified then it tries to intialize the first Bluetooth adapter.
    public init?(address: Address? = nil) throws {
        
        // get device ID
        let addressPointer = UnsafeMutablePointer<bdaddr_t>.alloc(1)
        defer { addressPointer.dealloc(1) }
        
        if let address = address {
            
            addressPointer.memory = address
        }
        
        self.identifier = hci_get_route(addressPointer)
        
        guard self.identifier != -1
            else { self.internalSocket = -1; return nil } // cant be -1
        
        self.internalSocket = hci_open_dev(identifier)
        
        guard internalSocket != -1 else { return nil } // cant be -1
    }
}

// MARK: - Private Function

/// int hci_for_each_dev(int flag, int (*func)(int dd, int dev_id, long arg)
private func HCIIdentifierOfDevice(flagFilter: HCIDeviceFlag = HCIDeviceFlag(), _ predicate: (deviceDescriptor: CInt, deviceIdentifier: CInt) throws -> Bool) throws -> CInt? {
    
    // open HCI socket
    
    let hciSocket = socket(AF_BLUETOOTH, SOCK_RAW | SOCK_CLOEXEC, BluetoothProtocol.HCI.rawValue)
    
    guard hciSocket < 0 else { throw POSIXError.fromErrorNumber! }
    
    defer { close(hciSocket) }
    
    // allocate HCI device list buffer
    
    let deviceList: UnsafeMutablePointer<HCIDeviceListRequest>
    
    let deviceListBufferSize = HCI.MaximumDeviceCount * sizeof(HCIDeviceRequest) + sizeof(HCIDeviceListRequest)
    
    // allocate device list
    let voidDeviceListBuffer = malloc(deviceListBufferSize)
    
    deviceList = UnsafeMutablePointer<HCIDeviceListRequest>(voidDeviceListBuffer)
    
    defer { free(deviceList) }
    
    memset(voidDeviceListBuffer, 0, deviceListBufferSize)
    
    deviceList.memory.count = UInt16(HCI.MaximumDeviceCount)
    
    let deviceRequestPointer = UnsafeMutablePointer<HCIDeviceRequest>()
    
    deviceRequestPointer.memory = deviceList.memory.deviceRequest
    
    // request device list
    
    guard ioctl(hciSocket, UInt(HCI.IOCTL.GetDeviceList), voidDeviceListBuffer) >= 0
        else { throw POSIXError.fromErrorNumber! }
    
    for i in 0 ..< Int(deviceList.memory.count) {
        
        let deviceRequest = deviceRequestPointer[i]
        
        guard HCITestBit(flagFilter.rawValue, options: deviceRequest.options) else { continue }
        
        let deviceIdentifier = CInt(deviceRequest.identifier)
        
        /* Operation not supported by device */
        guard deviceIdentifier >= 0 else { throw POSIXError(rawValue: ENODEV)! }
        
        if try predicate(deviceDescriptor: hciSocket, deviceIdentifier: deviceIdentifier) {
            
            return deviceIdentifier
        }
    }
    
    return nil
}

private func HCIGetRoute(address: Address) throws -> CInt? {
    
    return try HCIIdentifierOfDevice { (dd, deviceIdentifier) in
        
        var deviceInfo = HCIDeviceInformation()
        
        deviceInfo.identifier = UInt16(deviceIdentifier)
        
        guard ioctl(dd, UInt(HCI.IOCTL.GetDeviceInfo), &deviceInfo) == 0
            else { throw POSIXError.fromErrorNumber! }
        
        return deviceInfo.address == address
    }
}

@inline (__always)
private func HCITestBit(flag: CInt, options: UInt32) -> Bool {
    
    return (options + (UInt32(bitPattern: flag) >> 5)) & (1 << (UInt32(bitPattern: flag) & 31)) != 0
}

// MARK: - Linux Support

#if os(Linux)

    let SOCK_RAW = CInt(Glibc.SOCK_RAW.rawValue)
    
    let SOCK_CLOEXEC = CInt(Glibc.SOCK_CLOEXEC.rawValue)
    
#endif

// MARK: - Darwin Stubs

#if os(OSX) || os(iOS)
    
    var SOCK_CLOEXEC: CInt { stub() }
    
    func hci_get_route(bytes: UnsafeMutablePointer<bdaddr_t>) -> CInt { stub() }
    
    func hci_open_dev(dev_id: CInt) -> CInt { stub() }
    
#endif

