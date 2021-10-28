//
//  DeviceUp.swift
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
