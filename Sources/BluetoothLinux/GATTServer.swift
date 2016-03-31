//
//  GATTServer.swift
//  BluetoothLinux
//
//  Created by Alsey Coleman Miller on 2/29/16.
//  Copyright © 2016 PureSwift. All rights reserved.
//

import struct SwiftFoundation.UUID

public final class GATTServer {
    
    // MARK: - Properties
    
    public var log: (String -> ())?
    
    public var database = GATTDatabase()
    
    // MARK: - Private Properties
    
    private let connection = ATTConnection()
    
    // MARK: - Initialization
    
    public init(maximumTransmissionUnit: Int = ATT.MTU.LowEnergy.Default) {
        
        // set initial MTU and register handlers
        self.connection.maximumTransmissionUnit = maximumTransmissionUnit
        self.registerATTHandlers()
    }
    
    // MARK: - Methods
    
    /// Performs the actual IO for sending data.
    @inline(__always)
    public func read(socket: L2CAPSocket) throws {
        
        try connection.read(socket)
    }
    
    /// Performs the actual IO for recieving data.
    @inline(__always)
    public func write(socket: L2CAPSocket) throws {
        
        try connection.write(socket)
    }
    
    // MARK: - Private Methods
    
    @inline(__always)
    private func registerATTHandlers() {
        
        // Exchange MTU
        connection.register(exchangeMTU)
        
        // Read By Group Type
        connection.register(readByGroupType)
        
        // Read By Type
        connection.register(readByType)
        
        // Find Information
        connection.register(findInformation)
        
        // Find By Type Value
        connection.register(findByTypeValue)
    }
    
    private func errorResponse(opcode: ATT.Opcode, _ error: ATT.Error, _ handle: UInt16 = 0) {
        
        log?("Error \(error) - \(opcode) (\(handle))")
        
        connection.sendError(opcode, error: error, handle: handle)
    }
    
    @noreturn @inline(__always)
    private func fatalErrorResponse(message: String, _ opcode: ATT.Opcode, _ handle: UInt16 = 0) {
        
        errorResponse(opcode, ATT.Error.UnlikelyError, handle)
        
        fatalError(message)
    }
    
    private func respond<T: ATTProtocolDataUnit>(response: T) {
        
        log?("Response: \(response)")
        
        connection.send(response) { _ in }
    }
    
    // MARK: Callbacks
    
    private func exchangeMTU(pdu: ATTMaximumTransmissionUnitRequest) {
        
        let serverMTU = UInt16(connection.maximumTransmissionUnit)
        
        let finalMTU = max(min(pdu.clientMTU, serverMTU), UInt16(ATT.MTU.LowEnergy.Default))
        
        // Respond with the server MTU
        connection.send(ATTMaximumTranssmissionUnitResponse(serverMTU: serverMTU)) { _ in }
        
        // Set MTU to minimum
        connection.maximumTransmissionUnit = Int(finalMTU)
        
        log?("MTU exchange: \(pdu.clientMTU) -> \(finalMTU)")
    }
    
    private func readByGroupType(pdu: ATTReadByGroupTypeRequest) {
        
        typealias Attribute = ATTReadByGroupTypeResponse.AttributeData
        
        let opcode = pdu.dynamicType.attributeOpcode
        
        log?("Read by Group Type (\(pdu.startHandle) - \(pdu.endHandle))")
        
        // validate handles
        guard pdu.startHandle != 0 && pdu.endHandle != 0
            else { errorResponse(opcode, .InvalidHandle); return }
        
        guard pdu.startHandle <= pdu.endHandle
            else { errorResponse(opcode, .InvalidHandle, pdu.startHandle); return }
        
        // GATT defines that only the Primary Service and Secondary Service group types 
        // can be used for the "Read By Group Type" request. Return an error if any other group type is given.
        guard pdu.type == GATT.UUID.PrimaryService.UUID || pdu.type == GATT.UUID.SecondaryService.UUID
            else { errorResponse(opcode, .UnsupportedGroupType, pdu.startHandle); return }
        
        // search for only primary services
        let primary = pdu.type == GATT.UUID.PrimaryService.UUID
        
        print("Primary: \(primary)")
        
        let services = database.readByGroupType(pdu.startHandle ..< pdu.endHandle, primary: primary)
        
        guard services.isEmpty == false
            else { errorResponse(opcode, .AttributeNotFound, pdu.startHandle); return }
        
        var attributeData = [Attribute](count: services.count, repeatedValue: Attribute())
        
        for (index, service) in services.enumerate() {
            
            let serviceHandle = database.serviceHandle(index)
            
            // set values
            attributeData[index].attributeHandle = serviceHandle
            attributeData[index].endGroupHandle = serviceHandle + UInt16(service.characteristics.count)
            attributeData[index].value = service.UUID.byteValue
        }
                
        guard let response = ATTReadByGroupTypeResponse(data: attributeData)
            else { fatalErrorResponse("Could not create ATTReadByGroupTypeResponse. Attribute Data: \(attributeData)", opcode, pdu.startHandle) }
        
        respond(response)
    }
    
