//
//  DeviceDown.swift
//  
//
//  Created by Alsey Coleman Miller on 16/10/21.
//

import SystemPackage

public extension HostControllerIO {
    
    struct DeviceDown: IOControlInteger {
        
        @_alwaysEmitIntoClient
        public static var id: HostControllerIO { .deviceDown }
        
        public var device: HostController.ID
        
        public init(device: HostController.ID) {
            self.device = device
        }
        
        @_alwaysEmitIntoClient
        public var intValue: Int32 {
            return Int32(device.rawValue)
        }
    }
}

// MARK: - File Descriptor

internal extension FileDescriptor {
    
    @usableFromInline
    func deviceDown(for id: HostController.ID) throws {
        try inputOutput(HostControllerIO.DeviceDown(device: id))
    }
}

// MARK: - Host Controller

public extension HostController {
    
    /// Disable the HCI device.
    func disable() throws {
        try fileDescriptor.deviceDown(for: id)
    }
    
    /// Disable the HCI device.
    static func disable(device id: HostController.ID) throws {
        let fileDescriptor = try FileDescriptor.bluetooth(.hci, flags: [.closeOnExec])
        try fileDescriptor.closeAfter {
            try fileDescriptor.deviceDown(for: id)
        }
    }
}
