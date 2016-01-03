//
//  Request.swift
//  BlueZ
//
//  Created by Alsey Coleman Miller on 1/2/16.
//  Copyright © 2016 PureSwift. All rights reserved.
//

#if os(Linux)
    import CBlueZ
#endif

import SwiftFoundation

public extension Adapter {
    
    func sendRequest(timeout: Int = 1000) {
        
        
    }
}

public extension Adapter {
    
    public struct Request {
        
        
    }
}

// MARK: - Darwin Stubs

#if os(OSX) || os(iOS)

    /// Sends
    func hci_send_req(dd: CInt, _ hci_request: COpaquePointer, _ timeout: CInt) -> CInt { stub() }

#endif
