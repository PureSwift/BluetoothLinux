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
    
    public mutating func insertService(handle: UInt16, UUID: BluetoothUUID, primary: Bool, handleCount: UInt16) -> Attribute? {
        
        func findInsertLocation(start: UInt16, _ end: UInt16) -> (Service?, Service?) {
            
            var after: Service?
            
            for service in services {
                
                let (startHandle, endHandle) = service.handles
                
                guard (start >= startHandle && start <= endHandle) == false
                    else { return (service, after) }
                
                guard (start >= startHandle && start <= endHandle) == false
                    else { return (service, after) }
                
                guard (end < endHandle) == false
                    else { return (nil, after) }
                
                after = service
            }
            
            return (nil, after)
        }
        
        let findInsertServices = findInsertLocation(handle, handle + handleCount - 1)
        
        if let foundService = findInsertServices.0 {
            
            // create new service
            let type = GATT.UUID(primaryService: primary)
            
            let currentUUID = foundService.UUID
            
            // Check if service match
            guard (foundService.UUID == UUID
                && foundService.UUID == type.UUID
                && foundService.attributes.count == Int(handleCount)
                && foundService.attributes[0].handle == handle) == false
                else { return nil }
            
            return foundService.attributes[0]
        }
        
        // service not found, create new service
        
        let service = Service(identifier: nextServiceID, UUID: UUID, handle: handle, primary: primary)
        
        if let after = findInsertServices.1 {
            
            //if (!queue_push_after(db->services, after, service))
            //  goto fail;
        } else {
            
            services.prepend(service)
        }
        
        // Fast-forward nextHandle if the new service was added to the end
        nextHandle = max(handle + handleCount, nextHandle)
        
        return service.attributes[0]
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
        
        public private(set) var attributes: [Attribute]
        
        public var active = false
        
        public var claimed = false
        
        public var UUID: BluetoothUUID {
            
            return attributes[0].type
        }
        
        /// Internal identifier for lookup.
        private let identifier: UInt
        
        /// Start and end identifiers.
        private var handles: (UInt16, UInt16) {
            
            return (attributes[0].handle, attributes.last!.handle)
        }
        
        /// Create a new service and give it an attribute.
        private init(identifier: UInt, UUID: BluetoothUUID, handle: UInt16, primary: Bool) {
            
            self.identifier = identifier
            
            let type = primary ? GATT.UUID.PrimaryService.rawValue : GATT.UUID.PrimaryService.rawValue
            
            let newAttribute = Attribute(serviceIdentifier: identifier, handle: handle, type: .Bit16(type), value: UUID.byteValue)
            
            self.attributes = [newAttribute]
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


