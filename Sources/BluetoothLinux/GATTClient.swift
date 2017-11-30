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
    public let connection: ATTConnection
    
    // MARK: - Initialization
    
    public init(socket: L2CAPSocket) {
        
        self.connection = ATTConnection(socket: socket)
        
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
    
    
}
