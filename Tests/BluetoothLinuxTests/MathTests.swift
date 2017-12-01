//
//  MathTests.swift
//  BluetoothLinux
//
//  Created by Alsey Coleman Miller on 3/3/16.
//  Copyright © 2016 PureSwift. All rights reserved.
//

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
        
        let bit = HCIFilter.Bits.Event
        
        var cDestination: UInt32 = 0
        
        withUnsafeMutablePointer(to: &cDestination) {
            CSwiftBluetoothLinuxTest.hci_set_bit(bit, UnsafeMutableRawPointer($0))
        }
        
        var swiftDestination: UInt32 = 0
        
        withUnsafeMutablePointer(to: &swiftDestination) {
            CSwiftBluetoothLinux.HCISetBit(bit, UnsafeMutableRawPointer($0))
        }
        
        XCTAssert(cDestination == swiftDestination, "\(cDestination) == \(swiftDestination)")
        XCTAssert(swiftDestination == 2147483648, "\(swiftDestination)")
        XCTAssert(cDestination == 2147483648, "\(cDestination)")
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
        
        let event = HCIGeneralEvent.CommandComplete.rawValue
        
        var swiftFilter = HCIFilter()
        
        swiftFilter.setEvent(HCIGeneralEvent.CommandStatus.rawValue)
        swiftFilter.setEvent(HCIGeneralEvent.CommandComplete.rawValue)
        swiftFilter.setEvent(HCIGeneralEvent.LowEnergyMeta.rawValue)
        swiftFilter.setEvent(event)
        
        var cFilter = hci_filter()
        hci_filter_set_event(CInt(HCIGeneralEvent.CommandStatus.rawValue), &cFilter)
        hci_filter_set_event(CInt(HCIGeneralEvent.CommandComplete.rawValue), &cFilter)
        hci_filter_set_event(CInt(HCIGeneralEvent.LowEnergyMeta.rawValue), &cFilter)
        hci_filter_set_event(CInt(event), &cFilter)
        
        XCTAssert(swiftFilter.eventMask.0 == cFilter.event_mask.0 && swiftFilter.eventMask.1 == cFilter.event_mask.1,
                  "\(swiftFilter.eventMask) == \(cFilter.event_mask)")
        
        swiftFilter.clear()
        swiftFilter.setEvent(HCIGeneralEvent.CommandStatus.rawValue, HCIGeneralEvent.CommandComplete.rawValue, HCIGeneralEvent.LowEnergyMeta.rawValue, event)
        
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
