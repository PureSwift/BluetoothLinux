//
//  HCIStringsTests.swift
//  BluetoothLinuxABITests
//
//  Round-trip and behavior tests for the HCI string converter family,
//  asserting the reference (BlueZ `lib/bluetooth/hci.c`) behavior.
//

import Testing
#if canImport(Glibc)
import Glibc
#elseif canImport(Darwin)
import Darwin
#endif
import CBluetoothLinuxABI
@testable import BluetoothLinuxABI

@Suite("HCI Strings")
struct HCIStringsTests {

    @Test func bus() {
        #expect(String(cString: BluetoothLinuxABI.hci_bustostr(Int32(HCI_USB))!) == "USB")
        #expect(String(cString: BluetoothLinuxABI.hci_bustostr(99)!) == "Unknown")
        #expect(String(cString: BluetoothLinuxABI.hci_dtypetostr(Int32(HCI_USB))!) == "USB")
    }

    @Test func deviceType() {
        #expect(String(cString: BluetoothLinuxABI.hci_typetostr(Int32(HCI_PRIMARY))!) == "Primary")
        #expect(String(cString: BluetoothLinuxABI.hci_typetostr(Int32(HCI_AMP))!) == "AMP")
    }

    @Test func deviceFlags() {
        let down = BluetoothLinuxABI.hci_dflagstostr(0)!
        #expect(String(cString: down) == "DOWN ")
        free(down)

        // No "DOWN" prefix once HCI_UP is set, but "UP" itself is still
        // printed — it's just another entry in the device flags table.
        let up = BluetoothLinuxABI.hci_dflagstostr(1 << UInt32(HCI_UP))!
        #expect(String(cString: up) == "UP ")
        free(up)
    }

    @Test func packetType() {
        let str = BluetoothLinuxABI.hci_ptypetostr(UInt32(HCI_DM1) | UInt32(HCI_DH1))!
        #expect(String(cString: str) == "DM1 DH1 ")
        free(str)

        var value: UInt32 = 0
        let matched = "DM1,DH1".withCString { BluetoothLinuxABI.hci_strtoptype(UnsafeMutablePointer(mutating: $0), &value) }
        #expect(matched == 1)
        #expect(value == UInt32(HCI_DM1) | UInt32(HCI_DH1))
    }

    @Test func linkMode() {
        // No "PERIPHERAL" prefix once HCI_LM_MASTER is set, but
        // "CENTRAL" (the table entry HCI_LM_MASTER maps to) is still
        // printed by the same bit-table loop.
        let str = BluetoothLinuxABI.hci_lmtostr(UInt32(HCI_LM_MASTER))!
        #expect(String(cString: str) == "CENTRAL ")
        free(str)

        let peripheral = BluetoothLinuxABI.hci_lmtostr(0)!
        #expect(String(cString: peripheral) == "PERIPHERAL ")
        free(peripheral)
    }

    @Test func commands() {
        let str = BluetoothLinuxABI.hci_cmdtostr(0)!
        #expect(String(cString: str) == "Inquiry")
        free(str)
    }

    @Test func version() {
        let str = BluetoothLinuxABI.hci_vertostr(0x09)!
        #expect(String(cString: str) == "5.0")
        free(str)

        var ver: UInt32 = 0
        let matched = "5.0".withCString { BluetoothLinuxABI.hci_strtover(UnsafeMutablePointer(mutating: $0), &ver) }
        #expect(matched == 1)
        #expect(ver == 0x09)
    }
}
