//
//  DarwinMathTests.swift
//  BluetoothLinux
//
//  Created by Alsey Coleman Miller on 3/3/16.
//  Copyright © 2016 PureSwift. All rights reserved.
//

#if os(OSX)

    import XCTest
    @testable import BluetoothLinux
    
    final class MathTests: XCTestCase {
        
        func testHCISetBit() {
            
            let bit = HCIFilter.Bits.Event
            
            var cDestination: UInt32 = 0
            
            hci_set_bit(bit, withUnsafeMutablePointer(&cDestination, { UnsafeMutablePointer<Void>($0) }))
            
            var swiftDestination: UInt32 = 0
            
            HCISetBit(bit, destination: &swiftDestination)
            
            XCTAssert(cDestination == swiftDestination, "\(cDestination) == \(swiftDestination)")
        }
        
        func testHCIFilterSetPacketType() {
            
            var swiftFilter = HCIFilter()
            swiftFilter.setPacketType(.Event)
            
            var cFilter = hci_filter()
            hci_filter_set_ptype(HCI_EVENT_PKT, &cFilter)
            
            XCTAssert(swiftFilter.typeMask == cFilter.type_mask, "\(swiftFilter.typeMask) == \(cFilter.type_mask)")
        }
        
        func testIOCTLConstants() {
            
            let swiftDefinitionList = [
                HCI.IOCTL.DeviceUp,
                HCI.IOCTL.DeviceDown,
                HCI.IOCTL.DeviceReset,
                HCI.IOCTL.DeviceRestat,
                HCI.IOCTL.GetDeviceList,
                HCI.IOCTL.GetDeviceInfo
            ]
            
            var cListCopy = hci_ioctl_list
            
            let cListPointer = withUnsafeMutablePointer(&cListCopy) { UnsafeMutablePointer<Int32>($0) }
            
            for (index, swiftDefinition) in swiftDefinitionList.enumerate() {
                
                let cDefinition = cListPointer[index]
                
                guard swiftDefinition == cDefinition else {
                    
                    XCTFail("\(swiftDefinition) == \(cDefinition) at definition \(index + 1)")
                    return
                }
            }
        }
    }

#endif
