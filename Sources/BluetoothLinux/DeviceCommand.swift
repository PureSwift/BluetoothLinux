//
//  DeviceCommand.swift
//  BluetoothLinux
//
//  Created by Alsey Coleman Miller on 3/2/16.
//  Copyright © 2016 PureSwift. All rights reserved.
//

#if os(Linux)
    import Glibc
#elseif os(macOS) || os(iOS)
    import Darwin.C
#endif

import Foundation
import Bluetooth

public extension HostController {
    
    func deviceCommand<T: HCICommand>(_ command: T) throws {
        
        try HCISendCommand(internalSocket.fileDescriptor, command: command)
    }
    
    func deviceCommand<T: HCICommandParameter>(_ commandParameter: T) throws {
        
        let command = T.command
        
        let parameterData = commandParameter.data
        
        try HCISendCommand(internalSocket.fileDescriptor, command: command, parameterData: parameterData)
    }
}

// MARK: - Internal HCI Function

internal func HCISendCommand <T: HCICommand> (_ deviceDescriptor: CInt,
                             command: T,
                             parameterData: Data = Data()) throws {
    
    let packetType = HCIPacketType.command.rawValue
    
    let header = HCICommandHeader(command: command, parameterLength: UInt8(parameterData.count))
    
    /// data sent to host controller interface
    var data = [UInt8]([packetType]) + [UInt8](header.data) + [UInt8](parameterData)
    
    // write to device descriptor socket
    guard write(deviceDescriptor, &data, data.count) >= 0 // should we check if all data was written?
        else { throw POSIXError.fromErrno() }
}
