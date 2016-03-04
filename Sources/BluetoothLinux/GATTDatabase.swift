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
    
    private var nextServiceID: UInt = 0
    
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
    
    public mutating func removeService(attribute: Attribute) -> Bool {
        
        guard let index = services.indexOf({ $0.identifier == attribute.serviceIdentifier })
            else { return false }
        
        services.removeAtIndex(index)
        
        return true
    }
    
    public func insertService(handle: UInt16, UUID: BluetoothUUID, primary: Bool, handleCount: UInt16) {
        
        
    }
    
    public mutating func newAttribute(serviceIndex: UInt, handle: UInt16, type: BluetoothUUID, value: [UInt8]) {
        
        var attribute = Attribute(serviceIdentifier: serviceIndex, handle: handle, type: type, value: value)
        
        
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
        
        public var active = false {
            
            didSet {
                
                
            }
        }
        
        public var claimed = false
        
        public private(set) var handleCount: UInt16 = 0
        
        /// Internal identifier for lookup.
        private let identifier: UInt
        
        /// Create a new service and give it an attribute.
        private init(identifier: UInt, UUID: BluetoothUUID, handle: UInt16, primary: Bool, handleCount: Int) {
            
            self.identifier = identifier
            
            let type = primary ? GATT.UUID.PrimaryService.rawValue : GATT.UUID.PrimaryService.rawValue
            
            let newAttribute = Attribute(serviceIdentifier: identifier, handle: handle, type: .Bit16(type), value: UUID.byteValue)
            
            self.attributes.append(newAttribute)
        }
    }
    
    /// GATT Attribute
    public struct Attribute {
        
        // Public data
        
        public let handle: UInt16
        
        public let type: BluetoothUUID
        
        public let value: [UInt8]
        
        // Private Data
        
        private let serviceIdentifier: UInt
        
        private let read: Read? = nil
        
        private let write: Write? = nil
        
        private let readID: UInt = 0
        
        private let writeID: UInt = 0
        
        private var pendingReads = Deque<PendingRead>()
        
        private var pendingWrites = Deque<PendingWrite>()
        
        private init(serviceIdentifier: UInt, handle: UInt16, type: BluetoothUUID, value: [UInt8]) {
            
            self.serviceIdentifier = serviceIdentifier
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


