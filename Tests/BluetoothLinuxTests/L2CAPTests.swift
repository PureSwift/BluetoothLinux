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
        NSLog("Will create server socket \(address)")
        let serverSocket = try await BluetoothLinux.L2CAPSocket.lowEnergyServer(
            address: address
        )
        NSLog("Created server socket")
        let newConnection = try await serverSocket.accept()
        NSLog("Server Connected")
        let characteristic = GATTAttribute.Characteristic(
                uuid: GATTManufacturerNameString.uuid,
                value: GATTManufacturerNameString(rawValue: "PureSwift").data,
                permissions: [.read],
                properties: [.read],
                descriptors: []
        )
        let service = GATTAttribute.Service(
            uuid: .deviceInformation,
            primary: true,
            characteristics: [characteristic]
        )
        let database = GATTDatabase(services: [service])
        var logs = [String]()
        let server = await GATTServer(
            socket: newConnection, 
            maximumTransmissionUnit: .max,
            maximumPreparedWrites: 1000,
            database: database,
            log: { 
                NSLog("Server: \($0)")
                logs.append($0)
            }
        )
        // 
        for await event in newConnection.event {
            NSLog("Server: \(event)")
        }
    }
}
