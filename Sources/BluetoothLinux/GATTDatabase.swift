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
    
    private var notificationList = Deque<Notification>()
    
    private var nextNotificationID: UInt = 0
    
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
    
    public mutating func insertService(handle: UInt16, UUID: BluetoothUUID, primary: Bool, handleCount: UInt16) -> Attribute? {
        
        func findInsertLocation(start: UInt16, _ end: UInt16) -> (service: Service?, after: Service?) {
            
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
        
        if let foundService = findInsertServices.service {
            
            // create new service
            let type = GATT.UUID(primaryService: primary)
            
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
        
        // increment
        nextServiceID += 1
        
        if let after = findInsertServices.1 {
            
            let afterIndex = self.services.indexOf({ $0.identifier == after.identifier })!
            
            self.services.insert(service, atIndex: afterIndex)
            
        } else {
            
            services.prepend(service)
        }
        
        // Fast-forward nextHandle if the new service was added to the end
        nextHandle = max(handle + handleCount, nextHandle)
        
        return service.attributes[0]
    }
    
    public mutating func removeService(attribute: Attribute) -> Bool {
        
        guard let index = services.indexOf({ $0.identifier == attribute.serviceIdentifier })
            else { return false }
        
        services.removeAtIndex(index)
        
        return true
    }
    
    public func service(ofAttribute attribute: Attribute) -> Service? {
        
        for service in services {
            
            if service.identifier == attribute.serviceIdentifier {
                
                return service
            }
        }
        
        return nil
    }
    
    /// Registers for notifications and returns the notification ID.
    public mutating func register(serviceAdded: AttributeCallback, serviceRemoved: AttributeCallback) -> UInt {
        
        let notification = Notification(identifier: nextNotificationID, serviceAdded: serviceAdded, serviceRemoved: serviceRemoved)
        
        // increment
        nextNotificationID += 1
        
        notificationList.append(notification)
        
        return notification.identifier
    }
    
    /// Unregisters the notification with specified identifier.
    public mutating func unregister(notificationIdentifier: UInt) -> Bool {
        
        guard let notificationIndex = notificationList.indexOf({ $0.identifier == notificationIdentifier })
            else { return false }
        
        notificationList.removeAtIndex(notificationIndex)
        
        return true
    }
    
    public func readByGroupType(handle handle: (start: UInt16, end: UInt16), type: BluetoothUUID) -> [Attribute] {
        
        var attributes = [Attribute]()
        
        for service in services {
            
            guard service.active else { continue }
            
            guard type == service.attributes[0].type else { continue }
            
            let groupStart = service.attributes[0].handle
            
            let groupEnd = groupStart + UInt16(service.attributes.count - 1)
            
            guard (groupEnd < handle.start || groupStart > handle.end) == false else { continue }
            
            guard (groupStart < handle.start || groupStart > handle.end) == false else { continue }
            
            attributes.append(service.attributes[0])
        }
        
        return attributes
    }
    
    public func readbyType(handle handle: (start: UInt16, end: UInt16), type: BluetoothUUID) -> [Attribute] {
        
        var attributes = [Attribute]()
        
        for service in services {
            
            for attribute in service.attributes {
                
                guard attribute.handle >= handle.start
                    && attribute.handle <= handle.end
                    && attribute.type == type else { continue }
                
                attributes.append(attribute)
            }
        }
        
        return attributes
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
        
        /// Start and end identifiers.
        internal var handles: (UInt16, UInt16) {
            
            return (attributes[0].handle, attributes.last!.handle)
        }
        
        /// Internal identifier for lookup.
        private let identifier: UInt
        
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
    
    struct Notification {
        
        let identifier: UInt
        
        let serviceAdded: AttributeCallback
        
        let serviceRemoved: AttributeCallback
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


