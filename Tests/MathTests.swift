//
//  MathTests.swift
//  BluetoothLinux
//
//  Created by Alsey Coleman Miller on 3/3/16.
//  Copyright © 2016 PureSwift. All rights reserved.
//

#if os(OSX)

    import XCTest
    @testable import BluetoothLinux
    
    final class MathTests: XCTestCase {
        
        func testHCIMath() {
            
            let bit = HCIFilter.Bits.Event
            
            var cDestination: CInt = 0
            
            withUnsafeMutablePointer(&cDestination) { hci_set_bit(bit, UnsafeMutablePointer<Void>($0)) }
            
            var swiftDestination: CInt = 0
            
            HCISetBit(bit, destination: &swiftDestination)
            
            XCTAssert(cDestination == swiftDestination, "\(cDestination) == \(swiftDestination)")
        }
        
    }

#endif