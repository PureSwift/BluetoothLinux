//
//  iBeaconTests.swift
//  BluetoothLinux
//
//  Created by Alsey Coleman Miller on 4/29/16.
//  Copyright © 2016 PureSwift. All rights reserved.
//

import XCTest
import Foundation
import Bluetooth
import CSwiftBluetoothLinux
import CSwiftBluetoothLinuxTest
@testable import BluetoothLinux

final class iBeaconTests: XCTestCase {
    
    static let allTests = [
        ("testAdvertisementData", testAdvertisementData)
    ]
    
    func testAdvertisementData() {
        
        let identifier = UUID()
        
        let major: UInt16 = 1
        
        let minor: UInt16 = 1
        
        let rssi = RSSI(rawValue: -29)!
        
        var adverstisementDataParameter = beaconAdvertisementData(Array(identifier.data),
                                                                  CInt(major),
                                                                  CInt(minor),
                                                                  CInt(rssi.rawValue))
        
        var parameterBytes = [UInt8].init(repeating: 0, count: Int(adverstisementDataParameter.length))
        
        let _ = withUnsafePointer(to: &adverstisementDataParameter.data) {
            memcpy(&parameterBytes, UnsafeRawPointer($0), parameterBytes.count)
        }
        
        var advertisingDataCommand = iBeacon(uuid: identifier,
                                             major: major,
                                             minor: minor,
                                             rssi: rssi).advertisingDataCommand
        
        XCTAssert(adverstisementDataParameter.length.hashValue == advertisingDataCommand.data.count, "Invalid Length: \(adverstisementDataParameter.length) == \(advertisingDataCommand.data.count)")
        
        let dataPointer1 = withUnsafePointer(to: &adverstisementDataParameter.data) { return UnsafeRawPointer($0) }
        let dataPointer2 = withUnsafePointer(to: &advertisingDataCommand.data.bytes) { return UnsafeRawPointer($0) }
        
        XCTAssert(memcmp(dataPointer1, dataPointer2, Int(advertisingDataCommand.data.count)) == 0, "Invalid generated data: \n\(adverstisementDataParameter.data)\n == \n\(advertisingDataCommand.data.bytes)")
    }
}



