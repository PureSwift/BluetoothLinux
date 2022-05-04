//
//  BluetoothLinuxTests.swift
//  BluetoothLinuxTests
//
//  Created by Alsey Coleman Miller on 4/18/19.
//

import Foundation
import XCTest
import Bluetooth
import BluetoothHCI
import CBluetoothLinux
import CBluetoothLinuxTest
@testable import BluetoothLinux

final class BluetoothLinuxTests: XCTestCase {
    
    func testHCISetBit() {
        
        let event = HCIGeneralEvent.commandStatus.rawValue
        let bit = (CInt(event) & HCI_FLT_EVENT_BITS)
        var cDestination: UInt32 = 0
        CBluetoothLinuxTest.hci_set_bit(bit, &cDestination)
        var swiftDestination: UInt32 = 0
        CBluetoothLinux.HCISetBit(bit, &swiftDestination)
        
        XCTAssert(cDestination == swiftDestination, "\(cDestination) == \(swiftDestination)")
        XCTAssert(swiftDestination == 32768, "\(swiftDestination)")
        XCTAssert(cDestination == 32768, "\(cDestination)")
    }
    
    func testHCIFilterSetPacketType() {
        
        var swiftFilter = HCISocketOption.Filter()
        swiftFilter.setPacketType(.event)
        
        var cFilter = hci_filter()
        hci_filter_set_ptype(HCI_EVENT_PKT, &cFilter)
        
        XCTAssert(swiftFilter.typeMask == cFilter.type_mask, "\(swiftFilter.typeMask) == \(cFilter.type_mask)")
        XCTAssert(cFilter.type_mask == 16)
    }
    
    func testHCIFilterSetEvent() {
        
        let event = HCIGeneralEvent.commandComplete
        
        var swiftFilter = HCISocketOption.Filter()
        
        swiftFilter.setEvent(HCIGeneralEvent.commandStatus)
        swiftFilter.setEvent(HCIGeneralEvent.commandComplete)
        swiftFilter.setEvent(HCIGeneralEvent.lowEnergyMeta)
        swiftFilter.setEvent(event)
        
        var cFilter = hci_filter()
        hci_filter_set_event(CInt(HCIGeneralEvent.commandStatus.rawValue), &cFilter)
        hci_filter_set_event(CInt(HCIGeneralEvent.commandComplete.rawValue), &cFilter)
        hci_filter_set_event(CInt(HCIGeneralEvent.lowEnergyMeta.rawValue), &cFilter)
        hci_filter_set_event(CInt(event.rawValue), &cFilter)
        
        XCTAssert(swiftFilter.bytes.eventMask.0 == cFilter.event_mask.0 && swiftFilter.bytes.eventMask.1 == cFilter.event_mask.1,
                  "\(swiftFilter.bytes.eventMask) == \(cFilter.event_mask)")
        
        swiftFilter = .init()
        swiftFilter.bytes.setEvent(HCIGeneralEvent.commandStatus.rawValue,
                             HCIGeneralEvent.commandComplete.rawValue,
                             HCIGeneralEvent.lowEnergyMeta.rawValue,
                                   event.rawValue)
        
        //XCTAssert(swiftFilter.eventMask.0 == cFilter.event_mask.0 && swiftFilter.eventMask.1 == cFilter.event_mask.1, "\(swiftFilter.eventMask) == \(cFilter.event_mask)")
    }
    
    #if os(Linux)
    func testIOCTLConstants() {
        
        let swiftDefinitionList: [HostControllerIO] = [
            .deviceUp,
            .deviceDown,
            .deviceReset,
            .deviceRestat,
            .getDeviceList,
            .getDeviceInfo,
            .getConnectionList,
            .getConnectionInfo,
            .getAuthenticationInfo
        ]
        
        XCTAssertEqual(swiftDefinitionList.count, 9)
        withUnsafePointer(to: hci_ioctl_list) {
            $0.withMemoryRebound(to: Int32.self, capacity: swiftDefinitionList.count) { (cListPointer) in
                for (index, swiftDefinition) in swiftDefinitionList.enumerated() {
                    let cDefinition = CUnsignedLong(bitPattern: CLong(cListPointer[index]))
                    guard swiftDefinition.rawValue == cDefinition else {
                        XCTFail("\(swiftDefinition) == \(cDefinition) at definition \(index + 1)")
                        return
                    }
                }
            }
        }
    }
    #endif
}
