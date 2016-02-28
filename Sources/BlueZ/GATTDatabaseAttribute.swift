//
//  GattDatabaseAttribute.swift
//  BlueZ
//
//  Created by Alsey Coleman Miller on 2/28/16.
//  Copyright © 2016 PureSwift. All rights reserved.
//

#if os(Linux)
    import CBlueZ
    import Glibc
#elseif os(OSX) || os(iOS)
    import Darwin.C
#endif

public final class GATTDatabaseAttribute {
    
    // MARK: - Internal Properties
    
    internal let internalPointer: COpaquePointer
    
    // MARK: - Initialization
    
    internal init(_ internalPointer: COpaquePointer) {
        
        assert(internalPointer != nil)
        
        self.internalPointer = internalPointer
    }
    
    // MARK: - Methods
    
    
    
    // MARK: - Dynamic Properties
    
    
}

// MARK: - Darwin Stubs

#if os(OSX) || os(iOS)
    
    //func btd_adapter_unref(adapter: COpaquePointer) { stub() }

#endif
