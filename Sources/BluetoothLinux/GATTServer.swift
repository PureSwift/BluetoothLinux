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
    
    public private(set) var database: GATTDatabase
    
    public let connection: ATTConnection
    
    // MARK: - Initialization
    
    public init(connection: ATTConnection, database: GATTDatabase) {
        
        self.connection = connection
        self.database = database
    }
    
    // MARK: - Private Methods
    
    private func log(text: String) {
        
        if log { print(text) }
    }
    
    /// gatt_server_register_att_handlers()
    private func registerATTHandlers() {
        
        // Exchange MTU
        connection.register(exchangeMTU)
        
        // Read By Group Type
        //connection.register(readByGroupType)
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
    
    /*
    private func readByGroupType(pdu: ATTReadByGroupTypeRequest) {
        
        
    }*/
}