//
//  iBeaconTests.swift
//  BluetoothLinux
//
//  Created by Alsey Coleman Miller on 4/29/16.
//  Copyright © 2016 PureSwift. All rights reserved.
//

#if os(OSX)
    
    import XCTest
    import SwiftFoundation
    import Bluetooth
    @testable import BluetoothLinux
    
    final class iBeaconTests: XCTestCase {
        
        func testAdvertisementData() {
            
            let identifier = UUID()
            
            let major: UInt16 = 0
            
            let minor: UInt16 = 1
            
            let rssi: Int8 = -59
            
            var adverstisementDataParameter = beaconAdvertisementData(identifier.toData().byteValue, CInt(major), CInt(minor), CInt(rssi))
            
            var parameterBytes = [UInt8].init(repeating: 0, count: Int(adverstisementDataParameter.length))
            
            withUnsafePointer(&adverstisementDataParameter.data) { memcpy(&parameterBytes, UnsafePointer<Void>($0), parameterBytes.count) }
            
            var advertisingDataCommand = LowEnergyCommand.SetAdvertisingDataParameter()
            
            SetBeaconData(UUID: identifier, major: major, minor: minor, RSSI: UInt8(bitPattern: rssi), parameter: &advertisingDataCommand)
            
            XCTAssert(adverstisementDataParameter.length == advertisingDataCommand.length, "Invalid Length: \(adverstisementDataParameter.length) == \(advertisingDataCommand.length)")
            
            //XCTAssert(memcmp(<#T##UnsafePointer<Void>!#>, <#T##UnsafePointer<Void>!#>, <#T##Int#>))
        }
    }
    
#endif