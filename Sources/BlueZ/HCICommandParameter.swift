//
//  HCICommand.swift
//  BlueZ
//
//  Created by Alsey Coleman Miller on 1/3/16.
//  Copyright © 2016 PureSwift. All rights reserved.
//

import typealias SwiftFoundation.Byte

/// HCI Command Parameter Data.
///
///- Note: Only C packed structs from the BlueZ library should adopt this protocol.
public protocol HCICommandParameter {
    
    /// Length of the command when encoded to data. 
    ///
    /// - Note: Commands are a fixed length.
    static var dataLength: CInt { get }
}


