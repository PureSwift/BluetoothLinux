//
//  RFCOMMSocketTests.swift
//  BluetoothLinuxTests
//

import Foundation
import XCTest
import Bluetooth
import SystemPackage
import Socket
@testable import BluetoothLinux

final class RFCOMMSocketTests: XCTestCase {

    func testSocketOptionValues() {
        XCTAssertEqual(RFCOMMSocketOption.optionLevel.rawValue, 18) // SOL_RFCOMM
        XCTAssertEqual(RFCOMMSocketOption.connectionInfo.rawValue, 0x02)
        XCTAssertEqual(RFCOMMSocketOption.linkMode.rawValue, 0x03)
    }

    func testLinkModeEncoding() {
        // `RFCOMM_LM` is a 16-bit bitmask
        let linkMode = RFCOMMSocketOption.LinkMode(linkMode: [.authenticated, .encrypted])
        linkMode.withUnsafeBytes { buffer in
            XCTAssertEqual(buffer.count, MemoryLayout<RFCOMMLinkMode.RawValue>.size)
            XCTAssertEqual(buffer[0], 0x06)
            XCTAssertEqual(buffer[1], 0x00)
        }
        let decoded = RFCOMMSocketOption.LinkMode.withUnsafeBytes { buffer in
            buffer[0] = 0x24
            buffer[1] = 0x00
        }
        XCTAssertEqual(decoded.linkMode, [.encrypted, .secure])
    }

    #if os(Linux)
    func testSocketAddressEncoding() {
        // socket address construction requires the Bluetooth address family (Linux only)
        let address = RFCOMMSocketAddress(
            address: BluetoothAddress(rawValue: "00:1A:7D:DA:71:13")!,
            channel: 3
        )
        address.withUnsafePointer { pointer, size in
            XCTAssertEqual(Int(size), MemoryLayout<CInterop.RFCOMMSocketAddress>.size)
            let bytes = UnsafeRawPointer(pointer).loadUnaligned(as: CInterop.RFCOMMSocketAddress.self)
            XCTAssertEqual(bytes.channel, 3)
        }
    }
    #endif
}
