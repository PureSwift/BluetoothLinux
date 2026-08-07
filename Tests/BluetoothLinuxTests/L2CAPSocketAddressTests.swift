//
//  L2CAPSocketAddressTests.swift
//  BluetoothLinuxTests
//
//  Socket address construction requires the Bluetooth address family,
//  which is only available on Linux (these run in CI).
//

#if os(Linux)
import Foundation
import XCTest
import Bluetooth
import BluetoothHCI
import SystemPackage
import Socket
@testable import BluetoothLinux

final class L2CAPSocketAddressTests: XCTestCase {

    func testClassicAddressEncoding() {
        let address = L2CAPSocketAddress(
            address: BluetoothAddress(rawValue: "00:1A:7D:DA:71:13")!,
            addressType: nil,
            protocolServiceMultiplexer: .bnep,
            channel: 0
        )
        address.withUnsafePointer { pointer, size in
            XCTAssertEqual(Int(size), MemoryLayout<CInterop.L2CAPSocketAddress>.size)
            let bytes = UnsafeRawPointer(pointer).loadUnaligned(as: CInterop.L2CAPSocketAddress.self)
            XCTAssertEqual(UInt16(littleEndian: bytes.l2_psm), 0x000F)
            XCTAssertEqual(bytes.l2_cid, 0)
            XCTAssertEqual(bytes.l2_bdaddr_type, 0)
            XCTAssertEqual(BluetoothAddress(littleEndian: bytes.l2_bdaddr).rawValue, "00:1A:7D:DA:71:13")
        }
    }

    func testClassicAddressDecoding() {
        var bytes = CInterop.L2CAPSocketAddress()
        bytes.l2_psm = UInt16(0x0011).littleEndian // HID Control
        bytes.l2_bdaddr = BluetoothAddress(rawValue: "00:1A:7D:DA:71:13")!.littleEndian
        let address = L2CAPSocketAddress(bytes)
        XCTAssertEqual(address.protocolServiceMultiplexer, .hidc)
        // Decoding is deliberately not the inverse of encoding here. On the
        // wire `l2_bdaddr_type` has no "unspecified" encoding: 0 *is* BR/EDR,
        // which is why the encoder maps a nil address type onto it. Reading 0
        // back as `.bredr` is therefore the accurate answer, and the one the
        // kernel means, even though it does not round-trip to the nil this
        // address was built from.
        XCTAssertEqual(address.addressType, .bredr)
        XCTAssertEqual(address.channel.rawValue, 0)
        XCTAssertEqual(address.address.rawValue, "00:1A:7D:DA:71:13")
    }

    func testLowEnergyAddressEncoding() {
        let address = L2CAPSocketAddress(
            lowEnergy: BluetoothAddress(rawValue: "00:1A:7D:DA:71:13")!,
            isRandom: false
        )
        address.withUnsafePointer { pointer, size in
            let bytes = UnsafeRawPointer(pointer).loadUnaligned(as: CInterop.L2CAPSocketAddress.self)
            XCTAssertEqual(UInt16(littleEndian: bytes.l2_cid), 0x0004) // ATT
            XCTAssertEqual(bytes.l2_bdaddr_type, AddressType.lowEnergyPublic.rawValue)
        }
    }
}
#endif
