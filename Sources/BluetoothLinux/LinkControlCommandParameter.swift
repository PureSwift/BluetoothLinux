//
//  LinkControlCommandParameter.swift
//  BluetoothLinux
//
//  Created by Alsey Coleman Miller on 1/14/16.
//  Copyright © 2016 PureSwift. All rights reserved.
//

#if os(Linux)
    import Glibc
#elseif os(OSX) || os(iOS)
    import Darwin.C
#endif

public extension LinkControlCommand {
    
    public struct InquiryParameter {
        
        public static let length = 5
        
        public var lap: (UInt8, UInt8, UInt8) = (0, 0, 0)
        
        public var length: UInt8 = 0 /* 1.28s units */
        
        public var count: UInt8 = 0
        
        public init() { }
    }
}
