//
//  HCIDeviceInformation.swift
//  
//
//  Created by Alsey Coleman Miller on 17/10/21.
//

import Bluetooth
import SystemPackage
import Socket

public extension HostControllerIO {
    
    struct DeviceInformation: IOControlValue {
        
        @_alwaysEmitIntoClient
        public static var id: HostControllerIO { .getDeviceInfo }
        
        @usableFromInline
        internal private(set) var bytes: CInterop.HCIDeviceInformation
        
        @usableFromInline
        internal init(_ bytes: CInterop.HCIDeviceInformation) {
            self.bytes = bytes
        }
        
        public init(request id: HostController.ID) {
            self.init(CInterop.HCIDeviceInformation(id: id.rawValue))
        }
        
        public mutating func withUnsafeMutablePointer<Result>(_ body: (UnsafeMutableRawPointer) throws -> (Result)) rethrows -> Result {
            try Swift.withUnsafeMutableBytes(of: &bytes) { buffer in
                try body(buffer.baseAddress!)
            }
        }
    }
}

public extension HostControllerIO.DeviceInformation {
    
    var id: HostController.ID {
        return .init(rawValue: bytes.id)
    }
    
    var name: String {
        return bytes._name
    }
    
    var address: BluetoothAddress {
        return BluetoothAddress(bytes: bytes.address)
    }
    
    var flags: HCIDeviceOptions {
        return .init(rawValue: bytes.flags)
    }
    
    var type: HCIControllerType {
        return HCIControllerType(rawValue: CInt((bytes.type & 0x30) >> 4))
    }
    
    var busType: HCIBusType {
        return HCIBusType(rawValue: CInt(bytes.type & 0x0f))
    }
}


// MARK: - File Descriptor

internal extension SocketDescriptor {
    
    @usableFromInline
    func deviceInformation(for id: HostController.ID) throws -> HostControllerIO.DeviceInformation {
        var request = HostControllerIO.DeviceInformation(request: id)
        try inputOutput(&request)
        return request
    }
}

// MARK: - Host Controller

public extension HostController {
    
    /// Get device information.
    static func deviceInformation(for id: HostController.ID) throws -> HostControllerIO.DeviceInformation {
        let fileDescriptor = try SocketDescriptor.bluetooth(.hci, flags: [.closeOnExec])
        return try fileDescriptor.closeAfter {
            try fileDescriptor.deviceInformation(for: id)
        }
    }
}
