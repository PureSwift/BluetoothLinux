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
        
        let length = byteValue.count
        var vector = iovec()
        vector.iov_len = length
        vector.iov_base = UnsafeMutablePointer<Void>.init(allocatingCapacity: length)
        
        memcpy(vector.iov_base, byteValue, length)
        
        self = vector
    }
}
