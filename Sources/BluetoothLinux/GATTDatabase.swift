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
    public var services: [Service] = [] {
        
        didSet { updateAttributes() }
    }
    
    /// Attribute representation of the database.
    public private(set) var attributes: [Attribute] = []
    
    // MARK: - Initialization
    
    public init(services: [Service] = []) {
        
        self.services = services
        self.updateAttributes()
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
        
        return attributes[Int(handle) - 1]
    }
    
    // MARK: - Private Methods
    
    private mutating func updateAttributes() {
        
        var attributes = [Attribute]()
        
        var handle: UInt16 = 0x0000
        
        for service in services {
            
            // increment handle
            handle += 1
            
            let attribute = Attribute(service: service, handle: handle)
            
            attributes.append(attribute)
            
            for characteristic in service.characteristics {
                
                // increment handle
                handle += 1
                
                attributes += Attribute.fromCharacteristic(characteristic, handle: handle)
                
                handle = attributes.last!.handle
            }
        }
        
        self.attributes = attributes
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
    }
    
    /// GATT Include Declaration
    public struct Include {
        
        /// Included service handle
        public var serviceHandle: UInt16
        
        /// End group handle
        public var endGroupHandle: UInt16
        
        /// Included Service UUID
        public var serviceUUID: BluetoothUUID
        
        public init(serviceHandle: UInt16, endGroupHandle: UInt16, serviceUUID: BluetoothUUID) {
            
            self.serviceHandle = serviceHandle
            self.endGroupHandle = endGroupHandle
            self.serviceUUID = serviceUUID
        }
        
        /// ATT Attribute Value
        private var value: [UInt8] {
            
            let handleBytes = serviceHandle.littleEndianBytes
            
            let endGroupBytes = endGroupHandle.littleEndianBytes
            
            return [handleBytes.0, handleBytes.1, endGroupBytes.0, endGroupBytes.1] + serviceUUID.byteValue
        }
    }
    
    /// GATT Characteristic
    public struct Characteristic {
        
        public typealias Descriptor = GATTDatabase.Descriptor
        public typealias Permission = ATT.AttributePermission
        public typealias Property = GATT.CharacteristicProperty
        
        public var UUID: BluetoothUUID
        
        public var value: [UInt8]
        
        public var descriptors: [Descriptor]
        
        public var permissions: [Permission]
        
        public var properties: [Property]
        
        public init(UUID: BluetoothUUID,
                    value: [UInt8] = [],
                    permissions: [Permission] = [],
                    properties: [Property] = [],
                    descriptors: [Descriptor] = []) {
            
            self.UUID = UUID
            self.value = value
            self.permissions = permissions
            self.descriptors = descriptors
            self.properties = properties
        }
    }
    
    /// GATT Characteristic Descriptor
    public struct Descriptor {
        
        public typealias Permission = ATT.AttributePermission
        
        public var UUID: BluetoothUUID
        
        public var permissions: [Permission]
        
        public var value: [UInt8]
        
        public init(UUID: BluetoothUUID, value: [UInt8] = [], permissions: [Permission] = []) {
            
            self.UUID = UUID
            self.value = value
            self.permissions = permissions
        }
    }
    
    /// ATT Attribute
    public struct Attribute {
        
        public typealias Permission = ATT.AttributePermission
        
        public let handle: UInt16
        
        public let UUID: BluetoothUUID
        
        public let value: [UInt8]
        
        public let permissions: [Permission]
        
        /// Defualt initializer
        private init(handle: UInt16, UUID: BluetoothUUID, value: [UInt8] = [], permissions: [Permission] = []) {
            
            self.handle = handle
            self.UUID = UUID
            self.value = value
            self.permissions = permissions
        }
        
        /// Initialize attribute with a `Service`.
        private init(service: Service, handle: UInt16) {
            
            self.handle = handle
            self.UUID = GATT.UUID(primaryService: service.primary).toUUID()
            self.value = service.UUID.byteValue
            self.permissions = [.Read] // Read only
        }
        
        /// Initialize attribute with an `Include Declaration`.
        private init(include: Include, handle: UInt16) {
            
            self.handle = handle
            self.UUID = GATT.UUID.Include.toUUID()
            self.value = include.value
            self.permissions = [.Read] // Read only
        }
        
        /// Initialize attributes from a `Characteristic`.
        private static func fromCharacteristic(characteristic: Characteristic, handle: UInt16) -> [Attribute] {
            
            var currentHandle = handle
            
            let declarationAttribute: Attribute = {
                
                let propertiesMask = characteristic.properties.optionsBitmask()
                let valueHandleBytes = (handle + 1).littleEndianBytes
                let value = [propertiesMask, valueHandleBytes.0, valueHandleBytes.1] + characteristic.UUID.byteValue
                
                return Attribute(handle: currentHandle, UUID: GATT.UUID.Characteristic.toUUID(), value: value, permissions: [.Read])
            }()
            
            currentHandle += 1
            
            let valueAttribute = Attribute(handle: currentHandle, UUID: characteristic.UUID, value: characteristic.value, permissions: characteristic.permissions)
            
            var attributes = [declarationAttribute, valueAttribute]
            
            // add descriptors
            if characteristic.descriptors.isEmpty == false {
                
                var descriptorAttributes = [Attribute]()
                
                for descriptor in characteristic.descriptors {
                    
                    currentHandle += 1
                    
                    let attribute = Attribute(descriptor: descriptor, handle: currentHandle)
                    
                    descriptorAttributes.append(attribute)
                }
                
                attributes += descriptorAttributes
            }
            
            return attributes
        }
        
        /// Initialize attribute with a `Characteristic Descriptor`.
        private init(descriptor: Descriptor, handle: UInt16) {
            
            self.handle = handle
            self.UUID = descriptor.UUID
            self.value = descriptor.value
            self.permissions = descriptor.permissions
        }
    }
}


