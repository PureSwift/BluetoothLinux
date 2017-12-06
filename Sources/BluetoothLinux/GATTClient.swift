//
//  GATTClient.swift
//  BluetoothLinux
//
//  Created by Alsey Coleman Miller on 2/29/16.
//  Copyright © 2016 PureSwift. All rights reserved.
//

import Foundation
import Bluetooth

/// GATT Client
public final class GATTClient {
    
    // MARK: - Properties
    
    public var log: ((String) -> ())?
    
    public var database = GATTDatabase()
    
    // Don't modify
    @_versioned
    internal let connection: ATTConnection
    
    // MARK: - Initialization
    
    deinit {
        
        self.connection.unregisterAll()
    }
    
    public init(socket: L2CAPSocket,
                maximumTransmissionUnit: Int = ATT.MTU.LowEnergy.Default,
                log: ((String) -> ())? = nil) {
        
        self.connection = ATTConnection(socket: socket)
        self.connection.maximumTransmissionUnit = maximumTransmissionUnit
        self.log = log
        self.registerATTHandlers()
        
        // queue MTU exchange
        self.exchangeMTU()
    }
    
    // MARK: - Methods
    
    /// Performs the actual IO for recieving data.
    @inline(__always)
    public func read() throws {
        
        try connection.read()
    }
    
    /// Performs the actual IO for sending data.
    @inline(__always)
    public func write() throws -> Bool {
        
        return try connection.write()
    }
    
    // MARK: Requests
    
    /// Discover All Primary Services
    ///
    /// This sub-procedure is used by a client to discover all the primary services on a server.
    ///
    /// - Parameter completion: The completion closure.
    public func discoverAllPrimaryServices(completion: @escaping (GATTClientResponse<[Service]>) -> ()) {
        
        /// The Attribute Protocol Read By Group Type Request shall be used with 
        /// the Attribute Type parameter set to the UUID for «Primary Service». 
        /// The Starting Handle shall be set to 0x0001 and the Ending Handle shall be set to 0xFFFF.
        discoverServices(start: 0x0001, end: 0xFFFF, primary: true, completion: completion)
    }
    
    /// Discover Primary Service by Service UUID
    /// 
    /// This sub-procedure is used by a client to discover a specific primary service on a server
    /// when only the Service UUID is known. The specific primary service may exist multiple times on a server. 
    /// The primary service being discovered is identified by the service UUID.
    ///
    /// - Parameter uuid: The UUID of the service to find.
    /// - Parameter completion: The completion closure.
    public func discoverPrimaryServices(by uuid: BluetoothUUID,
                                        completion: @escaping (GATTClientResponse<[Service]>) -> ()) {
        
        // The Attribute Protocol Find By Type Value Request shall be used with the Attribute Type
        // parameter set to the UUID for «Primary Service» and the Attribute Value set to the 16-bit
        // Bluetooth UUID or 128-bit UUID for the specific primary service. 
        // The Starting Handle shall be set to 0x0001 and the Ending Handle shall be set to 0xFFFF.
        discoverServices(uuid: uuid, start: 0x0001, end: 0xFFFF, primary: true, completion: completion)
    }
    
    /// Discover All Characteristics of a Service
    /// 
    /// This sub-procedure is used by a client to find all the characteristic declarations within 
    /// a service definition on a server when only the service handle range is known.
    /// The service specified is identified by the service handle range.
    public func discoverAllCharacteristics(of service: Service,
                                           completion: @escaping (GATTClientResponse<[Characteristic]>) -> ()) {
        
        // The Attribute Protocol Read By Type Request shall be used with the Attribute Type
        // parameter set to the UUID for «Characteristic» The Starting Handle shall be set to 
        // starting handle of the specified service and the Ending Handle shall be set to the 
        // ending handle of the specified service.
        
        discoverCharacteristics(service: service, completion: completion)
    }
    
    /// Discover Characteristics by UUID
    /// 
    /// This sub-procedure is used by a client to discover service characteristics on a server when 
    /// only the service handle ranges are known and the characteristic UUID is known. 
    /// The specific service may exist multiple times on a server. 
    /// The characteristic being discovered is identified by the characteristic UUID.
    public func discoverCharacteristics(of service: Service,
                                        by uuid: BluetoothUUID,
                                        completion: @escaping (GATTClientResponse<[Characteristic]>) -> ()) {
        
        // The Attribute Protocol Read By Type Request is used to perform the beginning of the sub-procedure.
        // The Attribute Type is set to the UUID for «Characteristic» and the Starting Handle and Ending Handle
        // parameters shall be set to the service handle range.
        
        discoverCharacteristics(uuid: uuid, service: service, completion: completion)
    }
    
