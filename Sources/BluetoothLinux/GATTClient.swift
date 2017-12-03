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
    public func discoverAllPrimaryServices() {
        
        /// The Attribute Protocol Read By Group Type Request shall be used with 
        /// the Attribute Type parameter set to the UUID for «Primary Service». 
        /// The Starting Handle shall be set to 0x0001 and the Ending Handle shall be set to 0xFFFF.
        discoverServices(start: 0x0001, end: 0xFFFF, primary: true)
    }
    
    // MARK: - Private Methods
    
    @inline(__always)
    private func registerATTHandlers() {
        
        // Exchange MTU
        //let _ = connection.register(exchangeMTU)
        
        
    }
    
    @inline(__always)
    private func send <Request: ATTProtocolDataUnit, Response: ATTProtocolDataUnit> (_ request: Request, response: @escaping (Response) -> ()) {
        
        log?("Request: \(request)")
        
        let callback: (ATTProtocolDataUnit) -> () = { response($0 as! Response)  }
        
        let responseType: ATTProtocolDataUnit.Type = Response.self
        
        guard let _ = connection.send(request, response: (callback, responseType))
            else { fatalError("Could not add PDU to queue: \(request)") }
    }
    
    // MARK: Requests
    
    private func exchangeMTU() {
        
        let clientMTU = UInt16(self.connection.maximumTransmissionUnit)
        
        let pdu = ATTMaximumTransmissionUnitRequest(clientMTU: clientMTU)
        
        
        
    }
    
    private func discoverServices(uuid: BluetoothUUID? = nil,
                                  start: UInt16 = 0x0001,
                                  end: UInt16 = 0xffff,
                                  primary: Bool = true) {
        
        let serviceType = GATT.UUID(primaryService: primary)
        
        if let uuid = uuid {
            
            let pdu = ATTFindByTypeRequest(startHandle: start,
                                           endHandle: end,
                                           attributeType: serviceType.rawValue,
                                           attributeValue: uuid.littleEndian)
            
            send(pdu, response: findByType)
            
        } else {
            
            let pdu = ATTReadByGroupTypeRequest(startHandle: start,
                                                endHandle: end,
                                                type: serviceType.toUUID())
            
            send(pdu, response: readByGroupType)
        }
    }
    
    private func discoveryComplete() {
        
        
    }
    
    // MARK: - Callbacks
    
    private func readByGroupType(pdu: ATTReadByGroupTypeResponse) {
        
        // Read By Group Type Response returns a list of Attribute Handle, End Group Handle, and Attribute Value tuples
        // corresponding to the services supported by the server. Each Attribute Value contained in the response is the 
        // Service UUID of a service supported by the server. The Attribute Handle is the handle for the service declaration.
        // The End Group Handle is the handle of the last attribute within the service definition. 
        // The Read By Group Type Request shall be called again with the Starting Handle set to one greater than the 
        // last End Group Handle in the Read By Group Type Response.
        
        let lastEnd = pdu.data.last?.endGroupHandle ?? 0x00
        
        print(pdu)
    }
    
    private func findByType(pdu: ATTFindByTypeResponse) {
        
        
    }
}
