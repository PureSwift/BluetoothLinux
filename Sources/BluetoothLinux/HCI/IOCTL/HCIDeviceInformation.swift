//
//  HCIDeviceInformation.swift
//  
//
//  Created by Alsey Coleman Miller on 17/10/21.
//

import Bluetooth
import SystemPackage

public extension HostControllerIO {
    
    struct DeviceInformation: IOControlValue {
        
        public static var id: HostControllerIO { .getDeviceInfo }
        
        internal private(set) var bytes: CInterop.HCIDeviceInformation
        
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
}


// MARK: - File Descriptor

internal extension FileDescriptor {
    
    func deviceInformation(for id: HostController.ID) throws -> HostControllerIO.DeviceInformation {
        var request = HostControllerIO.DeviceInformation(request: id)
        try inputOutput(&request)
        return request
    }
}