    // MARK: - Private Methods
    
    @inline(__always)
    private func registerATTHandlers() {
        
        // value confirmation
        
    }
    
    @inline(__always)
    private func send <Request: ATTProtocolDataUnit, Response: ATTProtocolDataUnit> (_ request: Request, response: @escaping (ATTResponse<Response>) -> ()) {
        
        log?("Request: \(request)")
        
        let callback: (AnyATTResponse) -> () = { response(ATTResponse<Response>($0)) }
        
        let responseType: ATTProtocolDataUnit.Type = Response.self
        
        guard let _ = connection.send(request, response: (callback, responseType))
            else { fatalError("Could not add PDU to queue: \(request)") }
    }
    
    // MARK: Requests
    
    private func exchangeMTU() {
        
        let clientMTU = UInt16(self.connection.maximumTransmissionUnit)
        
        let pdu = ATTMaximumTransmissionUnitRequest(clientMTU: clientMTU)
        
        send(pdu, response: { [unowned self] in self.exchangeMTUResponse($0) })
    }
    
    private func discoverServices(uuid: BluetoothUUID? = nil,
                                  start: UInt16 = 0x0001,
                                  end: UInt16 = 0xffff,
                                  primary: Bool = true,
                                  completion: @escaping (GATTClientResponse<[Service]>) -> ()) {
        
        let serviceType = GATT.UUID(primaryService: primary)
        
        let operation = DiscoveryOperation<Service>(uuid: uuid,
                                                  start: start,
                                                  end: end,
                                                  type: serviceType,
                                                  foundData: [],
                                                  completion: completion)
        
        if let uuid = uuid {
            
            let pdu = ATTFindByTypeRequest(startHandle: start,
                                           endHandle: end,
                                           attributeType: serviceType.rawValue,
                                           attributeValue: [UInt8](uuid.littleEndian.data))
            
            send(pdu) { [unowned self] in self.findByType($0, operation: operation) }
            
        } else {
            
            let pdu = ATTReadByGroupTypeRequest(startHandle: start,
                                                endHandle: end,
                                                type: serviceType.uuid)
            
            send(pdu) { [unowned self] in self.readByGroupType($0, operation: operation) }
        }
    }
    
    private func discoverCharacteristics(uuid: BluetoothUUID? = nil,
                                         service: Service,
                                         completion: @escaping (GATTClientResponse<[Characteristic]>) -> ()) {
        
        let attributeType = GATT.UUID.characteristic
        
        let operation = DiscoveryOperation<Characteristic>(uuid: uuid,
                                                           start: service.handle,
                                                           end: service.end,
                                                           type: attributeType,
                                                           foundData: [],
                                                           completion: completion)
        
        if let uuid = uuid {
            
            
            
        } else {
            
            let pdu = ATTReadByTypeRequest(startHandle: service.handle,
                                           endHandle: service.end,
                                           attributeType: attributeType.uuid)
            
            send(pdu) { [unowned self] in self.readByType($0, operation: operation) }
        }
    }
    
    // MARK: - Callbacks
    
    private func exchangeMTUResponse(_ response: ATTResponse<ATTMaximumTransmissionUnitResponse>) {
        
        switch response {
            
        case let .error(error):
            
            log?("Could not exchange MTU: \(error)")
            
        case let .value(pdu):
            
            let finalMTU = Int(pdu.serverMTU)
            
            let currentMTU = self.connection.maximumTransmissionUnit
            
            log?("MTU Exchange (\(currentMTU) -> \(finalMTU))")
            
            self.connection.maximumTransmissionUnit = finalMTU
        }
    }
    
