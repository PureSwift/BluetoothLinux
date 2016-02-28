//
//  GattServer.swift
//  BlueZ
//
//  Created by Alsey Coleman Miller on 2/28/16.
//  Copyright © 2016 PureSwift. All rights reserved.
//

#if os(Linux)
    import CBlueZ
    import CBlueZInternal
    import Glibc
#elseif os(OSX) || os(iOS)
    import Darwin.C
#endif

public final class GATTServer {
    
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
