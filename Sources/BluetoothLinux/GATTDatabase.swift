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
    
    /// Attribute representation of the database.
    public private(set) var attributes: [Attribute]
    
    // MARK: - Initialization
    
    public init(services: [Service] = []) {
        
        self.services = services
    }
    
    // MARK: - Dynamic Properties
    
    public var isEmpty: Bool {
        
        return services.isEmpty
    }
    
    // MARK: - Methods
    
    /// Clear the database.
    public mutating func clear() {
        
        self.services = []
    }
    
    /*
    /// Clear all ATT attributes in the specified range.
    public mutating func clear(range: Range<UInt16>) {
        
        for handle in range {
            
            
        }
    }*/
    
    public func readByGroupType(handle: Range<UInt16>, type: BluetoothUUID) -> [Attribute] {
        
        var attributes = [Attribute]()
        
        for service in services {
            
            guard service.typeUUID == type else { continue }
            
            let groupStart = service.attributes[0].handle
            
            let groupEnd = groupStart + UInt16(service.attributes.count - 1)
            
            guard (groupEnd < handle.start || groupStart > handle.end) == false else { continue }
            
            guard (groupStart < handle.start || groupStart > handle.end) == false else { continue }
            
            attributes.append(service.attributes[0])
        }
        
        return attributes
    }
    
    public func readByType(handle: Range<UInt16>, type: BluetoothUUID) -> [Attribute] {
        
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
    
    // MARK: - Private Methods
    
    /*
    private mutating func updateAttributes() {
        
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
        
        self.attributes = attributes
    }*/
    
    private func serviceHandle(index: Int) -> UInt16 {
        
        var handle: UInt16 = 0x0001
        
        for (index, service) in services.enumerate() {
            
            // increment handle
            handle += 1
            
            for characteristic in service.characteristics {
                
                // increment handle
                handle += 1
            }
        }
    }
}

// MARK: - Supporting Types

public extension GATTDatabase {
    
    /// GATT Service
    public struct Service {
        
        public var characteristics: [Characteristic]
        
        public var primary: Bool
        
        public var UUID: BluetoothUUID
        
        public init(characteristics: [Characteristic], primary: Bool, UUID: BluetoothUUID) {
            
            self.characteristics = characteristics
            self.primary = primary
            self.UUID = UUID
        }
        
        /// Primary or secondary service UUID.
        public var typeUUID: BluetoothUUID {
            
            let type = primary ? GATT.UUID.PrimaryService.rawValue : GATT.UUID.SecondaryService.rawValue
            
            return .Bit16(type)
        }
    }
    
    /// GATT Characteristic
    public struct Characteristic {
        
        public var UUID: BluetoothUUID
        
        public var value: [UInt8]
        
        public init(UUID: BluetoothUUID, value: [UInt8] = []) {
            
            self.UUID = UUID
            self.value = value
        }
    }
    
    /// GATT Attribute
    public struct Attribute {
        
        public let handle: UInt16
        
        public let type: BluetoothUUID
        
        public let value: [UInt8]
        
        /// Initialize attribute with a Service.
        public init(handle: UInt16, service: Service) {
            
            self.handle = handle
            self.type = service.typeUUID
            self.value = service.UUID.byteValue
        }
        
        /// Initialize attribute with a Characteristic.
        public init(handle: UInt16, characteristic: Characteristic) {
            
            self.handle = handle
            self.type = characteristic.UUID
            self.value = characteristic.value
        }
    }
}


