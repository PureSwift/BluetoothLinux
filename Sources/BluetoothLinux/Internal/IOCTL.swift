//
//  IOCTL.swift
//  BluetoothLinux
//
//  Created by Alsey Coleman Miller on 3/1/16.
//  Copyright © 2016 PureSwift. All rights reserved.
//

/// #define _IOC(dir,type,nr,size) \
/// (((dir)  << _IOC_DIRSHIFT) | \
/// ((type) << _IOC_TYPESHIFT) | \
/// ((nr)   << _IOC_NRSHIFT) | \
/// ((size) << _IOC_SIZESHIFT))
@usableFromInline
internal func _IOC(
    _ direction: IOCDirection,
    _ type: IOCType,
    _ nr: CInt,
    _ size: CInt
) -> CUnsignedLong {
    
    let dir = CInt(direction.rawValue)
    let dirValue = dir << _DIRSHIFT
    let typeValue = type.rawValue << _TYPESHIFT
    let nrValue = nr << _NRSHIFT
    let sizeValue = size << _SIZESHIFT
    let value = CLong(dirValue | typeValue | nrValue | sizeValue)
    return CUnsignedLong(bitPattern: value)
}

@usableFromInline
internal func _IOW<T>(_ type: IOCType, _ nr: CInt, _ size: T.Type) -> CUnsignedLong {
    return _IOC(.write, type, nr, _TYPECHECK(size))
}

@usableFromInline
internal func _IOR<T>(_ type: IOCType, _ nr: CInt, _ size: T.Type) -> CUnsignedLong {
    return _IOC(.read, type, nr, _TYPECHECK(size))
}

@usableFromInline
internal func _TYPECHECK<T>(_ type: T.Type) -> CInt {
    return CInt(MemoryLayout<T>.size)
}

@usableFromInline
internal enum IOCDirection: CUnsignedInt {
    
    case none   = 0
    case write  = 1
    case read   = 2
}

@usableFromInline
internal struct IOCType: RawRepresentable, Equatable, Hashable {
    
    public let rawValue: CInt
    
    public init(rawValue: CInt) {
        self.rawValue = rawValue
    }
}

extension IOCType: ExpressibleByUnicodeScalarLiteral {
    
    public init(unicodeScalarLiteral character: Unicode.Scalar) {
        self.init(rawValue: CInt(character.value))
    }
}

@usableFromInline
var _NRBITS: CInt       { CInt(8) }

@usableFromInline
var _TYPEBITS: CInt     { CInt(8) }

@usableFromInline
var _SIZEBITS: CInt     { CInt(14) }

@usableFromInline
var _DIRBITS: CInt      { CInt(2) }

@usableFromInline
var _NRMASK: CInt       { CInt((1 << _NRBITS)-1) }

@usableFromInline
var _TYPEMASK: CInt     { CInt((1 << _TYPEBITS)-1) }

@usableFromInline
var _SIZEMASK: CInt     { CInt((1 << _SIZEBITS)-1) }

@usableFromInline
var _DIRMASK: CInt      { CInt((1 << _DIRBITS)-1) }

@usableFromInline
var _NRSHIFT: CInt      { CInt(0) }

@usableFromInline
var _TYPESHIFT: CInt    { CInt(_NRSHIFT+_NRBITS) }

@usableFromInline
var _SIZESHIFT: CInt    { CInt(_TYPESHIFT+_TYPEBITS) }

@usableFromInline
var _DIRSHIFT: CInt     { CInt(_SIZESHIFT+_SIZEBITS) }
