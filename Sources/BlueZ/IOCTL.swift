//
//  IOCTL.swift
//  BlueZ
//
//  Created by Alsey Coleman Miller on 3/1/16.
//  Copyright © 2016 PureSwift. All rights reserved.
//

#if os(Linux)
    import CBlueZ
    import Glibc
#elseif os(OSX) || os(iOS)
    import Darwin.C
#endif

import SwiftFoundation

internal struct IOC {
    
    static let NRBITS       = CInt(8)
    
    static let TYPEBITS     = CInt(8)
    
    static let SIZEBITS     = CInt(14)
    
    static let DIRBITS      = CInt(2)
    
    static let NRMASK       = CInt((1 << IOC.NRBITS)-1)
    
    static let TYPEMASK     = CInt((1 << IOC.TYPEBITS)-1)
    
    static let SIZEMASK     = CInt((1 << IOC.SIZEBITS)-1)
    
    static let DIRMASK      = CInt((1 << IOC.DIRBITS)-1)
    
    static let NRSHIFT      = CInt(0)
    
    static let TYPESHIFT    = CInt(IOC.NRSHIFT+IOC.NRBITS)
    
    static let SIZESHIFT    = CInt(IOC.TYPESHIFT+IOC.TYPEBITS)
    
    static let DIRSHIFT     = CInt(IOC.SIZESHIFT+IOC.SIZEBITS)
    
    static let NONE         = CUnsignedInt(0)
    
    static let WRITE        = CUnsignedInt(1)
    
    static let READ         = CUnsignedInt(2)
    
    @inline(__always)
    static func TYPECHECK<T>(type: T.Type) -> CInt {
        
        return CInt(sizeof(type))
    }
    
    /// #define _IOC(dir,type,nr,size) \
    /// (((dir)  << _IOC_DIRSHIFT) | \
    /// ((type) << _IOC_TYPESHIFT) | \
    /// ((nr)   << _IOC_NRSHIFT) | \
    /// ((size) << _IOC_SIZESHIFT))
    static func IOC(direction: CUnsignedInt, _ type: CInt,  _ nr: CInt, _ size: CInt) -> CInt {
        
        let dir = CInt(direction)
        
        return (((dir) << DIRSHIFT) | ((type) << TYPESHIFT) | ((nr) << NRSHIFT) | ((size) << SIZESHIFT))
    }
    
    @inline(__always)
    static func IOW<T>(type: CInt, _ nr: CInt, _ size: T.Type) -> CInt {
        
        return IOC(WRITE, type, nr, TYPECHECK(size))
    }
    
    @inline(__always)
    static func IOR<T>(type: CInt, _ nr: CInt, _ size: T.Type) -> CInt {
        
        return IOC(READ, type, nr, TYPECHECK(size))
    }
}

// MARK: - Darwin Stubs

#if os(OSX) || os(iOS)
    
    func ioctl(d: CInt, _ request: CInt, _ varargs: Any...) { stub() }

#endif
