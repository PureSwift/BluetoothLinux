//
//  L2CAPTests.swift
//  
//
//  Created by Alsey Coleman Miller on 4/10/23.
//

import Foundation
import XCTest
import Bluetooth
import BluetoothHCI
import BluetoothGATT
@testable import BluetoothLinux

final class L2CAPTests: XCTestCase {
    
    func testServerConnection() async throws {
        guard ProcessInfo.processInfo.environment["SWIFT_BLUETOOTH_HARDWARE_TEST_SERVER"] != nil else {
            return
        }
        guard let controller = await BluetoothLinux.HostController.default else {
            XCTFail()
            return
        }
        let address = try await controller.readDeviceAddress()
        NSLog("Will create server socket")
        let server = try await BluetoothLinux.L2CAPSocket.lowEnergyServer(
            address: address
        )
        NSLog("Created server socket")
        let newConnection = try await server.accept()
        NSLog("Server Connected")
        let recievedData = try await newConnection.recieve(256)
        NSLog("Server recieved")
        XCTAssertEqual(recievedData, Data("test-client-1234".utf8))
        try await newConnection.send(Data("test-server-1234".utf8))
        NSLog("Server sent")
        try? await Task.sleep(nanoseconds: 1_000_000_000)
    }

    func testClientConnection() async throws {
        guard let serverAddress = ProcessInfo.processInfo.environment["SWIFT_BLUETOOTH_HARDWARE_TEST_CLIENT"].flatMap({ BluetoothAddress(rawValue: $0) }) else {
            return
        }
        guard let controller = await BluetoothLinux.HostController.default else {
            XCTFail()
            return
        }
        let address = try await controller.readDeviceAddress()
        NSLog("Will create client socket")
        let client = try await BluetoothLinux.L2CAPSocket.lowEnergyClient(
            address: address,
            destination: serverAddress,
            type: .public
        )
        NSLog("Client Connected")
        try await client.send(Data("test-client-1234".utf8))
        NSLog("Client sent")
        let recievedData = try await client.recieve(256)
        NSLog("Client recieved")
        XCTAssertEqual(recievedData, Data("test-server-1234".utf8))
        try? await Task.sleep(nanoseconds: 1_000_000_000)
    }
}
