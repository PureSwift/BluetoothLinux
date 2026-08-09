//
//  HCIDeviceTests.swift
//  BluetoothLinuxABITests
//
//  Covers only the parts of the HCI device management family that
//  don't require a real or virtual Bluetooth adapter: input
//  validation that returns before any socket is touched, and
//  hci_send_cmd's wire format, verified over a plain pipe rather than
//  an HCI socket. hci_devinfo/hci_devba/hci_for_each_dev/hci_get_route/
//  hci_send_req all need an actual AF_BLUETOOTH/BTPROTO_HCI device to
//  exercise meaningfully and are covered by neither this file nor a
//  conformance driver yet.
//

import Testing
#if canImport(Glibc)
import Glibc
#elseif canImport(Darwin)
import Darwin
#endif
import CBluetoothLinuxABI
@testable import BluetoothLinuxABI

@Suite("HCI Device")
struct HCIDeviceTests {

    @Test("hci_open_dev rejects a negative device id before opening a socket")
    func openDevRejectsNegativeID() {
        errno = 0
        #expect(BluetoothLinuxABI.hci_open_dev(-1) == -1)
        #expect(errno == ENODEV)
    }

    @Test("hci_close_dev on an invalid descriptor fails like close(2)")
    func closeDevInvalidDescriptor() {
        #expect(BluetoothLinuxABI.hci_close_dev(-1) == -1)
    }

    @Test("hci_send_cmd writes the exact HCI command packet layout")
    func sendCmdPacketLayout() {
        var fds: [Int32] = [0, 0]
        let pipeResult = fds.withUnsafeMutableBufferPointer { pipe($0.baseAddress) }
        #expect(pipeResult == 0)
        let readEnd = fds[0]
        let writeEnd = fds[1]
        defer {
            close(readEnd)
            close(writeEnd)
        }

        var parameter: UInt8 = 0x42
        let result = withUnsafeMutableBytes(of: &parameter) { buffer in
            BluetoothLinuxABI.hci_send_cmd(writeEnd, 0x03, 0x0003, 1, buffer.baseAddress)
        }
        #expect(result == 0)

        var received = [UInt8](repeating: 0, count: 5)
        let bytesRead = received.withUnsafeMutableBytes { read(readEnd, $0.baseAddress, $0.count) }
        #expect(bytesRead == 5)

        // HCI_COMMAND_PKT
        #expect(received[0] == 0x01)
        // opcode, little-endian: ocf | (ogf << 10) = 0x0003 | (0x03 << 10) = 0x0C03
        #expect(received[1] == 0x03)
        #expect(received[2] == 0x0C)
        // plen
        #expect(received[3] == 1)
        // the single parameter byte
        #expect(received[4] == 0x42)
    }

    @Test("hci_send_cmd omits the parameter iovec when plen is 0")
    func sendCmdNoParameter() {
        var fds: [Int32] = [0, 0]
        let pipeResult = fds.withUnsafeMutableBufferPointer { pipe($0.baseAddress) }
        #expect(pipeResult == 0)
        let readEnd = fds[0]
        let writeEnd = fds[1]
        defer {
            close(readEnd)
            close(writeEnd)
        }

        let result = BluetoothLinuxABI.hci_send_cmd(writeEnd, 0x01, 0x0001, 0, nil)
        #expect(result == 0)

        var received = [UInt8](repeating: 0, count: 4)
        let bytesRead = received.withUnsafeMutableBytes { read(readEnd, $0.baseAddress, $0.count) }
        #expect(bytesRead == 4)
        #expect(received[3] == 0)
    }
}
