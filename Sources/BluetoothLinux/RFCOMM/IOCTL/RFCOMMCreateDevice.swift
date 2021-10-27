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
        
        @usableFromInline
        internal private(set) var bytes: CInterop.RFCOMMDeviceRequest
        
        @usableFromInline
        internal init(_ bytes: CInterop.RFCOMMDeviceRequest) {
            self.bytes = bytes
        }
        
        @_alwaysEmitIntoClient
        public init(
            device: HostController.ID,
            flags: BitMaskOptionSet<RFCOMMFlag>,
            source: BluetoothAddress,
            destination: BluetoothAddress,
            channel: UInt8
        ) {
            self.init(CInterop.RFCOMMDeviceRequest(
                device: device.rawValue,
                flags: flags.rawValue,
                source: source,
                destination: destination,
                channel: channel)
            )
        }
        
        @_alwaysEmitIntoClient
        public mutating func withUnsafeMutablePointer<Result>(_ body: (UnsafeMutableRawPointer) throws -> (Result)) rethrows -> Result {
            try Swift.withUnsafeMutableBytes(of: &bytes) { buffer in
                try body(buffer.baseAddress!)
            }
        }
    }
}

public extension RFCOMMIO.CreateDevice {
    
    @_alwaysEmitIntoClient
    var id: HostController.ID {
        return .init(rawValue: bytes.device)
    }
    
    @_alwaysEmitIntoClient
    var flags: BitMaskOptionSet<RFCOMMFlag> {
        return .init(rawValue: bytes.flags)
    }
    
    @_alwaysEmitIntoClient
    var source: BluetoothAddress {
        return bytes.source
    }
    
    @_alwaysEmitIntoClient
    var destination: BluetoothAddress {
        return bytes.destination
    }
    
    @_alwaysEmitIntoClient
    var channel: UInt8 {
        return bytes.channel
    }
}


// MARK: - File Descriptor

internal extension FileDescriptor {
    
    @usableFromInline
    func rfcommCreateDevice(
        device id: HostController.ID,
        flags: BitMaskOptionSet<RFCOMMFlag> = [],
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
    }
}
