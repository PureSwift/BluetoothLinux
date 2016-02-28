//
//  Darwin.swift
//  BlueZ
//
//  Created by Alsey Coleman Miller on 2/28/16.
//  Copyright © 2016 PureSwift. All rights reserved.
//

#if os(OSX) || os(iOS)
    
    @noreturn
    internal func stub() {
        
        fatalError("Method not implemented. This code only runs on Linux.")
    }
    
#endif