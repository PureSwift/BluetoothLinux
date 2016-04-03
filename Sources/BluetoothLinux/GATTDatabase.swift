//
//  GATTDatabase.swift
//  BluetoothLinux
//
//  Created by Alsey Coleman Miller on 2/29/16.
//  Copyright © 2016 PureSwift. All rights reserved.
//

import SwiftFoundation
import Bluetooth

/// GATT Database
public struct GATTDatabase {
    
    // MARK: - Internal Properties
    
    /// Do not access directly, use `newHandle()`
    internal var lastHandle: UInt16 = 0x0000
    
    internal var attributeGroups = [AttributeGroup]()
    
    // MARK: - Initialization
    
    public init() { }
    
    // MARK: - Dynamic Properties
    
    /// Whether the database contains any attributes. 
    public var isEmpty: Bool {
        
        return attributeGroups.isEmpty
    }
    
    /// Attribute representation of the database.
    public var attributes: [Attribute] {
        
        var attributes = [Attribute]()
        
        for group in attributeGroups {
            
            attributes += group.attributes
        }
        
        return attributes
    }
    
    // MARK: - Methods
    
    public mutating func add(service: Service) {
        
        let serviceAttribute = Attribute(service: service, handle: newHandle())
        
        var attributes = [serviceAttribute]
        
        for characteristic in service.characteristics {
            
            attributes += Attribute.fromCharacteristic(characteristic, handle: newHandle())
            
            lastHandle = attributes.last!.handle
        }
        
        let group = AttributeGroup(attributes: attributes)
        
        attributeGroups.append(group)
    }
    
    /// Clear the database.
    public mutating func clear() {
        
        self.attributeGroups = []
    }
    
    /// Write the value to attribute specified by the handle.
    public mutating func write(value: Data, forAttribute handle: UInt16) {
        
        self[handle].value = value
    }
    
    /// The handle of the service at the specified index.
    public func serviceHandles(ofService index: Int) -> (start: UInt16, end: UInt16) {
        
        let service = attributeGroups[index]
        
        return (service.startHandle, service.endHandle)
    }
    
    // MARK: - Subscripting
    
    /// The attribute with the specified handle.
    public private(set) subscript(handle: UInt16) -> Attribute {
        
        get {
            
            for group in attributeGroups {
                
                for attribute in group.attributes {
                    
                    guard attribute.handle != handle
                        else { return attribute }
                }
            }
            
            fatalError("Invalid handle \(handle)")
        }
        
        mutating set {
            
            for (groupIndex, group) in attributeGroups.enumerate() {
                
                for (attributeIndex, attribute) in group.attributes.enumerate() {
                    
                    guard attribute.handle != handle else {
                        
                        attributeGroups[groupIndex].attributes[attributeIndex] = newValue
                        
                        return
                    }
                }
            }
            
            fatalError("Invalid handle \(handle)")
        }
    }
    
    // MARK: - Private Methods
    
    private mutating func newHandle() -> UInt16 {
        
        // starts at 0x0001
        lastHandle += 1
        
        return lastHandle
    }
}

// MARK: - Supporting Types

public extension GATTDatabase {
    
    /// GATT Include Declaration
    public struct Include {
        
        /// Included service handle
        public var serviceHandle: UInt16
        
        /// End group handle
        public var endGroupHandle: UInt16
        
        /// Included Service UUID
        public var serviceUUID: Bluetooth.UUID
        
        public init(serviceHandle: UInt16, endGroupHandle: UInt16, serviceUUID: Bluetooth.UUID) {
            
            self.serviceHandle = serviceHandle
            self.endGroupHandle = endGroupHandle
            self.serviceUUID = serviceUUID
        }
        
        /// ATT Attribute Value
        private func toData() -> Data {
            
            let handleBytes = serviceHandle.littleEndianBytes
            
            let endGroupBytes = endGroupHandle.littleEndianBytes
            
            return Data(byteValue: [handleBytes.0, handleBytes.1, endGroupBytes.0, endGroupBytes.1] + serviceUUID.toData().byteValue)
        }
    }
    
    /// ATT Attribute
    public struct Attribute {
        
        public let handle: UInt16
        
        public let UUID: Bluetooth.UUID
        
        public let permissions: [Permission]
        
        public var value: Data
        
        /// Defualt initializer
        private init(handle: UInt16, UUID: Bluetooth.UUID, value: Data = Data(), permissions: [Permission] = []) {
            
            self.handle = handle
            self.UUID = UUID
            self.value = value
            self.permissions = permissions
        }
        
        /// Initialize attribute with a `Service`.
        private init(service: GATT.Service, handle: UInt16) {
            
            self.handle = handle
            self.UUID = GATT.UUID(primaryService: service.primary).toUUID()
            self.value = service.UUID.toData()
            self.permissions = [.Read] // Read only
        }
        
        /// Initialize attribute with an `Include Declaration`.
        private init(include: Include, handle: UInt16) {
            
            self.handle = handle
            self.UUID = GATT.UUID.Include.toUUID()
            self.value = include.toData()
            self.permissions = [.Read] // Read only
        }
        
        /// Initialize attributes from a `Characteristic`.
        private static func fromCharacteristic(characteristic: Characteristic, handle: UInt16) -> [Attribute] {
            
            var currentHandle = handle
            
            let declarationAttribute: Attribute = {
                
                let propertiesMask = characteristic.properties.optionsBitmask()
                let valueHandleBytes = (handle + 1).littleEndianBytes
                let value = [propertiesMask, valueHandleBytes.0, valueHandleBytes.1] + characteristic.UUID.toData().byteValue
                
                return Attribute(handle: currentHandle, UUID: GATT.UUID.Characteristic.toUUID(), value: Data(byteValue: value), permissions: [.Read])
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

// MARK: - Private Supporting Types

internal extension GATTDatabase {
    
    /// Internal Representation of a GATT Service. 
    ///
    ///- Note: For use with `GATTDatabase` only.
    internal struct AttributeGroup {
        
        var attributes: [Attribute] {
            
            willSet {
                
                assert(attributes.count == newValue.count, "Cannot modify Service structure")
            }
        }
        
        var startHandle: UInt16 {
            
            return attributes[0].handle
        }
        
        var endHandle: UInt16 {
            
            return attributes.last!.handle
        }
        
        var service: Attribute {
            
            return attributes[0]
        }
    }
}

// MARK: - Typealiases

public extension GATT {
    
    public typealias Database = GATTDatabase
}

public extension GATTDatabase {
    
    public typealias Service = GATT.Service
    public typealias Characteristic = GATT.Characteristic
    public typealias Descriptor = GATT.Descriptor
    public typealias Permission = GATT.Permission
}
