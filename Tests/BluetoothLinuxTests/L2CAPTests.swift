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
import BluetoothGAP
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
        do {
            do { try await controller.enableLowEnergyAdvertising(false) }
            catch HCIError.commandDisallowed { /* ignore */ }

            let encoder = GAPDataEncoder()
            let advertisingData = try encoder.encodeAdvertisingData([
                GAPShortLocalName(name: "Test")
            ])
            try await controller.setLowEnergyAdvertisingData(advertisingData)

            do { try await controller.enableLowEnergyAdvertising() }
            catch HCIError.commandDisallowed { /* ignore */ }
        }
        catch {
            NSLog("Unable to enable advertising. \(error)")
        }
        NSLog("Enabled advertising")
        let address = try await controller.readDeviceAddress()
        NSLog("Will create server socket \(address)")
        let serverSocket = try await BluetoothLinux.L2CAPSocket.lowEnergyServer(
            address: address
        )
        NSLog("Created server socket")
        let newConnection = try await serverSocket.accept()
        NSLog("Server Connected")
        let service = GATTAttribute.Service(
            uuid: .deviceInformation,
            primary: true,
            characteristics: [
                GATTAttribute.Characteristic(
                    uuid: GATTManufacturerNameString.uuid,
                    value: GATTManufacturerNameString(rawValue: "PureSwift").data,
                    permissions: [.read],
                    properties: [.read],
                    descriptors: []
                ),
                GATTAttribute.Characteristic(
                    uuid: GATTModelNumber.uuid,
                    value: GATTModelNumber(rawValue: "SolarInverter1,1").data,
                    permissions: [.read],
                    properties: [.read],
                    descriptors: []
                ),
                GATTAttribute.Characteristic(
                    uuid: GATTHardwareRevisionString.uuid,
                    value: GATTHardwareRevisionString(rawValue: "1.0.0").data,
                    permissions: [.read],
                    properties: [.read],
                    descriptors: []
                ),
                GATTAttribute.Characteristic(
                    uuid: GATTFirmwareRevisionString.uuid,
                    value: GATTFirmwareRevisionString(rawValue: "1.0.1").data,
                    permissions: [.read],
                    properties: [.read],
                    descriptors: []
                ),
            ]
        )
        let service2 = GATTAttribute.Service(
            uuid: .savantSystems,
            primary: true,
            characteristics: [
                    GATTAttribute.Characteristic(
                    uuid: .savantSystems2,
                    value: GATTManufacturerNameString(rawValue: "PureSwift").data,
                    permissions: [.read, .write],
                    properties: [.read, .write],
                    descriptors: []
                )
            ]
        )
        let batteryService = GATTAttribute.Service(
            uuid: .batteryService,
            primary: true,
            characteristics: [
                    GATTAttribute.Characteristic(
                    uuid: .batteryService,
                    value: GATTBatteryLevel(level: .init(rawValue: 95)!).data,
                    permissions: [.read],
                    properties: [.read],
                    descriptors: []
                )
            ]
        )
        let database = GATTDatabase(services: [service, service2, batteryService])
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
