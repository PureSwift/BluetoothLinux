//
//  HIDPTests.swift
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

final class HIDPTests: XCTestCase {

    /// A fake file descriptor; mocked syscalls never reach the kernel.
    private let fileDescriptor = SocketDescriptor(rawValue: 3)

    func testIORawValues() {
        // read-direction requests are sign-extended, matching the C `ioctl` request argument
        XCTAssertEqual(HIDPIO.addConnection.rawValue, 0x400448C8)
        XCTAssertEqual(HIDPIO.removeConnection.rawValue, 0x400448C9)
        XCTAssertEqual(HIDPIO.getConnectionList.rawValue, UInt(bitPattern: Int(Int32(bitPattern: 0x800448D2))))
        XCTAssertEqual(HIDPIO.getConnectionInfo.rawValue, UInt(bitPattern: Int(Int32(bitPattern: 0x800448D3))))
        for value in HIDPIO.allCases {
            XCTAssertEqual(HIDPIO(rawValue: value.rawValue), value)
        }
    }

    func testRequestLayout() {
        // must match the kernel's C struct layouts
        XCTAssertEqual(MemoryLayout<CInterop.HIDPConnectionAddRequest>.size, 168)
        XCTAssertEqual(MemoryLayout<CInterop.HIDPConnectionAddRequest>.stride, 168)
        XCTAssertEqual(MemoryLayout<CInterop.HIDPConnectionDeleteRequest>.size, 12)
        XCTAssertEqual(MemoryLayout<CInterop.HIDPConnectionInformation>.size, 148)
        XCTAssertEqual(MemoryLayout<CInterop.HIDPConnectionListRequest>.size, 16)
    }

    func testDeviceName() {
        let name = "Wireless Keyboard".hidpDeviceName
        XCTAssertEqual(String(hidpDeviceName: name), "Wireless Keyboard")
        // truncated to 127 bytes plus null terminator
        let long = String(repeating: "a", count: 200).hidpDeviceName
        XCTAssertEqual(String(hidpDeviceName: long).count, 127)
    }

    func testAddConnectionFakedKernelReply() throws {
        try MockingDriver.withMockingEnabled { driver in
            let descriptor = Data([0x05, 0x01, 0x09, 0x06]) // partial keyboard descriptor
            driver.ioctlHandler = { fd, request, pointer in
                XCTAssertEqual(request, HIDPIO.addConnection.rawValue)
                guard let pointer else {
                    XCTFail("Expected a request buffer for HIDPCONNADD")
                    errno = EINVAL
                    return -1
                }
                let request = pointer.assumingMemoryBound(to: CInterop.HIDPConnectionAddRequest.self)
                XCTAssertEqual(request.pointee.controlSocket, 7)
                XCTAssertEqual(request.pointee.interruptSocket, 8)
                XCTAssertEqual(request.pointee.parser, 0x0100)
                XCTAssertEqual(request.pointee.vendor, 0x05AC)
                XCTAssertEqual(request.pointee.reportDescriptorSize, 4)
                guard let reportDescriptor = request.pointee.reportDescriptor else {
                    XCTFail("Expected a report descriptor buffer")
                    errno = EINVAL
                    return -1
                }
                XCTAssertEqual(Data(bytes: reportDescriptor, count: 4), descriptor)
                XCTAssertEqual(String(hidpDeviceName: request.pointee.name), "Test Keyboard")
                return 0
            }
            try fileDescriptor.hidpAddConnection(
                controlSocket: SocketDescriptor(rawValue: 7),
                interruptSocket: SocketDescriptor(rawValue: 8),
                vendor: 0x05AC,
                name: "Test Keyboard",
                reportDescriptor: descriptor
            )
        }
    }

    func testRemoveConnectionIsTraced() throws {
        try MockingDriver.withMockingEnabled { driver in
            try fileDescriptor.hidpRemoveConnection(
                destination: BluetoothAddress(bytes: (1, 2, 3, 4, 5, 6))
            )
            XCTAssertEqual(
                driver.trace.dequeue(),
                Trace.Entry(name: "ioctl", [
                    fileDescriptor.rawValue,
                    HIDPIO.removeConnection.rawValue
                ])
            )
            XCTAssertTrue(driver.trace.isEmpty)
        }
    }

    func testConnectionListFakedKernelReply() throws {
        try MockingDriver.withMockingEnabled { driver in
            let expected = CInterop.HIDPConnectionInformation(
                address: BluetoothAddress(bytes: (6, 5, 4, 3, 2, 1)),
                flags: HIDPConnectionFlag.bootProtocolMode.rawValue,
                state: HIDPConnectionState.connected.rawValue,
                vendor: 0x05AC,
                product: 0x022C,
                version: 0x011B,
                name: "Test Keyboard".hidpDeviceName
            )
            driver.ioctlHandler = { fd, request, pointer in
                XCTAssertEqual(request, HIDPIO.getConnectionList.rawValue)
                guard let pointer else {
                    XCTFail("Expected a request buffer for HIDPGETCONNLIST")
                    errno = EINVAL
                    return -1
                }
                let request = pointer.assumingMemoryBound(to: CInterop.HIDPConnectionListRequest.self)
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
            let connections = try fileDescriptor.hidpConnectionList(limit: 8)
            XCTAssertEqual(connections.count, 1)
            XCTAssertEqual(connections[0].name, "Test Keyboard")
            XCTAssertEqual(connections[0].flags, [.bootProtocolMode])
            XCTAssertEqual(connections[0].state, .connected)
            XCTAssertEqual(connections[0].vendor, 0x05AC)
            XCTAssertEqual(connections[0].product, 0x022C)
            XCTAssertEqual(connections[0].address, BluetoothAddress(littleEndian: BluetoothAddress(bytes: (6, 5, 4, 3, 2, 1))))
        }
    }

    func testConnectionInformationFakedKernelReply() throws {
        try MockingDriver.withMockingEnabled { driver in
            driver.ioctlHandler = { fd, request, pointer in
                XCTAssertEqual(request, HIDPIO.getConnectionInfo.rawValue)
                guard let pointer else {
                    XCTFail("Expected a request buffer for HIDPGETCONNINFO")
                    errno = EINVAL
                    return -1
                }
                let request = pointer.assumingMemoryBound(to: CInterop.HIDPConnectionInformation.self)
                request.pointee.state = HIDPConnectionState.connected.rawValue
                request.pointee.vendor = 0x05AC
                request.pointee.name = "Test Mouse".hidpDeviceName
                return 0
            }
            let connection = try fileDescriptor.hidpConnectionInformation(
                for: BluetoothAddress(bytes: (1, 2, 3, 4, 5, 6))
            )
            XCTAssertEqual(connection.name, "Test Mouse")
            XCTAssertEqual(connection.state, .connected)
            XCTAssertEqual(connection.vendor, 0x05AC)
        }
    }
}
#endif
