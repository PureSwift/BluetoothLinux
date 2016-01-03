//
//  HCIEvent.swift
//  BlueZ
//
//  Created by Alsey Coleman Miller on 1/3/16.
//  Copyright © 2016 PureSwift. All rights reserved.
//

import SwiftFoundation

public protocol HCIEvent {
    
    /// Length of the command when encoded to data.
    ///
    /// - Note: Commands are a fixed length.
    static var dataLength: Byte { get }
    
    /// Initialize Event from data
    init(data: Data)
}