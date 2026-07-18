//
//  IOControlTests.swift
//  BluetoothLinuxTests
//
//  Unit tests for ioctl() calls using the syscall mocking scaffolding
//  (see Sources/BluetoothLinux/Internal/Mocking.swift), modeled after
//  swift-system's MockingTest / TestingInfrastructure.
//
//  These run without Bluetooth hardware on both Linux and Darwin:
//  `MockingDriver.withMockingEnabled` intercepts `system_ioctl` on the
//  current thread, records a trace of (fd, request, argument), and lets
//  the test fake the kernel's reply or force an errno.
//

#if ENABLE_MOCKING
import Foundation
import XCTest
import Bluetooth
import BluetoothHCI
import SystemPackage
import Socket
@testable import BluetoothLinux
#if canImport(Glibc)
import Glibc
#elseif canImport(Darwin)
import Darwin
#endif

final class IOControlTests: XCTestCase {

    /// A fake file descriptor; mocked syscalls never reach the kernel.
    private let fileDescriptor = SocketDescriptor(rawValue: 3)

    func testDeviceUpIsTraced() throws {
        try MockingDriver.withMockingEnabled { driver in
            try fileDescriptor.deviceUp(for: .init(rawValue: 1))
            XCTAssertEqual(
                driver.trace.dequeue(),
                Trace.Entry(name: "ioctl", [
                    fileDescriptor.rawValue,
                    HostControllerIO.deviceUp.rawValue,
                    Int32(1)
                ])
            )
            XCTAssertTrue(driver.trace.isEmpty)
        }
    }

    func testDeviceDownIsTraced() throws {
        try MockingDriver.withMockingEnabled { driver in
            try fileDescriptor.deviceDown(for: .init(rawValue: 2))
            XCTAssertEqual(
                driver.trace.dequeue(),
                Trace.Entry(name: "ioctl", [
                    fileDescriptor.rawValue,
                    HostControllerIO.deviceDown.rawValue,
                    Int32(2)
                ])
            )
            XCTAssertTrue(driver.trace.isEmpty)
        }
    }

    func testDeviceInformationFakedKernelReply() throws {
        try MockingDriver.withMockingEnabled { driver in
            driver.ioctlHandler = { fd, request, pointer in
                XCTAssertEqual(request, HostControllerIO.getDeviceInfo.rawValue)
                guard let pointer else {
                    XCTFail("Expected an out-parameter for HCIGETDEVINFO")
                    errno = EINVAL
                    return -1
                }
                var info = CInterop.HCIDeviceInformation(id: 0)
                info.name = (0x68, 0x63, 0x69, 0x30, 0, 0, 0, 0) // "hci0"
                info.address = (1, 2, 3, 4, 5, 6)
                info.flags = 0b0000_0100 // .running bit
                info.type = 0x13 // busType 0x3, controllerType 0x1
                pointer.storeBytes(of: info, as: CInterop.HCIDeviceInformation.self)
                return 0
            }
            let information = try fileDescriptor.deviceInformation(for: .init(rawValue: 0))
            XCTAssertEqual(information.id, HostController.ID(rawValue: 0))
            XCTAssertEqual(information.name, "hci0")
            XCTAssertEqual(information.address, BluetoothAddress(bytes: (1, 2, 3, 4, 5, 6)))
            XCTAssertTrue(information.flags.contains(.running))
            XCTAssertEqual(
                driver.trace.dequeue(),
                Trace.Entry(name: "ioctl", [
                    fileDescriptor.rawValue,
                    HostControllerIO.getDeviceInfo.rawValue
                ])
            )
            XCTAssertTrue(driver.trace.isEmpty)
        }
    }

    func testRFCOMMCreateDeviceIsTraced() throws {
        try MockingDriver.withMockingEnabled { driver in
            try fileDescriptor.rfcommCreateDevice(
                id: .init(rawValue: 0),
                flags: [.reuseDLC],
                source: BluetoothAddress(bytes: (1, 2, 3, 4, 5, 6)),
                destination: BluetoothAddress(bytes: (6, 5, 4, 3, 2, 1)),
                channel: 1
            )
            XCTAssertEqual(
                driver.trace.dequeue(),
                Trace.Entry(name: "ioctl", [
                    fileDescriptor.rawValue,
                    RFCOMMIO.createDevice.rawValue
                ])
            )
            XCTAssertTrue(driver.trace.isEmpty)
        }
    }

