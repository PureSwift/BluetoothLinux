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

    func testErrnoFromHCIErrorRemainingBranches() {
        XCTAssertEqual(Errno(HCIError.pageTimeout), .hostIsDown)
        XCTAssertEqual(Errno(HCIError.authenticationFailure), .permissionDenied)
        XCTAssertEqual(Errno(HCIError.keyMissing), .invalidArgument)
        XCTAssertEqual(Errno(HCIError.maxConnections), .tooManyLinks)
        XCTAssertEqual(Errno(HCIError.aclConnectionExists), .alreadyInProcess)
        XCTAssertEqual(Errno(HCIError.rejectedLimitedResources), .connectionRefused)
        XCTAssertEqual(Errno(HCIError.hostTimeout), .timedOut)
        XCTAssertEqual(Errno(HCIError.unsupportedFeature), .notSupportedOnSocket)
        XCTAssertEqual(Errno(HCIError.invalidParameters), .invalidArgument)
        XCTAssertEqual(Errno(HCIError.remoteUserEndedConnection), .connectionReset)
        XCTAssertEqual(Errno(HCIError.rejectedSecurity), .permissionDenied)
        XCTAssertEqual(Errno(HCIError.scoOffsetRejected), .connectionRefused)
        XCTAssertEqual(Errno(HCIError.unknownLMPPDU), .protocolError)
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
        let allFlags: [HCIDeviceFlag] = [
            .up, .initialized, .running,
            .passiveScan, .interactiveScan, .authenticated, .encrypt, .inquiry,
            .raw
        ]
        for flag in allFlags {
            XCTAssertFalse(options.contains(flag))
        }
        XCTAssertTrue(options.flags.isEmpty)
    }

    func testHCIDeviceOptionsFlagsPopulated() {
        // Bit 0 -> .up (now representable as a native OptionSet mask).
        let options = HCIDeviceOptions(rawValue: 0b0000_0101)
        XCTAssertFalse(options.flags.isEmpty)
        XCTAssertTrue(options.flags.contains(.up))
        XCTAssertTrue(options.flags.contains(.running))
    }

    func testLinkModeRawValues() {
        XCTAssertEqual(LinkMode.accept.rawValue, 0x8000)
        XCTAssertEqual(LinkMode.master.rawValue, 0x0001)
        XCTAssertEqual(LinkMode.authenticated.rawValue, 0x0002)
        XCTAssertEqual(LinkMode.encrypted.rawValue, 0x0004)
        XCTAssertEqual(LinkMode.trusted.rawValue, 0x0008)
        XCTAssertEqual(LinkMode.reliable.rawValue, 0x0010)
        XCTAssertEqual(LinkMode.secure.rawValue, 0x0020)
    }

    func testRFCOMMStateRoundTrip() {
        for state in RFCOMMState.allCases {
            XCTAssertEqual(RFCOMMState(rawValue: state.rawValue), state)
        }
        XCTAssertNil(RFCOMMState(rawValue: 0xFF))
    }

    func testHCIBusTypeDescriptions() {
        let expected: [(HCIBusType, String)] = [
            (.virtual, "Virtual"), (.usb, "USB"), (.pcCard, "PCCARD"),
            (.uart, "UART"), (.rs232, "RS232"), (.pci, "PCI"),
            (.sdio, "SDIO"), (.spi, "SPI"), (.i2c, "I2C"),
            (.smd, "SMD"), (.virtio, "VIRTIO")
        ]
        for (type, description) in expected {
            XCTAssertEqual(type.description, description)
            XCTAssertEqual(type.debugDescription, description)
        }
        XCTAssertEqual(HCIBusType(rawValue: 99).description, "Unknown 99")
    }

    func testHCIControllerTypeDescriptions() {
        XCTAssertEqual(HCIControllerType.primary.description, "Primary")
        XCTAssertEqual(HCIControllerType.amp.description, "AMP")
        XCTAssertEqual(HCIControllerType.amp.debugDescription, "AMP")
        XCTAssertEqual(HCIControllerType(rawValue: 42).description, "Unknown 42")
    }

    func testHCIPacketTypeRawValues() {
        XCTAssertEqual(HCIPacketType.command.rawValue, 0x01)
        XCTAssertEqual(HCIPacketType.acl.rawValue, 0x02)
        XCTAssertEqual(HCIPacketType.sco.rawValue, 0x03)
        XCTAssertEqual(HCIPacketType.event.rawValue, 0x04)
        XCTAssertEqual(HCIPacketType.vendor.rawValue, 0xff)
    }

    func testBluetoothSocketProtocol() {
        XCTAssertEqual(BluetoothSocketProtocol.l2cap.rawValue, 0)
        XCTAssertEqual(BluetoothSocketProtocol.hci.rawValue, 1)
        XCTAssertEqual(BluetoothSocketProtocol.rfcomm.rawValue, 3)
        XCTAssertEqual(BluetoothSocketProtocol.l2cap.type, .sequencedPacket)
        XCTAssertEqual(BluetoothSocketProtocol.hci.type, .raw)
        XCTAssertEqual(BluetoothSocketProtocol.sco.type, .sequencedPacket)
        XCTAssertEqual(BluetoothSocketProtocol.rfcomm.type, .stream)
        XCTAssertEqual(BluetoothSocketProtocol.bnep.type, .raw)
        XCTAssertEqual(BluetoothSocketProtocol.cmtp.type, .raw)
        XCTAssertEqual(BluetoothSocketProtocol.hidp.type, .raw)
        XCTAssertEqual(BluetoothSocketProtocol.avdtp.type, .raw)
        #if os(Linux)
        XCTAssertEqual(BluetoothSocketProtocol.family, .bluetooth)
        #endif
    }

    func testSocketOptionIdentifiers() {
        XCTAssertEqual(BluetoothSocketOption.security.rawValue, 4)
        XCTAssertEqual(BluetoothSocketOption.receiveMTU.rawValue, 13)
        XCTAssertEqual(RFCOMMSocketOption.connectionInfo.rawValue, 0x02)
        XCTAssertEqual(RFCOMMSocketOption.linkMode.rawValue, 0x03)
        XCTAssertEqual(RFCOMMSocketOption.optionLevel.rawValue, 18)
        #if os(Linux)
        XCTAssertEqual(BluetoothSocketOption.optionLevel, .bluetooth)
        #endif
    }

    func testSecuritySocketOptionRoundTrip() throws {
        let option = BluetoothSocketOption.Security(level: .high, keySize: 16)
        XCTAssertEqual(option.level, .high)
        XCTAssertEqual(option.keySize, 16)
        // Encode, then decode through the socket-option byte interface.
        let decoded = BluetoothSocketOption.Security.withUnsafeBytes { destination in
            option.withUnsafeBytes { source in
                destination.copyMemory(from: source)
            }
        }
        XCTAssertEqual(decoded, option)
        XCTAssertEqual(decoded.level, .high)
        XCTAssertEqual(decoded.keySize, 16)
        XCTAssertEqual(BluetoothSocketOption.Security().level, .sdp)
    }

    func testRFCOMMLinkModeSocketOptionRoundTrip() {
        let option = RFCOMMSocketOption.LinkMode(linkMode: [.master, .encrypted])
        let decoded = RFCOMMSocketOption.LinkMode.withUnsafeBytes { destination in
            option.withUnsafeBytes { source in
                destination.copyMemory(from: source)
            }
        }
        XCTAssertEqual(decoded.linkMode, [.master, .encrypted])
        XCTAssertTrue(RFCOMMSocketOption.LinkMode().linkMode.isEmpty)
    }

    func testRFCOMMConnectionInfoRoundTrip() {
        let empty = RFCOMMSocketOption.ConnectionInfo()
        XCTAssertEqual(empty.handle, 0)
        let decoded = RFCOMMSocketOption.ConnectionInfo.withUnsafeBytes { buffer in
            buffer.storeBytes(of: 7, toByteOffset: 0, as: UInt16.self)
        }
        XCTAssertEqual(decoded.handle, 7)
    }
}
