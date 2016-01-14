//
//  LowEnergyCommand.swift
//  BlueZ
//
//  Created by Alsey Coleman Miller on 1/14/16.
//  Copyright © 2016 PureSwift. All rights reserved.
//



public extension Bluetooth {
    
    public enum LowEnergyCommand: UInt16, HCICommand {
        
        public static let opcodeGroupField = OpcodeGroupField.LowEnergy
        
        case SetEventMask               = 0x0001
        case ReadBufferSize             = 0x0002
        case ReadLocalSupportedFeatures = 0x0003
        case SetRandomAddress           = 0x0005
    }
}