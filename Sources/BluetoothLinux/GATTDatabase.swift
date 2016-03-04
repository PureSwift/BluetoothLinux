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
    
    private var nextHandle: UInt16 = 0x0001
    
    private var services = Deque<Service>()
    
    private var notifyList = Deque<Notify>()
    
    private var nextNotifyID: UInt = 0
    
    // MARK: - Initialization
    
    public init() { }
    
    // MARK: - Methods
    
    public mutating func clear() {
        
        self.nextHandle = 0
        self.services.removeAll()
    }
    
    public mutating func clear(range: (start: UInt16, end: UInt16)) {
        
        
    }
    
    public mutating func addService() {
        
        
    }
    
    public mutating func removeService() {
        
        
    }
    
    public func insertService(handle: UInt16, UUID: BluetoothUUID, primary: Bool, handleCount: UInt16) {
        
        
    }
    
    public mutating func newAttribute(serviceIndex: Int, handle: UInt16, type: BluetoothUUID, value: [UInt8]) {
        
        var attribute = Attribute(service, service, handle: handle, type: type, value: value)
        
        
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
    
    public typealias Read = (Attribute) -> ()
    
    public typealias Write = (Attribute) -> ()
    
    public typealias AttributeCallback = (Attribute) -> ()
    
    /// GATT Service
    public struct Service {
        
        public private(set) var attributes = [Attribute]()
        
        public var active = false
        
        public var claimed = false
        
        public private(set) var handleCount: UInt16 = 0
        
        /// Create a new service and give it an attribute.
        private init(UUID: BluetoothUUID, handle: UInt16, primary: Bool, handleCount: Int) {
            
            let type = primary ? GATT.UUID.PrimaryService.rawValue : GATT.UUID.PrimaryService.rawValue
            
            let newAttribute = Attribute(handle: <#T##UInt16#>, type: .Bit16(type), value: <#T##[UInt8]#>)
            
            
        }
    }
    
    /// GATT Attribute
    public struct Attribute {
        
        // Public data
        
        public let handle: UInt16
        
        public let type: BluetoothUUID
        
        public let value: [UInt8]
        
        // Other Data
        
        private let read: Read?
        
        private let write: Write?
        
        private let readID: UInt = 0
        
        private let writeID: UInt = 0
        
        private var pendingReads = Deque<PendingRead>()
        
        private var pendingWrites = Deque<PendingWrite>()
        
        private init(handle: UInt16, type: BluetoothUUID, value: [UInt8]) {
            
            self.handle = handle
            self.type = type
            self.value = value
        }
    }
}

// MARK: - Private Types

private extension GATTDatabase {
    
    struct Notify {
        
        let identifier: UInt
        
        let serviceAdded: () -> ()
        
        let serviceRemoved: () -> ()
    }
    
    struct PendingRead {
        
        let identifier: UInt
        
        let timeoutIdentifier: UInt
        
        
    }
    
    struct PendingWrite {
        
        let identifier: UInt
        
        let timeoutIdentifier: UInt
    }
}


