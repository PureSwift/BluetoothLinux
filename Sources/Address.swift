//
//  Address.swift
//  BlueZ
//
//  Created by Alsey Coleman Miller on 12/6/15.
//  Copyright © 2015 PureSwift. All rights reserved.
//

#if os(Linux)
    import CBlueZ
#endif

public extension BlueZ {
    
    public struct Address: ByteValue {
        
        // MARK: - Properties
        
        public var byteValue: bdaddr_t
        
        // MARK: - Initialization
        
        public init(bytes: bdaddr_t) {
        
            self.byteValue = bytes
        }
    }
}

