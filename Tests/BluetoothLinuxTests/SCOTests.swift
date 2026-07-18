//
//  SCOTests.swift
//  BluetoothLinuxTests
//

import Foundation
import XCTest
import Bluetooth
import SystemPackage
import Socket
@testable import BluetoothLinux

final class SCOTests: XCTestCase {

    func testSocketOptionValues() {
        XCTAssertEqual(SCOSocketOption.optionLevel.rawValue, 17) // SOL_SCO
        XCTAssertEqual(SCOSocketOption.options.rawValue, 0x01)
        XCTAssertEqual(SCOSocketOption.connectionInfo.rawValue, 0x02)
        XCTAssertEqual(BluetoothSocketOption.voice.rawValue, 11) // BT_VOICE
    }

    func testVoiceSetting() {
        XCTAssertEqual(BluetoothSocketOption.Voice.Setting.cvsd.rawValue, 0x0060)
        XCTAssertEqual(BluetoothSocketOption.Voice.Setting.transparent.rawValue, 0x0003)
        XCTAssertEqual(BluetoothSocketOption.Voice().setting, .cvsd)
    }

    func testVoiceEncoding() {
        // `bt_voice` is a single 16-bit setting
        let voice = BluetoothSocketOption.Voice(setting: .transparent)
        voice.withUnsafeBytes { buffer in
            XCTAssertEqual(buffer.count, 2)
            XCTAssertEqual(buffer[0], 0x03)
            XCTAssertEqual(buffer[1], 0x00)
        }
        let decoded = BluetoothSocketOption.Voice.withUnsafeBytes { buffer in
            buffer[0] = 0x60
            buffer[1] = 0x00
        }
        XCTAssertEqual(decoded.setting, .cvsd)
    }

    func testOptionsLayout() {
        // `sco_options` is a single 16-bit MTU
        var options = SCOSocketOption.Options()
        options.maximumTransmissionUnit = 64
        options.withUnsafeBytes { buffer in
            XCTAssertEqual(buffer.count, 2)
        }
        // `sco_conninfo` is a 16-bit handle and 3 byte device class
        let info = SCOSocketOption.ConnectionInfo()
        info.withUnsafeBytes { buffer in
            XCTAssertEqual(buffer.count, MemoryLayout<CInterop.SCOConnectionInfo>.size)
        }
    }

    #if os(Linux)
    func testSocketAddressEncoding() {
        // socket address construction requires the Bluetooth address family (Linux only)
        let address = SCOSocketAddress(address: BluetoothAddress(rawValue: "00:1A:7D:DA:71:13")!)
        address.withUnsafePointer { pointer, size in
            XCTAssertEqual(Int(size), MemoryLayout<CInterop.SCOSocketAddress>.size)
            let bytes = UnsafeRawPointer(pointer).loadUnaligned(as: CInterop.SCOSocketAddress.self)
            XCTAssertEqual(BluetoothAddress(littleEndian: bytes.address).rawValue, "00:1A:7D:DA:71:13")
        }
    }
    #endif
}
