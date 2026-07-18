//
//  ManagementTests.swift
//  BluetoothLinux
//

import Foundation
import XCTest
import Bluetooth
@testable import BluetoothLinux

final class ManagementTests: XCTestCase {

    func testCommandHeader() {
        let header = ManagementCommandHeader(
            opcode: .setPowered,
            index: .init(rawValue: 0),
            parameterLength: 1
        )
        let data = header.data
        XCTAssertEqual(data, Data([0x05, 0x00, 0x00, 0x00, 0x01, 0x00]))
        XCTAssertEqual(ManagementCommandHeader(data: data), header)
    }

    func testEventHeader() {
        let header = ManagementEventHeader(
            event: .commandComplete,
            index: .init(rawValue: 1),
            parameterLength: 3
        )
        let data = header.data
        XCTAssertEqual(data, Data([0x01, 0x00, 0x01, 0x00, 0x03, 0x00]))
        XCTAssertEqual(ManagementEventHeader(data: data), header)
    }

    func testEventNotification() {
        // Command Complete for Read Management Version Information (0x0001)
        // status success, version 1, revision 22
        let data = Data([
            0x01, 0x00, // Command Complete
            0xFF, 0xFF, // no controller index
            0x06, 0x00, // parameter length
            0x01, 0x00, // opcode
            0x00,       // status
            0x01,       // version
            0x16, 0x00  // revision
        ])
        guard let notification = ManagementEventNotification(data: data) else {
            XCTFail("Could not parse event")
            return
        }
        XCTAssertEqual(notification.event, .commandComplete)
        XCTAssertEqual(notification.index, .none)
        XCTAssertEqual(notification.parameters.count, 6)
        guard let response = ManagementCommandResponse(notification) else {
            XCTFail("Could not parse response")
            return
        }
        XCTAssertEqual(response.opcode, .readVersion)
        XCTAssertEqual(response.status, .success)
        XCTAssertEqual(response.parameters, Data([0x01, 0x16, 0x00]))
    }

    func testEventNotificationInvalidLength() {
        // header declares more parameters than present
        let data = Data([0x01, 0x00, 0xFF, 0xFF, 0x0A, 0x00, 0x01])
        XCTAssertNil(ManagementEventNotification(data: data))
    }

    func testCommandStatusResponse() {
        // Command Status for Set Powered (0x0005), permission denied
        let notification = ManagementEventNotification(
            event: .commandStatus,
            index: .init(rawValue: 0),
            parameters: Data([0x05, 0x00, 0x14])
        )
        guard let response = ManagementCommandResponse(notification) else {
            XCTFail("Could not parse response")
            return
        }
        XCTAssertEqual(response.opcode, .setPowered)
        XCTAssertEqual(response.status, .permissionDenied)
    }

    func testControllerInformation() {
        var data = Data()
        data.append(contentsOf: [0x13, 0x71, 0xDA, 0x7D, 0x1A, 0x00]) // 00:1A:7D:DA:71:13
        data.append(0x08) // version 4.2
        data.append(contentsOf: [0x0F, 0x00]) // manufacturer (Broadcom)
        data.append(contentsOf: [0xFF, 0x02, 0x00, 0x00]) // supported settings
        data.append(contentsOf: [0x81, 0x02, 0x00, 0x00]) // current settings (powered, br/edr, le)
        data.append(contentsOf: [0x0C, 0x01, 0x1C]) // class of device
        var name = Data("Test Controller".utf8)
        name.append(contentsOf: repeatElement(0, count: ManagementControllerInformation.maximumNameLength - name.count))
        data.append(name)
        var shortName = Data("Test".utf8)
        shortName.append(contentsOf: repeatElement(0, count: ManagementControllerInformation.maximumShortNameLength - shortName.count))
        data.append(shortName)
        XCTAssertEqual(data.count, ManagementControllerInformation.length)
        guard let information = ManagementControllerInformation(data: data) else {
            XCTFail("Could not parse controller information")
            return
        }
        XCTAssertEqual(information.address, BluetoothAddress(rawValue: "00:1A:7D:DA:71:13"))
        XCTAssertEqual(information.version, 0x08)
        XCTAssertEqual(information.manufacturer, 15)
        XCTAssertEqual(information.supportedSettings.rawValue, 0x02FF)
        XCTAssertEqual(information.currentSettings, [.powered, .basicRateEnhancedDataRate, .lowEnergy])
        XCTAssertEqual(information.classOfDevice.0, 0x0C)
        XCTAssertEqual(information.classOfDevice.1, 0x01)
        XCTAssertEqual(information.classOfDevice.2, 0x1C)
        XCTAssertEqual(information.name, "Test Controller")
        XCTAssertEqual(information.shortName, "Test")
    }

    func testSettings() {
        XCTAssertThrowsError(try ManagementSocket.settings(from: Data([0x01])))
        XCTAssertEqual(
            try ManagementSocket.settings(from: Data([0x81, 0x02, 0x00, 0x00])),
            [.powered, .basicRateEnhancedDataRate, .lowEnergy]
        )
    }

    func testFixedLengthString() {
        let data = ManagementSocket.fixedLengthString("Test", length: 11)
        XCTAssertEqual(data.count, 11)
        XCTAssertEqual(data, Data([0x54, 0x65, 0x73, 0x74, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00]))
        // truncation preserves the null terminator
        let truncated = ManagementSocket.fixedLengthString("A very long controller name", length: 11)
        XCTAssertEqual(truncated.count, 11)
        XCTAssertEqual(truncated.last, 0x00)
    }

    func testStatusDescription() {
        for status in ManagementStatus.allCases {
            XCTAssertFalse(status.description.isEmpty)
        }
    }

    func testSettingsDescription() {
        let settings: ManagementSettings = [.powered, .lowEnergy]
        XCTAssertEqual(settings.description, "powered le")
    }
}
