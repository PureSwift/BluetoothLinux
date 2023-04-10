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
    
    func testConnection() async throws {
        guard let controller = await self.controller else {
            return
        }
        let testData = Data("test1234-\(UUID())".utf8)
        let server = try await BluetoothLinux.L2CAPSocket.lowEnergyServer(
            hostController: controller.a
        )
        let clientTask = Task {
            let client = try await BluetoothLinux.L2CAPSocket.lowEnergyClient(
                address: controller.b.readDeviceAddress(),
                destination: server.address,
                type: .public
            )
            try await client.send(testData)
            print("Client sent")
            let recievedData = try await client.recieve(256)
            print("Client recieved")
            XCTAssertEqual(recievedData, testData)
            return client
        }
        let newConnection = try await server.accept()
        print("Connected")
        let recievedData = try await newConnection.recieve(256)
        print("Server recieved")
        XCTAssertEqual(recievedData, testData)
        try await newConnection.send(testData)
        print("Server sent")
    }
}

extension L2CAPTests {
    
    var controller: (a: HostController, b: HostController)? {
        get async {
            let isLinux: Bool
            #if os(Linux)
            isLinux = true
            #else
            isLinux = false
            #endif
            let testsEnabled = ProcessInfo.processInfo.environment["SWIFT_BLUETOOTH_HARDWARE_TEST"] != nil
            let controllers = await BluetoothLinux.HostController.controllers
            guard isLinux, testsEnabled, controllers.count == 2 else {
                return nil
            }
            return (controllers[0], controllers[1])
        }
    }
}
