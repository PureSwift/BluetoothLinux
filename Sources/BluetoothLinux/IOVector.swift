//
//  IOVector.swift
//  BluetoothLinux
//
//  Created by Alsey Coleman Miller on 3/14/16.
//  Copyright © 2016 PureSwift. All rights reserved.
//

#if os(Linux)
    import Glibc
#elseif os(OSX) || os(iOS)
    import Darwin.C
#endif

public extension iovec {
    
    public init(byteValue: [UInt8]) {
        
        var vector = iovec()
        
        memcpy(&vector.iov_base, byteValue, byteValue.count)
        
        vector.iov_len = byteValue.count
        
        self = vector
    }
    
    public mutating func dealloc() {
        
        iov_base.dealloc(iov_len)
        iov_base = nil
        iov_len = 0
    }
}