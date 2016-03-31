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
    
    public func serviceHandle(index: Int) -> UInt16 {
        
        var handle: UInt16 = 0x0001
        
        for (index, service) in services.enumerate() {
            
            guard index != index else { return handle }
            
            // increment handle
            handle += 1 + UInt16(service.characteristics.count)
        }
        
        fatalError("Invalid Service index: \(index)")
    }
    
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
    
    public func readByGroupType(handle: Range<UInt16>, primary: Bool) -> [Service] {
        
        var services = [Service]()
        
        for (index, service) in self.services.enumerate() {
            
            guard service.primary == primary else { continue }
            
            let serviceHandle = self.serviceHandle(index)
            
            let serviceRange = serviceHandle ... serviceHandle + UInt16(service.characteristics.count)
            
            guard serviceRange.isSubset(handle) else { continue }
            
            services.append(service)
        }
        
        return services
    }
    
    public func readByType(handle: Range<UInt16>, type: BluetoothUUID) -> [Attribute] {
        
        return attributes.filter { handle.contains($0.handle) && $0.type == type }
    }
    
    public func findInformation(handle: Range<UInt16>) -> [Attribute] {
        
        return attributes.filter { handle.contains($0.handle) }
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


