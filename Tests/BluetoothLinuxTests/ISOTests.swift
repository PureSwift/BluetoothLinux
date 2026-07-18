//
//  ISOTests.swift
//  BluetoothLinuxTests
//

import Foundation
import XCTest
import Bluetooth
import SystemPackage
import Socket
@testable import BluetoothLinux

final class ISOTests: XCTestCase {

    func testSocketProtocol() {
        XCTAssertEqual(BluetoothSocketProtocol.iso.rawValue, 8) // BTPROTO_ISO
        XCTAssertEqual(BluetoothSocketProtocol.iso.type, .sequencedPacket)
        XCTAssertEqual(BluetoothSocketOption.isoQualityOfService.rawValue, 17) // BT_ISO_QOS
    }

    func testQualityOfServiceLayout() {
        // must match the kernel's `bt_iso_ucast_qos` layout
        // cig, cis, sca, packing, framing (5 bytes), in at offset 8, out at offset 20
        XCTAssertEqual(MemoryLayout<BluetoothSocketOption.ISOQualityOfService>.size, 30)
        XCTAssertEqual(MemoryLayout<BluetoothSocketOption.ISOQualityOfService>.stride, 32)
        XCTAssertEqual(MemoryLayout<BluetoothSocketOption.ISOQualityOfService.IO>.size, 10)
        XCTAssertEqual(MemoryLayout<BluetoothSocketOption.ISOQualityOfService.IO>.stride, 12)
        XCTAssertEqual(MemoryLayout<BluetoothSocketOption.ISOQualityOfService>.offset(of: \.input), 8)
        XCTAssertEqual(MemoryLayout<BluetoothSocketOption.ISOQualityOfService>.offset(of: \.output), 20)
    }

    func testQualityOfServiceEncoding() {
        var qos = BluetoothSocketOption.ISOQualityOfService()
        XCTAssertEqual(qos.group, 0xFF) // unset
        XCTAssertEqual(qos.stream, 0xFF) // unset
        qos.group = 1
        qos.stream = 2
        qos.output = .init(interval: 10_000, latency: 10, sdu: 40, phy: 0x02, retransmissionNumber: 2)
        qos.withUnsafeBytes { buffer in
            XCTAssertEqual(buffer[0], 1) // cig
            XCTAssertEqual(buffer[1], 2) // cis
            // out.interval at offset 20 (10000 = 0x2710 little endian)
            XCTAssertEqual(buffer[20], 0x10)
            XCTAssertEqual(buffer[21], 0x27)
            // out.sdu at offset 26
            XCTAssertEqual(buffer[26], 40)
        }
        let decoded = BluetoothSocketOption.ISOQualityOfService.withUnsafeBytes { buffer in
            buffer[0] = 5 // cig
            buffer[8] = 0x10 // in.interval
            buffer[9] = 0x27
        }
        XCTAssertEqual(decoded.group, 5)
        XCTAssertEqual(decoded.input.interval, 10_000)
    }

    #if os(Linux)
    func testSocketAddressEncoding() {
        // socket address construction requires the Bluetooth address family (Linux only)
        let address = ISOSocketAddress(
            address: BluetoothAddress(rawValue: "00:1A:7D:DA:71:13")!,
            addressType: .lowEnergyRandom
        )
        address.withUnsafePointer { pointer, size in
            XCTAssertEqual(Int(size), MemoryLayout<CInterop.ISOSocketAddress>.size)
            let bytes = UnsafeRawPointer(pointer).loadUnaligned(as: CInterop.ISOSocketAddress.self)
            XCTAssertEqual(BluetoothAddress(littleEndian: bytes.address).rawValue, "00:1A:7D:DA:71:13")
            XCTAssertEqual(bytes.type, AddressType.lowEnergyRandom.rawValue)
        }
    }
    #endif
}
