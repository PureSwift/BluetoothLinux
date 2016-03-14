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
    
    private func processReadByType() {
        
        
    }
    
    // MARK: Callbacks
    
    private func exchangeMTU(pdu: ATTMaximumTransmissionUnitRequest) {
        
        let serverMTU = UInt16(connection.maximumTransmissionUnit)
        
        let finalMTU = max(min(pdu.clientMTU, serverMTU), UInt16(ATT.MTU.LowEnergy.Default))
        
        /* Respond with the server MTU */
        connection.send(ATTMaximumTranssmissionUnitResponse(serverMTU: serverMTU)) { _ in }
        
        /* Set MTU to be the minimum */
        connection.maximumTransmissionUnit = Int(finalMTU)
        
        log?("MTU exchange complete, with MTU: \(finalMTU)")
    }
    
    private func readByGroupType(pdu: ATTReadByGroupTypeRequest) {
        
        let opcode = pdu.dynamicType.attributeOpcode
        
        log?("Read by Group Type - start: \(pdu.startHandle), end: \(pdu.endHandle)")
        
        // validate handles
        guard pdu.startHandle > 0 && pdu.endHandle > 0 else {
            
            let error = ATTErrorResponse(requestOpcode: opcode, attributeHandle: 0, error: .InvalidHandle)
            
            connection.send(error) { _ in }
            
            return
        }
        
        guard pdu.startHandle <= pdu.endHandle else {
            
            let error = ATTErrorResponse(requestOpcode: opcode, attributeHandle: pdu.startHandle, error: .InvalidHandle)
            
            connection.send(error) { _ in }
            
            return
        }
        
        // GATT defines that only the Primary Service and Secondary Service group types 
        // can be used for the "Read By Group Type" request. Return an error if any other group type is given.
        guard pdu.type == GATT.UUID.PrimaryService.UUID || pdu.type == GATT.UUID.SecondaryService.UUID else {
            
            let error = ATTErrorResponse(requestOpcode: opcode, attributeHandle: pdu.startHandle, error: .UnsupportedGroupType)
            
            connection.send(error) { _ in }
            
            return
        }
        
        let attributes = database.readByGroupType(handle: (pdu.startHandle, pdu.endHandle), type: pdu.type)
        
        guard attributes.isEmpty == false else {
            
            let error = ATTErrorResponse(requestOpcode: opcode, attributeHandle: pdu.startHandle, error: .AttributeNotFound)
            
            connection.send(error) { _ in }
            
            return
        }
        
        let attributeData = attributes.map { (attribute) -> ATTReadByGroupTypeResponse.AttributeData in
            
            guard let service = database.service(ofAttribute: attribute)
                else { fatalError("No service found for attribute in database. \(attribute)") }
            
            return ATTReadByGroupTypeResponse.AttributeData(attributeHandle: service.handles.0, endGroupHandle: service.handles.1, value: attribute.value)
        }
        
        guard let response = ATTReadByGroupTypeResponse(attributeDataList: attributeData)
            else { fatalError("Could not create ATTReadByGroupTypeResponse") }
        
        connection.send(response) { _ in }
    }
    
    private func readByType(pdu: ATTReadByTypeRequest) {
        
        let opcode = pdu.dynamicType.attributeOpcode
        
        log?("Read By Type - start: \(pdu.startHandle) end: \(pdu.endHandle)")
        
        guard pdu.startHandle != 0 && pdu.endHandle != 0
            else { connection.sendError(opcode, error: .InvalidHandle); return }
        
        guard (pdu.startHandle > pdu.endHandle) == false
            else { connection.sendError(opcode, error: .InvalidHandle, handle: pdu.startHandle); return }
        
        let attributes = database.readbyType(handle: (pdu.startHandle, pdu.endHandle), type: pdu.attributeType)
        
        guard attributes.isEmpty == false
            else { connection.sendError(opcode, error: .AttributeNotFound, handle: pdu.startHandle); return }
        
        
    }
}