    private func readByGroupType(_ response: ATTResponse<ATTReadByGroupTypeResponse>, operation: DiscoveryOperation<Service>) {
        
        // Read By Group Type Response returns a list of Attribute Handle, End Group Handle, and Attribute Value tuples
        // corresponding to the services supported by the server. Each Attribute Value contained in the response is the 
        // Service UUID of a service supported by the server. The Attribute Handle is the handle for the service declaration.
        // The End Group Handle is the handle of the last attribute within the service definition. 
        // The Read By Group Type Request shall be called again with the Starting Handle set to one greater than the 
        // last End Group Handle in the Read By Group Type Response.
        
        switch response {
            
        case let .error(errorResponse):
            
            operation.error(errorResponse)
            
        case let .value(pdu):
            
            var operation = operation
            
            // store PDU values
            for serviceData in pdu.data {
                
                guard let serviceUUID = BluetoothUUID(littleEndianData: serviceData.value)
                    else { operation.completion(.error(Error.invalidResponse(pdu))); return }
                
                let service = Service(uuid: serviceUUID,
                                      type: operation.type,
                                      handle: serviceData.attributeHandle,
                                      end: serviceData.endGroupHandle)
                
                operation.foundData.append(service)
            }
            
            // get more if possible
            let lastEnd = pdu.data.last?.endGroupHandle ?? 0x00
            
            // prevent infinite loop
            guard lastEnd >= operation.start
                else { operation.completion(.error(Error.invalidResponse(pdu))); return }
            
            operation.start = lastEnd + 1
            
            if lastEnd < operation.end {
                
                let pdu = ATTReadByGroupTypeRequest(startHandle: operation.start,
                                                    endHandle: operation.end,
                                                    type: operation.type.uuid)
                
                send(pdu) { [unowned self] in self.readByGroupType($0, operation: operation) }
                
            } else {
                
                operation.success()
            }
        }
    }
    
    private func findByType(_ response: ATTResponse<ATTFindByTypeResponse>, operation: DiscoveryOperation<Service>) {
        
        // Find By Type Value Response returns a list of Attribute Handle ranges. 
        // The Attribute Handle range is the starting handle and the ending handle of the service definition.
        // If the Attribute Handle range for the Service UUID being searched is returned and the End Found Handle 
        // is not 0xFFFF, the Find By Type Value Request may be called again with the Starting Handle set to one 
        // greater than the last Attribute Handle range in the Find By Type Value Response.
        
        switch response {
            
        case let .error(errorResponse):
            
            operation.error(errorResponse)
            
        case let .value(pdu):
            
            guard let serviceUUID = operation.uuid
                else { fatalError("Should have UUID specified") }
            
            var operation = operation
            
            // pre-allocate array
            operation.foundData.reserveCapacity(operation.foundData.count + pdu.handlesInformationList.count)
            
            // store PDU values
            for serviceData in pdu.handlesInformationList {
                
                let service = Service(uuid: serviceUUID,
                                      type: operation.type,
                                      handle: serviceData.foundAttribute,
                                      end: serviceData.groupEnd)
                
                operation.foundData.append(service)
            }
            
            // get more if possible
            let lastEnd = pdu.handlesInformationList.last?.groupEnd ?? 0x00
            
            operation.start = lastEnd + 1
            
            // need to continue scanning
            if lastEnd < operation.end {
                
                let pdu = ATTFindByTypeRequest(startHandle: operation.start,
                                               endHandle: operation.end,
                                               attributeType: operation.type.rawValue,
                                               attributeValue: serviceUUID.littleEndianData)
                
                send(pdu, response: { [unowned self] in self.findByType($0, operation: operation) })
                
            } else {
                
                operation.success()
            }
        }
    }
    
    private func readByType( _ response: ATTResponse<ATTReadByTypeResponse>, operation: DiscoveryOperation<Characteristic>) {
        
        // Read By Type Response returns a list of Attribute Handle and Attribute Value pairs corresponding to the
        // characteristics in the service definition. The Attribute Handle is the handle for the characteristic declaration. 
        // The Attribute Value is the Characteristic Properties, Characteristic Value Handle and Characteristic UUID. 
        // The Read By Type Request shall be called again with the Starting Handle set to one greater than the last 
        // Attribute Handle in the Read By Type Response.
        
        switch response {
            
        case let .error(errorResponse):
            
            operation.error(errorResponse)
            
        case let .value(pdu):
            
            var operation = operation
            
            // pre-allocate array
            operation.foundData.reserveCapacity(operation.foundData.count + pdu.data.count)
            
            // parse pdu data
            for characteristicData in pdu.data {
                
                let handle = characteristicData.handle
                
                guard let declaration = CharacteristicDeclaration(littleEndian: characteristicData.value)
                    else { operation.completion(.error(Error.invalidResponse(pdu))); return }
                
                let characteristic = Characteristic(uuid: declaration.uuid,
                                                    properties: declaration.properties,
                                                    handle: (handle, declaration.valueHandle))
                
                operation.foundData.append(characteristic)
            }
            
            // get more if possible
            let lastEnd = pdu.data.last?.handle ?? 0x00
            
            // prevent infinite loop
            guard lastEnd >= operation.start
                else { operation.completion(.error(Error.invalidResponse(pdu))); return }
            
            operation.start = lastEnd + 1
            
            // need to continue discovery
            if lastEnd != 0, operation.start < operation.end {
                
                let pdu = ATTReadByTypeRequest(startHandle: operation.start,
                                               endHandle: operation.end,
                                               attributeType: operation.type.uuid)
                
                send(pdu, response: { [unowned self] in self.readByType($0, operation: operation) })
                
            } else {
                
                operation.success()
            }
        }
    }
}

