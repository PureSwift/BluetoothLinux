//
//  IOCTL.swift
//  BluetoothLinux
//
//  Created by Alsey Coleman Miller on 3/1/16.
//  Copyright © 2016 PureSwift. All rights reserved.
//

#if os(Linux)
    import Glibc
#elseif os(OSX) || os(iOS)
    import Darwin.C
#endif

internal struct IOC {
    
    static let NRBITS       = CInt(8)
    
    static let TYPEBITS     = CInt(8)
    
    static let SIZEBITS     = CInt(14)
    
    static let DIRBITS      = CInt(2)
    
    static let NRMASK       = CInt((1 << NRBITS)-1)
    
    static let TYPEMASK     = CInt((1 << TYPEBITS)-1)
    
    static let SIZEMASK     = CInt((1 << SIZEBITS)-1)
    
    static let DIRMASK      = CInt((1 << DIRBITS)-1)
    
    static let NRSHIFT      = CInt(0)
    
    static let TYPESHIFT    = CInt(NRSHIFT+NRBITS)
    
    static let SIZESHIFT    = CInt(TYPESHIFT+TYPEBITS)
    
    static let DIRSHIFT     = CInt(SIZESHIFT+SIZEBITS)
    
    static let NONE         = CUnsignedInt(0)
    
    static let WRITE        = CUnsignedInt(1)
    
    static let READ         = CUnsignedInt(2)
    
    @inline(__always)
    static func TYPECHECK<T>(_ type: T.Type) -> CInt {
        
        return CInt(MemoryLayout<T>.size)
    }
    
    /// #define _IOC(dir,type,nr,size) \
    /// (((dir)  << _IOC_DIRSHIFT) | \
    /// ((type) << _IOC_TYPESHIFT) | \
    /// ((nr)   << _IOC_NRSHIFT) | \
    /// ((size) << _IOC_SIZESHIFT))
    static func IOC(_ direction: CUnsignedInt, _ type: CInt,  _ nr: CInt, _ size: CInt) -> CUnsignedLong {
        
        let dir = CInt(direction)
        
        return CUnsignedLong(bitPattern: CLong(((dir) << DIRSHIFT) | ((type) << TYPESHIFT) | ((nr) << NRSHIFT) | ((size) << SIZESHIFT)))
    }
    
    @inline(__always)
    static func IOW<T>(_ type: CInt, _ nr: CInt, _ size: T.Type) -> CUnsignedLong {
        
        return IOC(WRITE, type, nr, TYPECHECK(size))
    }
    
    @inline(__always)
    static func IOR<T>(_ type: CInt, _ nr: CInt, _ size: T.Type) -> CUnsignedLong {
        
        return IOC(READ, type, nr, TYPECHECK(size))
    }
}

// MARK: - Darwin Stubs

#if os(OSX) || os(iOS)
        
    func swift_bluetooth_ioctl(_ fd: Int32, _ request: UInt, _ pointer: UnsafeMutablePointer<Void>) -> CInt { stub() }

#endif
