//
//  main.swift
//  BlueZIndexing
//
//  Created by Alsey Coleman Miller on 12/6/15.
//  Copyright © 2015 PureSwift. All rights reserved.
//

#if os(Linux)
    import CBlueZ
#endif

print("Hello, World!")

let addressString = "01:23:45:67:89:AB"

let address = Bluetooth.Address(rawValue: addressString)