    func testRFCOMMReleaseDeviceIsTraced() throws {
        try MockingDriver.withMockingEnabled { driver in
            try fileDescriptor.rfcommReleaseDevice(id: .init(rawValue: 3))
            XCTAssertEqual(
                driver.trace.dequeue(),
                Trace.Entry(name: "ioctl", [
                    fileDescriptor.rawValue,
                    RFCOMMIO.releaseDevice.rawValue
                ])
            )
            XCTAssertTrue(driver.trace.isEmpty)
        }
    }

    func testDeviceListFakedKernelReply() throws {
        try MockingDriver.withMockingEnabled { driver in
            driver.ioctlHandler = { fd, request, pointer in
                XCTAssertEqual(fd, self.fileDescriptor.rawValue)
                XCTAssertEqual(request, HostControllerIO.getDeviceList.rawValue)
                guard let pointer else {
                    XCTFail("Expected an out-parameter for HCIGETDEVLIST")
                    errno = EINVAL
                    return -1
                }
                // Write the reply the way the kernel would: dev_num followed
                // by hci_dev_req entries (uint16 dev_id, uint32 dev_opt at
                // 4-byte alignment — the C layout of hci_dev_list_req).
                pointer.storeBytes(of: UInt16(2), as: UInt16.self)
                pointer.storeBytes(
                    of: CInterop.HCIDeviceList.Element(id: 0, options: 0),
                    toByteOffset: 4,
                    as: CInterop.HCIDeviceList.Element.self
                )
                pointer.storeBytes(
                    of: CInterop.HCIDeviceList.Element(id: 5, options: 0),
                    toByteOffset: 4 + MemoryLayout<CInterop.HCIDeviceList.Element>.stride,
                    as: CInterop.HCIDeviceList.Element.self
                )
                return 0
            }
            let deviceList = try fileDescriptor.deviceList()
            XCTAssertEqual(deviceList.count, 2)
            XCTAssertEqual(deviceList[0].id, HostController.ID(rawValue: 0))
            XCTAssertEqual(deviceList[1].id, HostController.ID(rawValue: 5))
            XCTAssertEqual(
                driver.trace.dequeue(),
                Trace.Entry(name: "ioctl", [
                    fileDescriptor.rawValue,
                    HostControllerIO.getDeviceList.rawValue
                ])
            )
            XCTAssertTrue(driver.trace.isEmpty)
        }
    }

    func testForcedErrnoThrows() {
        MockingDriver.withMockingEnabled { driver in
            driver.forceErrno = .always(errno: ENODEV)
            do {
                try fileDescriptor.deviceUp(for: .init(rawValue: 0))
                XCTFail("Expected ENODEV to be thrown")
            } catch {
                XCTAssertEqual(error as? Errno, Errno(rawValue: ENODEV))
            }
            XCTAssertNotNil(driver.trace.dequeue())
            XCTAssertTrue(driver.trace.isEmpty)
        }
    }

    func testInterruptedCallIsRetried() {
        MockingDriver.withMockingEnabled { driver in
            driver.forceErrno = .counted(errno: EINTR, count: 2)
            do {
                try fileDescriptor.deviceUp(for: .init(rawValue: 0))
            } catch {
                XCTFail("EINTR should have been retried, got \(error)")
            }
            // 2 interrupted attempts + 1 success
            XCTAssertNotNil(driver.trace.dequeue())
            XCTAssertNotNil(driver.trace.dequeue())
            XCTAssertNotNil(driver.trace.dequeue())
            XCTAssertTrue(driver.trace.isEmpty)
        }
    }

    func testMockingIsScoped() {
        XCTAssertFalse(mockingEnabled)
        MockingDriver.withMockingEnabled { _ in
            XCTAssertTrue(mockingEnabled)
        }
        XCTAssertFalse(mockingEnabled)
    }
}
#endif // ENABLE_MOCKING
