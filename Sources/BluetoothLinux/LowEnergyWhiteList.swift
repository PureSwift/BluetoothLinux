//
//  LowEnergyWhiteList.swift
//  BluetoothLinux
//
//  Created by Alsey Coleman Miller on 11/29/17.
//  Copyright © 2017 PureSwift. All rights reserved.
//

#if os(Linux)
    import Glibc
    import CSwiftBluetoothLinux
#elseif os(macOS) || os(iOS)
    import Darwin.C
#endif

import Foundation
import Bluetooth

public extension Adapter {
    
    /// LE Read White List Size Command
    ///
    /// Used to read the total number of white list entries that can be stored in the Controller.
    public func lowEnergyReadWhiteListSize(commandTimeout timeout: Int = 1000) throws -> Int {
        
        let sizeReturnParameter = try deviceRequest(LowEnergyCommand.readWhiteListSize, timeout: timeout)
        
        return Int(sizeReturnParameter.size)
    }
}
