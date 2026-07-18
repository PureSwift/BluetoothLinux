//
//  BNEPTests.swift
//  BluetoothLinuxTests
//

#if ENABLE_MOCKING
import Foundation
import XCTest
import Bluetooth
import SystemPackage
import Socket
@testable import BluetoothLinux
#if canImport(Glibc)
import Glibc
#elseif canImport(Darwin)
import Darwin
#endif

final class BNEPTests: XCTestCase {

    /// A fake file descriptor; mocked syscalls never reach the kernel.
    private let fileDescriptor = SocketDescriptor(rawValue: 3)

    func testIORawValues() {
        // read-direction requests are sign-extended, matching the C `ioctl` request argument
        XCTAssertEqual(BNEPIO.addConnection.rawValue, 0x400442C8)
        XCTAssertEqual(BNEPIO.removeConnection.rawValue, 0x400442C9)
        XCTAssertEqual(BNEPIO.getConnectionList.rawValue, UInt(bitPattern: Int(Int32(bitPattern: 0x800442D2))))
        XCTAssertEqual(BNEPIO.getConnectionInfo.rawValue, UInt(bitPattern: Int(Int32(bitPattern: 0x800442D3))))
        XCTAssertEqual(BNEPIO.getSupportedFeatures.rawValue, UInt(bitPattern: Int(Int32(bitPattern: 0x800442D4))))
        for value in BNEPIO.allCases {
            XCTAssertEqual(BNEPIO(rawValue: value.rawValue), value)
        }
    }

    func testRequestLayout() {
        // must match the kernel's C struct layouts
        XCTAssertEqual(MemoryLayout<CInterop.BNEPConnectionAddRequest>.size, 26)
        XCTAssertEqual(MemoryLayout<CInterop.BNEPConnectionAddRequest>.stride, 28)
        XCTAssertEqual(MemoryLayout<CInterop.BNEPConnectionDeleteRequest>.size, 10)
        XCTAssertEqual(MemoryLayout<CInterop.BNEPConnectionInformation>.size, 30)
        XCTAssertEqual(MemoryLayout<CInterop.BNEPConnectionInformation>.stride, 32)
        XCTAssertEqual(MemoryLayout<CInterop.BNEPConnectionListRequest>.size, 16)
    }

    func testDeviceName() {
        let bytes = "bnep0".deviceNameBytes
        XCTAssertEqual(bytes.0, UInt8(ascii: "b"))
        XCTAssertEqual(bytes.4, UInt8(ascii: "0"))
        XCTAssertEqual(bytes.5, 0)
        // truncated to 15 bytes plus null terminator
        let truncated = "a-very-long-interface-name".deviceNameBytes
        XCTAssertEqual(truncated.15, 0)
        let information = CInterop.BNEPConnectionInformation(
            flags: 0,
            role: BNEPRole.networkAccessPoint.rawValue,
            state: BNEPConnectionState.connected.rawValue,
            destination: BluetoothAddress(bytes: (1, 2, 3, 4, 5, 6)),
            device: bytes
        )
        let connection = BNEPConnection(information)
        XCTAssertEqual(connection.device, "bnep0")
        XCTAssertEqual(connection.role, .networkAccessPoint)
        XCTAssertEqual(connection.state, .connected)
        XCTAssertEqual(connection.destination, BluetoothAddress(bytes: (1, 2, 3, 4, 5, 6)))
    }

    func testAddConnectionFakedKernelReply() throws {
        try MockingDriver.withMockingEnabled { driver in
            driver.ioctlHandler = { fd, request, pointer in
                XCTAssertEqual(request, BNEPIO.addConnection.rawValue)
                guard let pointer else {
                    XCTFail("Expected a request buffer for BNEPCONNADD")
                    errno = EINVAL
                    return -1
                }
                let request = pointer.assumingMemoryBound(to: CInterop.BNEPConnectionAddRequest.self)
                XCTAssertEqual(request.pointee.socket, 7)
                XCTAssertEqual(request.pointee.role, BNEPRole.personalAreaNetworkUser.rawValue)
                // kernel writes back the created interface name
                request.pointee.device = "bnep0".deviceNameBytes
                return 0
            }
            let device = try fileDescriptor.bnepAddConnection(
                socket: SocketDescriptor(rawValue: 7),
                role: .personalAreaNetworkUser
            )
            XCTAssertEqual(device, "bnep0")
        }
    }

    func testRemoveConnectionIsTraced() throws {
        try MockingDriver.withMockingEnabled { driver in
            try fileDescriptor.bnepRemoveConnection(
                destination: BluetoothAddress(bytes: (1, 2, 3, 4, 5, 6))
            )
            XCTAssertEqual(
                driver.trace.dequeue(),
                Trace.Entry(name: "ioctl", [
                    fileDescriptor.rawValue,
                    BNEPIO.removeConnection.rawValue
                ])
            )
            XCTAssertTrue(driver.trace.isEmpty)
        }
    }

    func testConnectionListFakedKernelReply() throws {
        try MockingDriver.withMockingEnabled { driver in
            let expected = CInterop.BNEPConnectionInformation(
                flags: BNEPConnectionFlag.setupResponse.rawValue,
                role: BNEPRole.networkAccessPoint.rawValue,
                state: BNEPConnectionState.connected.rawValue,
                destination: BluetoothAddress(bytes: (6, 5, 4, 3, 2, 1)),
                device: "bnep0".deviceNameBytes
            )
            driver.ioctlHandler = { fd, request, pointer in
                XCTAssertEqual(request, BNEPIO.getConnectionList.rawValue)
                guard let pointer else {
                    XCTFail("Expected a request buffer for BNEPGETCONNLIST")
                    errno = EINVAL
                    return -1
                }
                let request = pointer.assumingMemoryBound(to: CInterop.BNEPConnectionListRequest.self)
                guard let connections = request.pointee.connections else {
                    XCTFail("Expected a connection buffer")
                    errno = EINVAL
                    return -1
                }
                XCTAssertGreaterThanOrEqual(request.pointee.count, 1)
                connections[0] = expected
                request.pointee.count = 1
                return 0
            }
            let connections = try fileDescriptor.bnepConnectionList(limit: 8)
            XCTAssertEqual(connections.count, 1)
            XCTAssertEqual(connections[0].device, "bnep0")
            XCTAssertEqual(connections[0].role, .networkAccessPoint)
            XCTAssertEqual(connections[0].state, .connected)
            XCTAssertEqual(connections[0].flags, [.setupResponse])
            XCTAssertEqual(connections[0].destination, BluetoothAddress(bytes: (6, 5, 4, 3, 2, 1)))
        }
    }

    func testSupportedFeaturesFakedKernelReply() throws {
        try MockingDriver.withMockingEnabled { driver in
            driver.ioctlHandler = { fd, request, pointer in
                XCTAssertEqual(request, BNEPIO.getSupportedFeatures.rawValue)
                guard let pointer else {
                    XCTFail("Expected a request buffer for BNEPGETSUPPFEAT")
                    errno = EINVAL
                    return -1
                }
                pointer.assumingMemoryBound(to: UInt32.self).pointee = 1
                return 0
            }
            let features = try fileDescriptor.bnepSupportedFeatures()
            XCTAssertEqual(features.features, 1)
            XCTAssertTrue(features.isSetupResponseSupported)
        }
    }
}
#endif
