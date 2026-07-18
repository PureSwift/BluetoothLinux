//
//  UserChannelTests.swift
//  BluetoothLinux
//

import Foundation
import XCTest
import Bluetooth
import BluetoothHCI
@testable import BluetoothLinux

final class UserChannelTests: XCTestCase {

    func testPacket() {
        // HCI Reset command packet
        let data = Data([0x01, 0x03, 0x0C, 0x00])
        guard let packet = HCIUserChannel.Packet(data: data) else {
            XCTFail("Could not parse packet")
            return
        }
        XCTAssertEqual(packet.type, .command)
        XCTAssertEqual(packet.data, Data([0x03, 0x0C, 0x00]))
    }

    func testPacketInvalid() {
        XCTAssertNil(HCIUserChannel.Packet(data: Data()))
        XCTAssertNil(HCIUserChannel.Packet(data: Data([0x05])))
    }

    func testCommandCompleteResponse() {
        // Command Complete for HCI Reset (0x0C03), status success
        let packet = HCIUserChannel.Packet(
            type: .event,
            data: Data([
                0x0E,       // Command Complete
                0x04,       // parameter length
                0x01,       // number of packets
                0x03, 0x0C, // opcode
                0x00        // status
            ])
        )
        guard let response = HCIUserChannel.CommandResponse(packet) else {
            XCTFail("Could not parse response")
            return
        }
        XCTAssertEqual(response.opcode, 0x0C03)
        XCTAssertNil(response.status)
        XCTAssertEqual(response.parameters, Data([0x00]))
    }

    func testCommandStatusResponse() {
        // Command Status for LE Create Connection (0x200D), command disallowed
        let packet = HCIUserChannel.Packet(
            type: .event,
            data: Data([
                0x0F,       // Command Status
                0x04,       // parameter length
                0x0C,       // status (command disallowed)
                0x01,       // number of packets
                0x0D, 0x20  // opcode
            ])
        )
        guard let response = HCIUserChannel.CommandResponse(packet) else {
            XCTFail("Could not parse response")
            return
        }
        XCTAssertEqual(response.opcode, 0x200D)
        XCTAssertEqual(response.status, 0x0C)
        XCTAssertEqual(HCIError(rawValue: 0x0C), .commandDisallowed)
        XCTAssertEqual(response.parameters, Data())
    }

    func testResponseIgnoresOtherPackets() {
        // ACL data is not a command response
        let acl = HCIUserChannel.Packet(type: .acl, data: Data([0x01, 0x00, 0x02, 0x00, 0xAA, 0xBB]))
        XCTAssertNil(HCIUserChannel.CommandResponse(acl))
        // LE Meta event is not a command response
        let meta = HCIUserChannel.Packet(type: .event, data: Data([0x3E, 0x01, 0x00]))
        XCTAssertNil(HCIUserChannel.CommandResponse(meta))
    }

    func testResponseInvalidLength() {
        // header declares more parameters than present
        let truncated = HCIUserChannel.Packet(type: .event, data: Data([0x0E, 0x0A, 0x01]))
        XCTAssertNil(HCIUserChannel.CommandResponse(truncated))
        // command complete too short for opcode
        let short = HCIUserChannel.Packet(type: .event, data: Data([0x0E, 0x01, 0x01]))
        XCTAssertNil(HCIUserChannel.CommandResponse(short))
    }
}
