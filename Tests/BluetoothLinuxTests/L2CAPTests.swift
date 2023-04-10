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
        guard let controller = try await self.controller else {
            return
        }
        let testData = Data("test1234-\(UUID())".utf8)
        NSLog("Will create server socket")
        let server = try await BluetoothLinux.L2CAPSocket.lowEnergyServer(
            hostController: controller.a
        )
        NSLog("Created server socket")
        let address = try await controller.b.readDeviceAddress()
        NSLog("Will create client socket")
        let client = try await BluetoothLinux.L2CAPSocket.lowEnergyClient(
            address: address,
            destination: server.address,
            type: .public
        )
        NSLog("Client Connected")
        let clientTask = Task {
            try await client.send(testData)
            NSLog("Client sent")
            let recievedData = try await client.recieve(256)
            NSLog("Client recieved")
            XCTAssertEqual(recievedData, testData)
            return client
        }
        let newConnection = try await server.accept()
        NSLog("Server Connected")
        let recievedData = try await newConnection.recieve(256)
        NSLog("Server recieved")
        XCTAssertEqual(recievedData, testData)
        try await newConnection.send(testData)
        NSLog("Server sent")
        _ = try await clientTask.value
    }
}

extension L2CAPTests {
    
    var controller: (a: HostController, b: HostController)? {
        get async throws {
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
            NSLog("Loading controllers")
            for (index, controller) in controllers.prefix(2).enumerated() {
                let information = try HostController.deviceInformation(for: controller.id)
                NSLog(
                """

                \(index + 1). \(information.name)
                \((information.address.description))
                \((information.busType.description))
                """)
            }
            return (controllers[0], controllers[1])
        }
    }
}
