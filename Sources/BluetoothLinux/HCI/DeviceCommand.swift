//
//  DeviceCommand.swift
//  BluetoothLinux
//
//  Created by Alsey Coleman Miller on 3/2/16.
//  Copyright © 2016 PureSwift. All rights reserved.
//

import Foundation
import BluetoothHCI
import SystemPackage

public extension HostController {
    
    func deviceCommand<T: HCICommand>(_ command: T) async throws {
        try await socket.sendCommand(command)
    }
    
    func deviceCommand<T: HCICommandParameter>(_ commandParameter: T) async throws {
        try await socket.sendCommand(
            T.command,
            parameter: commandParameter.data
        )
    }
}