// MARK: - Supporting Types

public extension GATTClient {
    
    public typealias Error = GATTClientError
    
    public typealias Response<Value> = GATTClientResponse<Value>
}

public enum GATTClientError: Error {
    
    /// The GATT server responded with an error response.
    case errorResponse(ATTErrorResponse)
    
    /// The GATT server responded with a PDU that has invalid values.
    case invalidResponse(ATTProtocolDataUnit)
}

public enum GATTClientResponse <Value> {
    
    case error(Swift.Error)
    case value(Value)
}

public extension GATTClient {
    
    /// A discovered service.
    public struct Service {
        
        public let uuid: BluetoothUUID
        
        public let type: GATT.UUID
        
        public let handle: UInt16
        
        public let end: UInt16
    }
    
    public struct Characteristic {
        
        public typealias Property = GATT.CharacteristicProperty
        
        public let uuid: BluetoothUUID
        
        public let properties: Set<Property>
        
        public let handle: (declaration: UInt16, value: UInt16)
    }
}

// MARK: - Private Supporting Types

private extension GATTClient {
    
    struct DiscoveryOperation <T> {
        
        let uuid: BluetoothUUID?
        
        var start: UInt16
        
        let end: UInt16
        
        let type: GATT.UUID
        
        var foundData = [T]()
        
        let completion: (GATTClientResponse<[T]>) -> ()
        
        @inline(__always)
        func success() {
            
            completion(.value(foundData))
        }
        
        @inline(__always)
        func error(_ responseError: ATTErrorResponse) {
            
            if responseError.errorCode == .attributeNotFound,
                foundData.isEmpty == false {
                
                success()
                
            } else {
                
                completion(.error(Error.errorResponse(responseError)))
            }
        }
    }
    
    /// A characteristic declaration is an Attribute with the Attribute Type set to 
    /// the UUID for «Characteristic» and Attribute Value set to the Characteristic Properties,
    /// Characteristic Value Attribute Handle and Characteristic UUID. 
    /// The Attribute Permissions shall be readable and not require authentication or authorization.
    struct CharacteristicDeclaration {
        
        typealias Property = GATT.CharacteristicProperty
        
        /// Characteristic Properties
        ///
        /// Bit field of characteristic properties.
        var properties: Set<Property>
        
        /// Characteristic Value Handle
        /// 
        /// Handle of the Attribute containing the value of this characteristic.
        var valueHandle: UInt16
        
        /// Characteristic UUID
        /// 
        /// 16-bit Bluetooth UUID or 128-bit UUID for Characteristic Value.
        var uuid: BluetoothUUID
        
        init?(littleEndian bytes: [UInt8]) {
            
            guard let length = Length(rawValue: bytes.count)
                else { return nil }
            
            let properties = Property.from(flags: bytes[0])
            
            let valueHandle = UInt16(littleEndian: UInt16(bytes: (bytes[1], bytes[2])))
            
            let uuid: BluetoothUUID
            
            switch length {
                
            case .uuid16Bit:
                
                let value = UInt16(bytes: (bytes[3], bytes[4]))
                
                uuid = .bit16(UInt16(littleEndian: value))
                
            case .uuid128Bit:
                
                let value = UInt128(data: Data(bytes.suffix(from: 5)))!
                
                uuid = .bit128(UInt128(littleEndian: value))
            }
            
            self.properties = properties
            self.valueHandle = valueHandle
            self.uuid = uuid
        }
        
        private enum Length: Int {
            
            case uuid16Bit      = 5 // (1 + 2 + 2)
            case uuid128Bit     = 19 // (1 + 2 + 16)
        }
    }
}
