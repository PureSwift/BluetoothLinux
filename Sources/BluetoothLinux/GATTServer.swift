//
//  GATTServer.swift
//  BluetoothLinux
//
//  Created by Alsey Coleman Miller on 2/29/16.
//  Copyright © 2016 PureSwift. All rights reserved.
//

public final class GATTServer {
    
    // MARK: - Properties
    
    public var log: (String -> ())?
    
    public var database: GATTDatabase
    
    public let connection: ATTConnection
    
    // MARK: - Initialization
    
    public init() {
        
        self.database = GATTDatabase()
        
        self.connection = ATTConnection()
        
        self.registerATTHandlers()
    }
    
    // MARK: - Private Methods
    
    private func registerATTHandlers() {
        
        // Exchange MTU
        connection.register(exchangeMTU)
        
        // Read By Group Type
        connection.register(readByGroupType)
        
        // Read By Type
        connection.register(readByType)
        
        // Find Information
        
    }
    
    private func errorResponse(opcode: ATTOpcode, _ error: ATTError, _ handle: UInt16 = 0) {
        
        log?("Error \(error) - \(opcode) (\(handle))")
        
        connection.sendError(opcode, error: error, handle: handle)
    }
    
    private func respond<T: ATTProtocolDataUnit>(response: T) {
        
        log?("Response: \(response)")
        
        connection.send(response) { _ in }
    }
    
    // MARK: Callbacks
    
    private func exchangeMTU(pdu: ATTMaximumTransmissionUnitRequest) {
        
        let serverMTU = UInt16(connection.maximumTransmissionUnit)
        
        let finalMTU = max(min(pdu.clientMTU, serverMTU), UInt16(ATT.MTU.LowEnergy.Default))
        
        /* Respond with the server MTU */
        connection.send(ATTMaximumTranssmissionUnitResponse(serverMTU: serverMTU)) { _ in }
        
        /* Set MTU to be the minimum */
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
                
        guard let response = ATTReadByGroupTypeResponse(attributeDataList: attributeData)
            else { fatalError("Could not create ATTReadByGroupTypeResponse. Attribute Data: \(attributeData)") }
        
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
            else { fatalError("Could not create ATTReadByTypeResponse. Attribute Data: \(attributeData)") }
        
        respond(response)
    }
    
    
}

