//
//  Bluetooth.swift
//  BlueZ
//
//  Created by Alsey Coleman Miller on 12/6/15.
//  Copyright © 2015 PureSwift. All rights reserved.
//

#if os(Linux)
    import CBlueZ
#endif

public struct Bluetooth { }

// MARK: - Darwin

#if os(OSX) || os(iOS)

    @noreturn
    internal func stub() {
        
        fatalError("Method not implemented. This code only runs on Linux.")
    }
    
#endif
