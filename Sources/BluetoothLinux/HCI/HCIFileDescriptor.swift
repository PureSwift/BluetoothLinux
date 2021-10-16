//
//  HCIFileDescriptor.swift
//  
//
//  Created by Alsey Coleman Miller on 16/10/21.
//

import Foundation
import Bluetooth
import BluetoothHCI
import SystemPackage

internal extension FileDescriptor {
    
    func sendCommand<Command: HCICommand>(
        _ command: Command,
        parameter parameterData: Data = Data()
    ) throws {
        // build data buffer to write
        assert(parameterData.count <= UInt8.max)
        let header = HCICommandHeader(
            command: command,
            parameterLength: UInt8(parameterData.count)
        )
        let dataLength = 1 + HCICommandHeader.length + parameterData.count
        var data = Data(capacity: dataLength)
        data.append(HCIPacketType.command.rawValue)
        data.append(header.data)
        if parameterData.isEmpty == false {
            data.append(parameterData)
        }
        assert(data.count == dataLength)
        // write data to socket
        try writeAll(data)
    }
}
