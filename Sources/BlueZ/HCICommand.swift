//
//  HCICommand.swift
//  BlueZ
//
//  Created by Alsey Coleman Miller on 1/13/16.
//  Copyright © 2016 PureSwift. All rights reserved.
//

/// HCI Command that can be send to the Bluetooth Adapter.
public protocol HCICommand: RawRepresentable {
    
    static var opcodeGroupField: OpcodeGroupField { get }
    
    init?(rawValue: OpcodeCommandField)
    
    var rawValue: OpcodeCommandField { get }
}