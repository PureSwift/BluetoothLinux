//
//  GattDatabase.swift
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

public final class GATTDatabase {
    
    // MARK: - Internal Properties
    
    internal let internalPointer: COpaquePointer
    
    // MARK: - Initialization
    
    internal init(_ internalPointer: COpaquePointer) {
        
        assert(internalPointer != nil)
        
        self.internalPointer = internalPointer
    }
    
    public init?() {
        
        self.internalPointer = gatt_db_new()
        
        guard internalPointer != nil else { return }
    }
    
    // MARK: - Methods
    
    
    
    // MARK: - Dynamic Properties
    
    
}

// MARK: - Darwin Stubs

#if os(OSX) || os(iOS)
    
    func gatt_db_new(_: Void) -> COpaquePointer { stub() }
    
    
    
#endif
