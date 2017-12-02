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
                maximumTransmissionUnit: Int = ATT.MTU.LowEnergy.Default) {
        
        self.connection = ATTConnection(socket: socket)
        self.connection.maximumTransmissionUnit = maximumTransmissionUnit
        self.registerATTHandlers()
    }
    
    // MARK: - Methods
    
    /// Performs the actual IO for sending data.
    @inline(__always)
    public func read() throws {
        
        try connection.read()
    }
    
    /// Performs the actual IO for recieving data.
    @inline(__always)
    public func write() throws -> Bool {
        
        return try connection.write()
    }
    
    // MARK: Requests
    
    public func discoverServices(uuid: BluetoothUUID? = nil,
                                 start: UInt16 = 0x0001,
                                 end: UInt16 = 0xffff,
                                 primary: Bool = true) throws -> [(UUID: BluetoothUUID, primary: Bool)] {
        
        let serviceType = GATT.UUID(primaryService: primary)
        
        if let uuid = uuid {
            
            let pdu = ATTFindByTypeRequest(startHandle: start,
                                       endHandle: end,
                                       attributeType: serviceType.rawValue,
                                       attributeValue: uuid.littleEndian)
            
            send(pdu, response: <#T##(ATTProtocolDataUnit) -> ()#>)
            
        } else {
            
            let pdu = ATTReadByGroupTypeRequest(startHandle: start,
                                            endHandle: end,
                                            type: serviceType.toUUID())
            
            
        }
    }
    
    // MARK: - Private Methods
    
    @inline(__always)
    private func registerATTHandlers() {
        
        // Exchange MTU
        //let _ = connection.register(exchangeMTU)
        
        
    }
    
    @inline(__always)
    private func send<T: ATTProtocolDataUnit>(_ request: T, response: @escaping (T) -> ()) {
        
        log?("Request: \(request)")
        
        guard let _ = connection.send(PDU: request, response: response)
            else { fatalError("Could not add PDU to queue: \(request)") }
    }
    
    private func exchangeMTU() {
        
        let clientMTU = UInt16(self.connection.maximumTransmissionUnit)
        
        let pdu = ATTMaximumTransmissionUnitRequest(clientMTU: UInt16(self.connection.maximumTransmissionUnit))
        
        
        
    }
    
    // MARK: - Callbacks
    
    private func readByGroupType(pdu: ATTReadByGroupTypeResponse) {
        
        
    }
    
    private func findByType(pdu: ATTFindByTypeResponse) {
        
        
    }
}
