//
//  HCIDeviceUp.swift
//  
//
//  Created by Alsey Coleman Miller on 16/10/21.
//

import SystemPackage

public extension HostControllerIO {
    
    struct DeviceUp: IOControlInteger {
        
        @_alwaysEmitIntoClient
        public static var id: HostControllerIO { .deviceUp }
        
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
    func deviceUp(for id: HostController.ID) throws {
        try inputOutput(HostControllerIO.DeviceUp(device: id))
    }
}

// MARK: - Host Controller

public extension HostController {
    
    /// Open and initialize HCI device.
    func enable() throws {
        try fileDescriptor.deviceUp(for: id)
    }
    
    /// Open and initialize HCI device.
    static func enable(device id: HostController.ID) throws {
        let fileDescriptor = try FileDescriptor.bluetooth(.hci, flags: [.closeOnExec])
        try fileDescriptor.closeAfter {
            try fileDescriptor.deviceUp(for: id)
        }
    }
}