    private func readByType(pdu: ATTReadByTypeRequest) {
        
        typealias Attribute = ATTReadByTypeResponse.AttributeData
        
        let opcode = pdu.dynamicType.attributeOpcode
        
        log?("Read by Type (\(pdu.startHandle) - \(pdu.endHandle))")
        
        guard pdu.startHandle != 0 && pdu.endHandle != 0
            else { errorResponse(opcode, .InvalidHandle); return }
        
        guard pdu.startHandle <= pdu.endHandle
            else { errorResponse(opcode, .InvalidHandle, pdu.startHandle); return }
        
        let attributes = database.readByType(pdu.startHandle ..< pdu.endHandle, type: pdu.attributeType)
        
        guard attributes.isEmpty == false
            else { errorResponse(opcode, .AttributeNotFound, pdu.startHandle); return }
        
        var attributeData = [Attribute](count: attributes.count, repeatedValue: Attribute())
        
        for (index, attribute) in attributes.enumerate() {
            
            attributeData[index].handle = UInt16(index)
            attributeData[index].value = attribute.value
        }
        
        guard let response = ATTReadByTypeResponse(data: attributeData)
            else { fatalErrorResponse("Could not create ATTReadByTypeResponse. Attribute Data: \(attributeData)", opcode, pdu.startHandle) }
        
        respond(response)
    }
    
    private func findInformation(pdu: ATTFindInformationRequest) {
        
        typealias Data = ATTFindInformationResponse.Data
        
        typealias Format = ATTFindInformationResponse.Format
        
        let opcode = pdu.dynamicType.attributeOpcode
        
        log?("Find Information (\(pdu.startHandle) - \(pdu.endHandle))")
        
        guard pdu.startHandle != 0 && pdu.endHandle != 0
            else { errorResponse(opcode, .InvalidHandle); return }
        
        guard pdu.startHandle <= pdu.endHandle
            else { errorResponse(opcode, .InvalidHandle, pdu.startHandle); return }
        
        let attributes = database.findInformation(pdu.startHandle ..< pdu.endHandle)
        
        guard attributes.isEmpty == false
            else { errorResponse(opcode, .AttributeNotFound, pdu.startHandle); return }
        
        let format = Format(UUID: attributes[0].type)
        
        var bit16Pairs = [(UInt16, UInt16)]()
        
        var bit128Pairs = [(UInt16, UUID)]()
        
        for (index, attribute) in attributes.enumerate() {
            
            // truncate if bigger than MTU
            let encodedLength = 2 + ((index + 1) * format.length)
            
            guard encodedLength <= connection.maximumTransmissionUnit
                else { break }
            
            // encode attribute
            switch (attribute.type, format) {
                
            case let (.Bit16(type), .Bit16):
                
                bit16Pairs.append((attribute.handle, type))
                
            case let (.Bit128(type), .Bit128):
                
                bit128Pairs.append((attribute.handle, type))
                
            default: break // mismatching types
            }
        }
        
        let data: Data
        
        switch format {
        case .Bit16: data = .Bit16(bit16Pairs)
        case .Bit128: data = .Bit128(bit128Pairs)
        }
        
        let response = ATTFindInformationResponse(data: data)
        
        respond(response)
    }
    
    private func findByTypeValue(pdu: ATTFindByTypeRequest) {
        
        typealias Handle = ATTFindByTypeResponse.HandlesInformation
        
        let opcode = pdu.dynamicType.attributeOpcode
        
        log?("Find By Type Value (\(pdu.startHandle) - \(pdu.endHandle)) (\(pdu.attributeType))")
        
        guard pdu.startHandle != 0 && pdu.endHandle != 0
            else { errorResponse(opcode, .InvalidHandle); return }
        
        guard pdu.startHandle <= pdu.endHandle
            else { errorResponse(opcode, .InvalidHandle, pdu.startHandle); return }
        
        let handles = database.findByTypeValue(pdu.startHandle ..< pdu.endHandle, type: pdu.attributeType, value: pdu.attributeValue)
        
        guard handles.isEmpty == false
            else { errorResponse(opcode, .AttributeNotFound, pdu.startHandle); return }
        
        let handlesInformation = handles.map { Handle(foundAttribute: $0.0, groupEnd: $0.1) }
        
        let response = ATTFindByTypeResponse(handlesInformationList: handlesInformation)
        
        respond(response)
    }
}

