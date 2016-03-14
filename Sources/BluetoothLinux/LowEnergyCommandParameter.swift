//
//  LowEnergyCommandParameter.swift
//  BluetoothLinux
//
//  Created by Alsey Coleman Miller on 1/14/16.
//  Copyright © 2016 PureSwift. All rights reserved.
//

public extension LowEnergyCommand {
    
    /// LE Set Advertising Data Command
    ///
    /// Used to set the data used in advertising packets that have a data field.
    ///
    /// - Note: Only the significant part of the Advertising Data is transmitted in the advertising packets.
    public struct SetAdvertisingDataParameter: HCICommandParameter {
        
        public static let command = LowEnergyCommand.SetAdvertisingData
        
        public static let length = 32
        
        /// The number of significant bytes.
        public var length: UInt8
        
        /// 31 octets of advertising data. 
        public var data: LowEnergyAdvertisingData
        
        public init(data: LowEnergyAdvertisingData, length: UInt8) {
            
            self.length = length
            self.data = data
        }
        
        public var byteValue: [UInt8] {
            
            return [length, data.0, data.1, data.2, data.3, data.4, data.5, data.6, data.7, data.8, data.9, data.10, data.11, data.12, data.13, data.14, data.15, data.16, data.17, data.18, data.19, data.20, data.21, data.22, data.23, data.24, data.25, data.26, data.27, data.28, data.29, data.30]
        }
    }
}


