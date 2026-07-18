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
