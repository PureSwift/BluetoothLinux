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

    func testInquiryFakedKernelReply() throws {
        try MockingDriver.withMockingEnabled { driver in
            driver.ioctlHandler = { fd, request, pointer in
                XCTAssertEqual(request, HostControllerIO.inquiry.rawValue)
                guard let pointer else {
                    XCTFail("Expected a request buffer for HCIINQUIRY")
                    errno = EINVAL
                    return -1
                }
                // Verify the request the caller marshalled.
                var inquiry = pointer.assumingMemoryBound(to: CInterop.HCIInquiryRequest.self).pointee
                XCTAssertEqual(inquiry.id, 0)
                XCTAssertEqual(inquiry.length, 4)
                XCTAssertEqual(inquiry.responseCount, 8)
                XCTAssertEqual(inquiry.flags, HostController.ScanOption.flushCache.rawValue)
                XCTAssertEqual(inquiry.lap.0, 0x33) // GIAC
                // Reply with 2 (zeroed) inquiry results, as the kernel would.
                inquiry.responseCount = 2
                pointer.assumingMemoryBound(to: CInterop.HCIInquiryRequest.self).pointee = inquiry
                for index in 0 ..< 2 {
                    // The kernel writes results at C sizeof (stride), see HCIScan.swift.
                    let offset = MemoryLayout<CInterop.HCIInquiryRequest>.stride
                        + (MemoryLayout<CInterop.HCIInquiryResult>.stride * index)
                    pointer.storeBytes(of: CInterop.HCIInquiryResult(), toByteOffset: offset, as: CInterop.HCIInquiryResult.self)
                }
                return 0
            }
            let results = try fileDescriptor.inquiry(
                device: .init(rawValue: 0),
                duration: 4,
                limit: 8,
                options: [.flushCache]
            )
            XCTAssertEqual(results.count, 2)
            XCTAssertEqual(results[0].address, .zero)
            XCTAssertEqual(
                driver.trace.dequeue(),
                Trace.Entry(name: "ioctl", [
                    fileDescriptor.rawValue,
                    HostControllerIO.inquiry.rawValue
                ])
            )
            XCTAssertTrue(driver.trace.isEmpty)
        }
    }

    func testRFCOMMDeviceListFakedKernelReply() throws {
        try MockingDriver.withMockingEnabled { driver in
            let expected = CInterop.RFCOMMDeviceInformation(
                id: 7,
                flags: RFCOMMFlag.reuseDLC.rawValue,
                state: RFCOMMState.connected.rawValue,
                source: BluetoothAddress(bytes: (1, 2, 3, 4, 5, 6)),
                destination: BluetoothAddress(bytes: (6, 5, 4, 3, 2, 1)),
                channel: 2
            )
            driver.ioctlHandler = { fd, request, pointer in
                XCTAssertEqual(request, RFCOMMIO.getDeviceList.rawValue)
                guard let pointer else {
                    XCTFail("Expected a request buffer for RFCOMMGETDEVLIST")
                    errno = EINVAL
                    return -1
                }
                pointer.assumingMemoryBound(to: CInterop.RFCOMMDeviceListRequest.self).pointee.count = 1
                // dev_info[] starts at the count padded to element alignment,
                // matching `struct rfcomm_dev_list_req` (see RFCOMMGetDeviceList.swift).
                let alignment = MemoryLayout<CInterop.RFCOMMDeviceInformation>.alignment
                let offset = (MemoryLayout<CInterop.RFCOMMDeviceListRequest>.size + alignment - 1)
                    & ~(alignment - 1)
                pointer.storeBytes(
                    of: expected,
                    toByteOffset: offset,
                    as: CInterop.RFCOMMDeviceInformation.self
                )
                return 0
            }
            let devices = try fileDescriptor.rfcommListDevices()
            XCTAssertEqual(devices.count, 1)
            XCTAssertEqual(devices[0].id, HostController.ID(rawValue: 7))
            XCTAssertEqual(devices[0].flags, [.reuseDLC])
            XCTAssertEqual(devices[0].state, .connected)
            XCTAssertEqual(devices[0].source, BluetoothAddress(bytes: (1, 2, 3, 4, 5, 6)))
            XCTAssertEqual(devices[0].destination, BluetoothAddress(bytes: (6, 5, 4, 3, 2, 1)))
            XCTAssertEqual(devices[0].channel, 2)
            XCTAssertNotNil(driver.trace.dequeue())
            XCTAssertTrue(driver.trace.isEmpty)
        }
    }

    func testRFCOMMGetDeviceInformationFakedKernelReply() throws {
        try MockingDriver.withMockingEnabled { driver in
            driver.ioctlHandler = { fd, request, pointer in
                XCTAssertEqual(request, RFCOMMIO.getDeviceInfo.rawValue)
                guard let pointer else {
                    XCTFail("Expected an out-parameter for RFCOMMGETDEVINFO")
                    errno = EINVAL
                    return -1
                }
                let info = pointer.assumingMemoryBound(to: CInterop.RFCOMMDeviceInformation.self)
                XCTAssertEqual(info.pointee.id, 3)
                info.pointee.flags = RFCOMMFlag.releaseOnHangup.rawValue
                info.pointee.state = RFCOMMState.listening.rawValue
                info.pointee.source = BluetoothAddress(bytes: (1, 2, 3, 4, 5, 6))
                info.pointee.destination = BluetoothAddress(bytes: (6, 5, 4, 3, 2, 1))
                info.pointee.channel = 5
                return 0
            }
            let device = try fileDescriptor.rfcommGetDevice(id: .init(rawValue: 3))
            XCTAssertEqual(device.id, HostController.ID(rawValue: 3))
            XCTAssertEqual(device.flags, [.releaseOnHangup])
            XCTAssertEqual(device.state, .listening)
            XCTAssertEqual(device.source, BluetoothAddress(bytes: (1, 2, 3, 4, 5, 6)))
            XCTAssertEqual(device.destination, BluetoothAddress(bytes: (6, 5, 4, 3, 2, 1)))
            XCTAssertEqual(device.channel, 5)
            XCTAssertNotNil(driver.trace.dequeue())
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
