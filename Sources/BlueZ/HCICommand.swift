//
//  HCICommand.swift
//  BlueZ
//
//  Created by Alsey Coleman Miller on 1/3/16.
//  Copyright © 2016 PureSwift. All rights reserved.
//

import SwiftFoundation

public protocol HCICommand {
    
    /// Opcode Group Field of all commands of this type.
    static var opcodeGroupField: OpcodeGroupField { get }
    
    /// Opcode Command Field of this particular command.
    var opcodeCommandField: UInt16  { get }
}