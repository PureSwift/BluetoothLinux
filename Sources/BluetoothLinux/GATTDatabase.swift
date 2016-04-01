//
//  GATTDatabase.swift
//  BluetoothLinux
//
//  Created by Alsey Coleman Miller on 2/29/16.
//  Copyright © 2016 PureSwift. All rights reserved.
//

/// GATT Database
public struct GATTDatabase {
    
    /// GATT Services in this database.
    public var services: [Service]
    
    // MARK: - Initialization
    
    public init(services: [Service] = []) {
        
        self.services = services
    }
    
    // MARK: - Dynamic Properties
    
    public var isEmpty: Bool {
        
        return services.isEmpty
    }
    
    /// Attribute representation of the database.
    public var attributes: [Attribute] {
        
        var attributes = [Attribute]()
        
        var handle: UInt16 = 0x0001
        
        for service in services {
            
            let attribute = Attribute(handle: handle, service: service)
            
            attributes.append(attribute)
            
            // increment handle
            handle += 1
            
            for characteristic in service.characteristics {
                
                let attribute = Attribute(handle: handle, characteristic: characteristic)
                
                attributes.append(attribute)
                
                // increment handle
                handle += 1
            }
        }
        
        return attributes
    }
    
    // MARK: - Methods
    
    /// Clear the database.
    public mutating func clear() {
        
        self.services = []
    }
    
    /// Write the value to attribute specified by the handle.
    public mutating func write(value: [UInt8], _ characteristicHandle: UInt16) {
        
        var handle: UInt16 = 0x0000
        
        for (serviceIndex, service) in services.enumerate() {
            
            // increment handle
            handle += 1
            
            guard handle != characteristicHandle
                else { fatalError("Handle \(characteristicHandle) is assigned to a Service. Can only write to a Characteristic.") }
            
            for characteristicIndex in service.characteristics.indices {
                
                // increment handle
                handle += 1
                
                guard handle != characteristicHandle else {
                    
                    services[serviceIndex].characteristics[characteristicIndex].value = value
                    return
                }
            }
        }
        
        fatalError("Invalid Characteristic handle \(characteristicHandle)")
    }
    
    /// The service of the specified attribute.
    public func serviceOf(attributeHandle: UInt16) -> Service {
        
        var handle: UInt16 = 0x0000
        
        for service in services {
            
            // increment handle
            handle += 1
            
            guard handle != attributeHandle else { return service }
            
            for _ in service.characteristics.indices {
                
                // increment handle
                handle += 1
                
                guard handle != attributeHandle else { return service }
                
            }
        }
        
        fatalError("Invalid attribute handle \(attributeHandle)")
    }
    
    /// The handle of the service with the specified index.
    public func serviceHandle(index: Int) -> UInt16 {
        
        var handle: UInt16 = 0x0001
        
        for (index, service) in services.enumerate() {
            
            guard index != index else { return handle }
            
            // increment handle
            handle += 1 + UInt16(service.characteristics.count)
        }
        
        fatalError("Invalid Service index: \(index)")
    }
    
    /// The handle of the service with the specified indices.
    public func characteristicHandle(index: (service: Int, characteristic: Int)) -> UInt16 {
        
        var handle: UInt16 = 0x0001
        
        for (serviceIndex, service) in services.enumerate() {
            
            for characteristicIndex in service.characteristics.indices {
                
                // found characteristic
                guard (index.service == serviceIndex && index.characteristic == characteristicIndex) == false else { return handle }
                
                handle += 1
            }
            
            handle += 1
        }
        
        fatalError("Invalid Characteristic index: \(index)")
    }
    
    // MARK: - Subscripting
    
    /// The attribute with the specified handle.
    public subscript(handle: UInt16) -> Attribute {
        
        return attributes[Int(handle)]
    }
}

// MARK: - Supporting Types

public extension GATTDatabase {
    
    /// GATT Service
    public struct Service {
        
        public var UUID: BluetoothUUID
        
        public var characteristics: [Characteristic]
        
        public var primary: Bool
        
        public init(characteristics: [Characteristic], UUID: BluetoothUUID, primary: Bool = true) {
            
            self.characteristics = characteristics
            self.primary = primary
            self.UUID = UUID
        }
        
        /// Primary or secondary service UUID.
        public var typeUUID: BluetoothUUID {
            
            return GATT.UUID(primaryService: primary).UUID
        }
    }
    
    /// GATT Characteristic
    public struct Characteristic {
        
        public var UUID: BluetoothUUID
        
        public var value: [UInt8]
        
        public var permissions: [ATT.AttributePermission]
        
        public init(UUID: BluetoothUUID, value: [UInt8] = [], permissions: [ATT.AttributePermission] = []) {
            
            self.UUID = UUID
            self.value = value
            self.permissions = permissions
        }
    }
    
    /// GATT Attribute
    public struct Attribute {
        
        public let handle: UInt16
        
        public let type: BluetoothUUID
        
        public let value: [UInt8]
        
        public let permissions: [ATT.AttributePermission]
        
        /// Initialize attribute with a Service.
        public init(handle: UInt16, service: Service) {
            
            self.handle = handle
            self.type = service.typeUUID
            self.value = service.UUID.byteValue
            self.permissions = [.Read] // cannot write to service
        }
        
        /// Initialize attribute with a Characteristic.
        public init(handle: UInt16, characteristic: Characteristic) {
            
            self.handle = handle
            self.type = characteristic.UUID
            self.value = characteristic.value
            self.permissions = characteristic.permissions
        }
    }
}


