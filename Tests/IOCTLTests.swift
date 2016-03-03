//
//  IOCTLTests.swift
//  BluetoothLinux
//
//  Created by Alsey Coleman Miller on 3/3/16.
//  Copyright © 2016 PureSwift. All rights reserved.
//

#if os(OSX)
    
    import XCTest
    @testable import BluetoothLinux
    
    final class IOCTLTests: XCTestCase {
        
        func testConstants() {
            
            var swiftDefinitionList = [HCI.IOCTL.DeviceUp, HCI.IOCTL.DeviceDown, HCI.IOCTL.DeviceReset, HCI.IOCTL.DeviceRestat]
            
            XCTAssert(hci_test_oictl_defines(&swiftDefinitionList, CInt(swiftDefinitionList.count)), )
        }
        
    }
    
#endif
