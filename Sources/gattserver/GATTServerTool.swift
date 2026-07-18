//
//  GATTServerTool.swift
//  BluetoothLinux
//
//  Advertise and serve a demo GATT database.
//

import Foundation
import ArgumentParser
import Bluetooth
import BluetoothGAP
import BluetoothGATT
import BluetoothHCI
import BluetoothLinux

@main
struct GATTServerTool: AsyncParsableCommand {

    static let configuration = CommandConfiguration(
        commandName: "gattserver",
        abstract: "Advertise and serve a demo GATT database (requires root)."
    )

    @Option(name: [.customShort("i"), .long], help: "The controller to use (e.g. hci0).", transform: HostController.ID.parse)
    var device: HostController.ID?

    @Option(help: "The advertised local name.")
    var name: String = "BluetoothLinux"

    @Flag(name: .shortAndLong, help: "Log GATT server events.")
    var verbose = false

    func run() async throws {
        let controller = try await HostController.command(device: device)
        try await startAdvertising(controller)
        let address = try await controller.readDeviceAddress()
        let serverSocket = try L2CAPSocket.Server.lowEnergyServer(address: address)
        print("Listening on \(address) ...")
        while true {
            // wait for a connection
            while serverSocket.status.accept == false {
                if let error = serverSocket.status.error {
                    throw error
                }
                try await Task.sleep(nanoseconds: 100_000)
            }
            let connection = try serverSocket.accept()
            print("Connected")
            let server = GATTServer(
                socket: connection,
                maximumTransmissionUnit: .max,
                maximumPreparedWrites: 1000,
                database: Self.database,
                log: verbose ? { print("[GATT] \($0)") } : nil
            )
            do {
                while true {
                    try server.run()
                    try await Task.sleep(nanoseconds: 100_000)
                }
            } catch {
                print("Disconnected: \(error)")
            }
        }
    }

    private func startAdvertising(_ controller: HostController) async throws {
        do {
            try await controller.enableLowEnergyAdvertising(false)
        } catch HCIError.commandDisallowed {
            // already disabled
        }
        let advertisingData = GAPDataEncoder<LowEnergyAdvertisingData>.encode(
            GAPShortLocalName(name: name)
        )
        try await controller.setLowEnergyAdvertisingData(advertisingData)
        do {
            try await controller.enableLowEnergyAdvertising()
        } catch HCIError.commandDisallowed {
            // already enabled
        }
    }

    /// Demo GATT database (Device Information + Battery services).
    static var database: GATTDatabase<Data> {
        let deviceInformation = GATTAttribute<Data>.Service(
            uuid: .bit16(0x180A), // Device Information
            isPrimary: true,
            characteristics: [
                GATTAttribute<Data>.Characteristic(
                    uuid: GATTManufacturerNameString.uuid,
                    value: Data(GATTManufacturerNameString(rawValue: "PureSwift")),
                    permissions: [.read],
                    properties: [.read],
                    descriptors: []
                ),
                GATTAttribute<Data>.Characteristic(
                    uuid: GATTModelNumber.uuid,
                    value: Data(GATTModelNumber(rawValue: "BluetoothLinux")),
                    permissions: [.read],
                    properties: [.read],
                    descriptors: []
                ),
                GATTAttribute<Data>.Characteristic(
                    uuid: GATTSoftwareRevisionString.uuid,
                    value: Data(GATTSoftwareRevisionString(rawValue: "1.0.0")),
                    permissions: [.read],
                    properties: [.read],
                    descriptors: []
                )
            ]
        )
        let battery = GATTAttribute<Data>.Service(
            uuid: GATTBatteryService.uuid,
            isPrimary: true,
            characteristics: [
                GATTAttribute<Data>.Characteristic(
                    uuid: GATTBatteryLevel.uuid,
                    value: Data(GATTBatteryLevel(level: .init(rawValue: 100)!)),
                    permissions: [.read],
                    properties: [.read],
                    descriptors: []
                )
            ]
        )
        return GATTDatabase<Data>(services: [deviceInformation, battery])
    }
}

extension HostController.ID {

    /// Parse a controller identifier from a command line argument (e.g. `hci0` or `0`).
    static func parse(_ argument: String) throws -> HostController.ID {
        let string = argument.hasPrefix("hci") ? String(argument.dropFirst(3)) : argument
        guard let rawValue = UInt16(string) else {
            throw ValidationError("Invalid device identifier '\(argument)'")
        }
        return .init(rawValue: rawValue)
    }
}

extension HostController {

    /// Resolve the controller to use for a command.
    static func command(device id: HostController.ID?) async throws -> HostController {
        if let id {
            return try await HostController(id: id)
        }
        guard let controller = await HostController.controllers.first else {
            throw ValidationError("No Bluetooth controllers found.")
        }
        return controller
    }
}
