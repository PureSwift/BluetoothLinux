//
//  LinkControlCommandParameter.swift
//  BlueZ
//
//  Created by Alsey Coleman Miller on 1/14/16.
//  Copyright © 2016 PureSwift. All rights reserved.
//

#if os(Linux)
    import CBlueZ
    import Glibc
#elseif os(OSX) || os(iOS)
    import Darwin.C
#endif

import SwiftFoundation

#if os(OSX)
    public struct inquiry_cp {
        var lap: (UInt8, UInt8, UInt8)
        var length: UInt8 /* 1.28s units */
        var num_rsp: UInt8
        init() { stub() }
    }
#endif

extension inquiry_cp: HCICommandParameter {
    public static var dataLength: CInt { return 5 }
}