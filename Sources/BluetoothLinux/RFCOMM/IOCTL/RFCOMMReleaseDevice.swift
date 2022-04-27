//
//  RFCOMMReleaseDevice.swift
//  
//
//  Created by Alsey Coleman Miller on 27/10/21.
//

import Bluetooth
import SystemPackage
import Socket

public extension RFCOMMIO {
    
    /// RFCOMM Release Device
    struct ReleaseDevice: Equatable, Hashable, IOControlValue {
        
        @_alwaysEmitIntoClient
        public static var id: RFCOMMIO { .releaseDevice }
        
        @usableFromInline
        internal private(set) var bytes: CInterop.RFCOMMDeviceRequest
        
        @usableFromInline
        internal init(_ bytes: CInterop.RFCOMMDeviceRequest) {
            self.bytes = bytes
        }
        
        @_alwaysEmitIntoClient
        public init(
            id: HostController.ID,
            flags: BitMaskOptionSet<RFCOMMFlag>
        ) {
            self.init(CInterop.RFCOMMDeviceRequest(
                device: id.rawValue,
                flags: flags.rawValue,
                source: .zero,
                destination: .zero,
                channel: 0x00)
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

public extension RFCOMMIO.ReleaseDevice {
    
    @_alwaysEmitIntoClient
    var id: HostController.ID {
        return .init(rawValue: bytes.device)
    }
    
    @_alwaysEmitIntoClient
    var flags: BitMaskOptionSet<RFCOMMFlag> {
        return .init(rawValue: bytes.flags)
    }
}

// MARK: - File Descriptor

internal extension SocketDescriptor {
    
    @usableFromInline
    func rfcommReleaseDevice(
        id: HostController.ID,
        flags: BitMaskOptionSet<RFCOMMFlag> = []
    ) throws {
        var request = RFCOMMIO.ReleaseDevice(
            id: id,
            flags: flags
        )
        try inputOutput(&request)
    }
}
