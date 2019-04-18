//
//  MathTests.swift
//  BluetoothLinux
//
//  Created by Alsey Coleman Miller on 3/3/16.
//  Copyright © 2016 PureSwift. All rights reserved.
//

import Foundation
import XCTest
import Bluetooth
import CSwiftBluetoothLinux
import CSwiftBluetoothLinuxTest
@testable import BluetoothLinux

final class MathTests: XCTestCase {
    
    static let allTests = [
        ("testHCISetBit", testHCISetBit),
        ("testHCIFilterSetPacketType", testHCIFilterSetPacketType),
        ("testHCIFilterSetEvent", testHCIFilterSetEvent),
        ("testIOCTLConstants", testIOCTLConstants)
    ]
    
    func testHCISetBit() {
        
        let event = HCIGeneralEvent.commandStatus.rawValue
        
        let bit = (CInt(event) & HCIFilter.Bits.Event)
        
        var cDestination: UInt32 = 0
        
        CSwiftBluetoothLinuxTest.hci_set_bit(bit, &cDestination)
        
        var swiftDestination: UInt32 = 0
        
        CSwiftBluetoothLinux.HCISetBit(bit, &swiftDestination)
        
        XCTAssert(cDestination == swiftDestination, "\(cDestination) == \(swiftDestination)")
        XCTAssert(swiftDestination == 32768, "\(swiftDestination)")
        XCTAssert(cDestination == 32768, "\(cDestination)")
    }
    
    func testHCIFilterSetPacketType() {
        
        var swiftFilter = HCIFilter()
        swiftFilter.setPacketType(.Event)
        
        var cFilter = hci_filter()
        hci_filter_set_ptype(HCI_EVENT_PKT, &cFilter)
        
        XCTAssert(swiftFilter.typeMask == cFilter.type_mask, "\(swiftFilter.typeMask) == \(cFilter.type_mask)")
        
        XCTAssert(cFilter.type_mask == 16)
    }
    
    func testHCIFilterSetEvent() {
        
        let event = HCIGeneralEvent.commandComplete.rawValue
        
        var swiftFilter = HCIFilter()
        
        swiftFilter.setEvent(HCIGeneralEvent.commandStatus.rawValue)
        swiftFilter.setEvent(HCIGeneralEvent.commandComplete.rawValue)
        swiftFilter.setEvent(HCIGeneralEvent.lowEnergyMeta.rawValue)
        swiftFilter.setEvent(event)
        
        var cFilter = hci_filter()
        hci_filter_set_event(CInt(HCIGeneralEvent.commandStatus.rawValue), &cFilter)
        hci_filter_set_event(CInt(HCIGeneralEvent.commandComplete.rawValue), &cFilter)
        hci_filter_set_event(CInt(HCIGeneralEvent.lowEnergyMeta.rawValue), &cFilter)
        hci_filter_set_event(CInt(event), &cFilter)
        
        XCTAssert(swiftFilter.eventMask.0 == cFilter.event_mask.0 && swiftFilter.eventMask.1 == cFilter.event_mask.1,
                  "\(swiftFilter.eventMask) == \(cFilter.event_mask)")
        
        swiftFilter.clear()
        swiftFilter.setEvent(HCIGeneralEvent.commandStatus.rawValue,
                             HCIGeneralEvent.commandComplete.rawValue,
                             HCIGeneralEvent.lowEnergyMeta.rawValue,
                             event)
        
        //XCTAssert(swiftFilter.eventMask.0 == cFilter.event_mask.0 && swiftFilter.eventMask.1 == cFilter.event_mask.1, "\(swiftFilter.eventMask) == \(cFilter.event_mask)")
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
        
        withUnsafeMutablePointer(to: &cListCopy) {
            
            $0.withMemoryRebound(to: Int32.self, capacity: 9) { (cListPointer) in
                
                for (index, swiftDefinition) in swiftDefinitionList.enumerated() {
                    
                    let cDefinition = CUnsignedLong(bitPattern: CLong(cListPointer[index]))
                    
                    guard swiftDefinition == cDefinition else {
                        
                        XCTFail("\(swiftDefinition) == \(cDefinition) at definition \(index + 1)")
                        return
                    }
                }
                
            }
        }
        
    }
}
