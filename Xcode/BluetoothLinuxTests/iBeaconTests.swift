//
//  iBeaconTests.swift
//  BluetoothLinux
//
//  Created by Alsey Coleman Miller on 4/29/16.
//  Copyright © 2016 PureSwift. All rights reserved.
//

#if os(OSX)
    
    import XCTest
    import Foundation
    import Bluetooth
    @testable import BluetoothLinux
    
    final class iBeaconTests: XCTestCase {
        
        func testAdvertisementData() {
            
            let identifier = UUID()
            
            let major: UInt16 = 1
            
            let minor: UInt16 = 1
            
            let rssi: Int8 = -29
            
            var adverstisementDataParameter = beaconAdvertisementData(Array(identifier.toData()), CInt(major).littleEndian, CInt(minor).littleEndian, CInt(rssi).littleEndian)
            
            var parameterBytes = [UInt8].init(repeating: 0, count: Int(adverstisementDataParameter.length))
            
            let _ = withUnsafePointer(to: &adverstisementDataParameter.data) { memcpy(&parameterBytes, UnsafeRawPointer($0), parameterBytes.count) }
            
            var advertisingDataCommand = LowEnergyCommand.SetAdvertisingDataParameter()
            
            SetBeaconData(UUID: identifier, major: major, minor: minor, RSSI: UInt8(bitPattern: rssi), parameter: &advertisingDataCommand)
            
            XCTAssert(adverstisementDataParameter.length == advertisingDataCommand.length, "Invalid Length: \(adverstisementDataParameter.length) == \(advertisingDataCommand.length)")
            
            let dataPointer1 = withUnsafePointer(to: &adverstisementDataParameter.data) { return UnsafeRawPointer($0) }
            let dataPointer2 = withUnsafePointer(to: &advertisingDataCommand.data) { return UnsafeRawPointer($0) }
            
            XCTAssert(memcmp(dataPointer1, dataPointer2, Int(advertisingDataCommand.length)) == 0, "Invalid generated data: \n\(adverstisementDataParameter.data)\n == \n\(advertisingDataCommand.data))")
        }
    }
    
#endif
