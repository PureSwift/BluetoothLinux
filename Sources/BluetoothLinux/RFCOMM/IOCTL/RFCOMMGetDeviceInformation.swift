//
//  RFCOMMGetDeviceInformation.swift
//  
//
//  Created by Alsey Coleman Miller on 27/10/21.
//

import Bluetooth
import SystemPackage
import Socket

public extension RFCOMMIO {
    
    /// RFCOMM Get Device Information
    struct GetDeviceInformation: Equatable, Hashable, IOControlValue {
        
        @_alwaysEmitIntoClient
        public static var id: RFCOMMIO { .getDeviceInfo }
        
        @usableFromInline
        internal private(set) var bytes: CInterop.RFCOMMDeviceInformation
        
        @usableFromInline
        internal init(_ bytes: CInterop.RFCOMMDeviceInformation) {
            self.bytes = bytes
        }
        
        @_alwaysEmitIntoClient
        public init(id: HostController.ID) {
            self.init(CInterop.RFCOMMDeviceInformation(id: id.rawValue))
        }
        
        @_alwaysEmitIntoClient
        public mutating func withUnsafeMutablePointer<Result>(_ body: (UnsafeMutableRawPointer) throws -> (Result)) rethrows -> Result {
            try Swift.withUnsafeMutableBytes(of: &bytes) { buffer in
                try body(buffer.baseAddress!)
            }
        }
    }
}

public extension RFCOMMIO.GetDeviceInformation {
    
    @_alwaysEmitIntoClient
    var device: RFCOMMDevice {
        return RFCOMMDevice(bytes)
    }
}


// MARK: - File Descriptor

internal extension SocketDescriptor {
    
    @usableFromInline
    func rfcommGetDevice(
        id: HostController.ID
    ) throws -> RFCOMMDevice {
        var request = RFCOMMIO.GetDeviceInformation(id: id)
        try inputOutput(&request)
        return request.device
    }
}
