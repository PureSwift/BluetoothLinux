//
//  GATTDatabase.swift
//  BluetoothLinux
//
//  Created by Alsey Coleman Miller on 2/29/16.
//  Copyright © 2016 PureSwift. All rights reserved.
//

/// GATT Database
public struct GATTDatabase {
    
    // MARK: - Private Properties
    
    private var services = Deque<Service>()
    
    private var notifyList = Deque<Notify>()
    
    private var nextHandle: UInt16 = 0x0001
    
    // MARK: - Initialization
    
    public init() { }
    
    // MARK: - Methods
    
    public mutating func clear() {
        
        self.nextHandle = 0
        self.services.removeAll()
    }
    
    public mutating func removeService(attribute: Attribute) {
        
        
    }
    
    // MARK: - Dynamic Properties
    
    public var isEmpty: Bool {
        
        return services.isEmpty
    }
}

// MARK: - Supporting Types

public extension GATTDatabase {
    
    public struct Service {
        
        public var attributes = [Attribute]()
        
        public var active = false
        
        public var claimed = false
        
        public init() { }
    }
    
    public struct Attribute {
        
        
    }
}

// MARK: - Internal Types

internal extension GATTDatabase {
    
    struct Notify {
        
        let identifier: UInt
        
        let serviceAdded: () -> ()
        
        let serviceRemoved: () -> ()
        
        
    }
}


