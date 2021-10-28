//
//  BluetoothSocketAddress.swift
//  
//
//  Created by Alsey Coleman Miller on 27/10/21.
//

import Bluetooth
import SystemPackage

public protocol BluetoothSocketAddress: SocketAddress where ProtocolID == BluetoothSocketProtocol {
        
    static var protocolID: BluetoothSocketProtocol { get }
}
