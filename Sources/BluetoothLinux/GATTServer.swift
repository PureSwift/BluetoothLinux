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
        
        
    }
}

