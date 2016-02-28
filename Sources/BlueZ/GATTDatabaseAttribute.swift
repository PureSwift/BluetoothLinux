//
//  GattDatabaseAttribute.swift
//  BlueZ
//
//  Created by Alsey Coleman Miller on 2/28/16.
//  Copyright © 2016 PureSwift. All rights reserved.
//

import Foundation

public extension GATTDatabase {
    
    typealias Attribute = GATTDatabaseAttribute
}

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