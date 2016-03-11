//
//  GATTServer.swift
//  BluetoothLinux
//
//  Created by Alsey Coleman Miller on 2/29/16.
//  Copyright © 2016 PureSwift. All rights reserved.
//

public final class GATTServer {
    
    // MARK: - Properties
    
    public var log = false
    
    public var database = GATTDatabase()
    
    public var connection: ATTConnection
    
    // MARK: - Initialization
    
    public init(connection: ATTConnection) {
        
        self.connection = connection
        
        self.registerATTHandlers()
    }
    
    // MARK: - Private Methods
    
    @inline(__always)
    private func log(text: String) {
        
        if log { print(text) }
    }
    
    /// gatt_server_register_att_handlers()
    private func registerATTHandlers() {
        
        // Exchange MTU
        connection.register(exchangeMTU)
        
        // Read By Group Type
        connection.register(readByGroupType)
    }
    
    // MARK: Callbacks
    
    private func exchangeMTU(pdu: ATTMaximumTransmissionUnitRequest) {
        
        let serverMTU = UInt16(connection.maximumTransmissionUnit)
        
        let finalMTU = max(min(pdu.clientMTU, serverMTU), UInt16(ATT.MTU.LowEnergy.Default))
        
        /* Respond with the server MTU */
        connection.send(ATTMaximumTranssmissionUnitResponse(serverMTU: serverMTU)) { _ in }
        
        /* Set MTU to be the minimum */
        connection.maximumTransmissionUnit = Int(finalMTU)
        
        log("MTU exchange complete, with MTU: \(finalMTU)")
    }
    
    private func readByGroupType(pdu: ATTReadByGroupTypeRequest) {
        
        let opcode = pdu.dynamicType.attributeOpcode
        
        log("Read by Group Type - start: \(pdu.startHandle), end: \(pdu.endHandle)")
        
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
        
        // Use the first attribute to determine the length of each attribute data unit. 
        // Stop when a different attribute value is seen.
        
        //let attributeLength = min(min(connection.maximumTransmissionUnit - 6, 251),  attributes[0].value.count) + 4
        
        let attributeData = attributes.map { (attribute) in
            
            guard let service = database.service(ofAttribute: attribute)
                else { fatalError("No service found for attribute in database. \(attribute)") }
            
            return ATTReadByGroupTypeResponse.AttributeData(attributeHandle: service.attributes[0], endGroupHandle: 0, value: [])
        }
        
        guard let response = ATTReadByGroupTypeResponse(attributeDataList: attributeData)
            else { fatalError("Could not create ATTReadByGroupTypeResponse") }
        
        connection.send(response) { _ in }
    }
}

