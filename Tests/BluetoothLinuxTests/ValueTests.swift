//
//  ValueTests.swift
//  BluetoothLinuxTests
//
//  Unit tests for value types that need no Bluetooth hardware:
//  enums, raw-value round trips, and pure conversion logic.
//

import Foundation
import XCTest
import Bluetooth
import BluetoothHCI
import SystemPackage
import Socket
@testable import BluetoothLinux

final class ValueTests: XCTestCase {

    func testAddressTypeRawValues() {
        XCTAssertEqual(AddressType().rawValue, AddressType.bredr.rawValue)
        XCTAssertEqual(AddressType.bredr.rawValue, 0x00)
        XCTAssertEqual(AddressType.lowEnergyPublic.rawValue, 0x01)
        XCTAssertEqual(AddressType.lowEnergyRandom.rawValue, 0x02)
    }

    func testAddressTypeIsLowEnergy() {
        XCTAssertFalse(AddressType.bredr.isLowEnergy)
        XCTAssertTrue(AddressType.lowEnergyPublic.isLowEnergy)
        XCTAssertTrue(AddressType.lowEnergyRandom.isLowEnergy)
    }

    func testAddressTypeFromLowEnergy() {
        XCTAssertEqual(AddressType(lowEnergy: .public), .lowEnergyPublic)
        XCTAssertEqual(AddressType(lowEnergy: .publicIdentity), .lowEnergyPublic)
        XCTAssertEqual(AddressType(lowEnergy: .random), .lowEnergyRandom)
        XCTAssertEqual(AddressType(lowEnergy: .randomIdentity), .lowEnergyRandom)
    }

    func testErrnoFromHCIError() {
        XCTAssertEqual(Errno(HCIError.unknownCommand), .badMessage)
        XCTAssertEqual(Errno(HCIError.noConnection), .socketNotConnected)
        XCTAssertEqual(Errno(HCIError.hardwareFailure), .ioError)
        XCTAssertEqual(Errno(HCIError.memoryFull), .noMemory)
        XCTAssertEqual(Errno(HCIError.connectionTimeout), .timedOut)
        XCTAssertEqual(Errno(HCIError.commandDisallowed), .resourceBusy)
        XCTAssertEqual(Errno(HCIError.connectionTerminated), .connectionAbort)
        XCTAssertEqual(Errno(HCIError.repeatedAttempts), .tooManySymbolicLinkLevels)
        XCTAssertEqual(Errno(HCIError.unsupportedRemoteFeature), .protocolNotSupported)
        // A case not handled by the switch maps to the default.
        XCTAssertEqual(Errno(HCIError.controllerBusy), .noFunction)
    }

    func testHostControllerIORawValueRoundTrip() {
        for value in HostControllerIO.allCases {
            XCTAssertEqual(HostControllerIO(rawValue: value.rawValue), value)
        }
    }

    func testHostControllerIOInvalidRawValue() {
        XCTAssertNil(HostControllerIO(rawValue: 0))
    }

    func testHostControllerIODescription() {
        XCTAssertEqual(HostControllerIO.deviceUp.description, ".deviceUp")
        XCTAssertEqual(HostControllerIO.getDeviceList.debugDescription, ".getDeviceList")
    }

    func testHostControllerIOAllCases() {
        XCTAssertEqual(HostControllerIO.allCases.count, 21)
    }

    func testHostControllerIOCodable() throws {
        let value = HostControllerIO.getDeviceInfo
        let data = try JSONEncoder().encode(value)
        let decoded = try JSONDecoder().decode(HostControllerIO.self, from: data)
        XCTAssertEqual(decoded, value)
    }

    func testRFCOMMIORawValueRoundTrip() {
        for value in RFCOMMIO.allCases {
            XCTAssertEqual(RFCOMMIO(rawValue: value.rawValue), value)
        }
        XCTAssertEqual(RFCOMMIO.allCases.count, 4)
        XCTAssertEqual(RFCOMMIO.createDevice.description, ".createDevice")
    }

    func testHCIDeviceOptionsContains() {
        // Flag raw values are bit positions: .up=0, .initialized=1, .running=2.
        let options = HCIDeviceOptions(rawValue: 0b0000_0101)
        XCTAssertTrue(options.contains(.up))
        XCTAssertFalse(options.contains(.initialized))
        XCTAssertTrue(options.contains(.running))

        let other = HCIDeviceOptions(rawValue: 0b0000_0010)
        XCTAssertFalse(other.contains(.up))
        XCTAssertTrue(other.contains(.initialized))
        XCTAssertFalse(other.contains(.running))
    }

    func testHCIDeviceOptionsEmpty() {
        let options = HCIDeviceOptions(rawValue: 0)
        for flag in HCIDeviceFlag.allCases {
            XCTAssertFalse(options.contains(flag))
        }
        XCTAssertTrue(options.flags.isEmpty)
    }

    func testHCIDeviceOptionsFlagsPopulated() {
        // Bit 2 -> .running; a non-zero bit position is representable in the set.
        let options = HCIDeviceOptions(rawValue: 0b0000_0100)
        XCTAssertFalse(options.flags.isEmpty)
        XCTAssertTrue(options.flags.contains(.running))
    }
}
