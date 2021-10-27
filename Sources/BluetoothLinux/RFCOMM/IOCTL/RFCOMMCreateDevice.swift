//
//  RFCOMMCreateDevice.swift
//  
//
//  Created by Alsey Coleman Miller on 26/10/21.
//

import Bluetooth
import SystemPackage

public extension RFCOMMIO {
    
    /// RFCOMM Create Device
    struct CreateDevice: Equatable, Hashable, IOControlValue {
        
        @_alwaysEmitIntoClient
        public static var id: RFCOMMIO { .createDevice }
        
        internal private(set) var bytes: CInterop.RFCOMMDeviceRequest
        
        internal init(_ bytes: CInterop.RFCOMMDeviceRequest) {
            self.bytes = bytes
        }
        
        public init(
            device: HostController.ID,
            flags: UInt32,
            source: BluetoothAddress,
            destination: BluetoothAddress,
            channel: UInt8
        ) {
            self.init(CInterop.RFCOMMDeviceRequest(
                device: device.rawValue,
                flags: flags,
                source: source,
                destination: destination,
                channel: channel)
            )
        }
        
        public mutating func withUnsafeMutablePointer<Result>(_ body: (UnsafeMutableRawPointer) throws -> (Result)) rethrows -> Result {
            try Swift.withUnsafeMutableBytes(of: &bytes) { buffer in
                try body(buffer.baseAddress!)
            }
        }
    }
}

public extension RFCOMMIO.CreateDevice {
    
    var id: HostController.ID {
        return .init(rawValue: bytes.device)
    }
    
    var flags: UInt32 {
        return bytes.flags
    }
    
    var source: BluetoothAddress {
        return bytes.source
    }
    
    var destination: BluetoothAddress {
        return bytes.destination
    }
    
    var channel: UInt8 {
        return bytes.channel
    }
}


// MARK: - File Descriptor

internal extension FileDescriptor {
    
    func rfcommCreateDevice(
        device: HostController.ID,
        flags: UInt32,
        source: BluetoothAddress,
        destination: BluetoothAddress,
        channel: UInt8
    ) throws {
        var request = RFCOMMIO.CreateDevice(
            device: id,
            flags: flags,
            source: source,
            destination: destination,
            channel: channel
        )
        try inputOutput(&request)
        return request
    }
}
