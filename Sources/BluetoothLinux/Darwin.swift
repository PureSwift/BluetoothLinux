//
//  Darwin.swift
//  BluetoothLinux
//
//  Created by Alsey Coleman Miller on 2/28/16.
//  Copyright © 2016 PureSwift. All rights reserved.
//

#if os(macOS) || os(iOS)
    
    internal func stub() -> Never {
        
        fatalError("Method not implemented. This code only runs on Linux.")
    }
    
#endif
