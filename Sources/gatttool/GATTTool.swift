//
//  GATTTool.swift
//  BluetoothLinux
//
//  GATT client for Bluetooth Low Energy peripherals.
//

import Foundation
import ArgumentParser
import Bluetooth
import BluetoothGATT
import BluetoothHCI
import BluetoothLinux

@main
struct GATTTool: AsyncParsableCommand {

    static let configuration = CommandConfiguration(
        commandName: "gatttool",
        abstract: "GATT client for Bluetooth Low Energy peripherals.",
        subcommands: [
            Primary.self,
            Characteristics.self,
            Read.self,
            Write.self,
            Notify.self
        ]
    )
}

/// Connection options shared by all subcommands.
struct ConnectionOptions: ParsableArguments {

    @Option(name: [.customShort("b"), .long], help: "The Bluetooth address of the remote device.", transform: { argument in
        guard let address = BluetoothAddress(rawValue: argument) else {
            throw ValidationError("Invalid Bluetooth address '\(argument)'")
        }
        return address
    })
    var destination: BluetoothAddress

    @Flag(name: [.customShort("r"), .long], help: "The remote device uses a random address.")
    var random = false

    @Option(name: [.customShort("i"), .long], help: "The controller to use (e.g. hci0).", transform: HostController.ID.parse)
    var device: HostController.ID?

    @Flag(name: .shortAndLong, help: "Log GATT client events.")
    var verbose = false
}

/// A connected GATT client with its IO pump task.
struct GATTToolSession {

    typealias Client = GATTClient<BluetoothLinux.L2CAPSocket.Connection>

    let client: Client

    let pump: Task<Void, Swift.Error>

    static func connect(_ options: ConnectionOptions) async throws -> GATTToolSession {
        let controller = try await HostController.command(device: options.device)
        let localAddress = try await controller.readDeviceAddress()
        let connection = try BluetoothLinux.L2CAPSocket.Connection.lowEnergyClient(
            address: localAddress,
            destination: options.destination,
            isRandom: options.random
        )
        if options.verbose {
            print("Connected to \(options.destination)")
        }
        var log: (@Sendable (String) -> ())? = nil
        if options.verbose {
            log = { print("[GATT] \($0)") }
        }
        let client = await GATTClient(
            socket: connection,
            log: log
        )
        let pump = Task {
            while Task.isCancelled == false {
                try await Task.sleep(nanoseconds: 100_000)
                try await client.run()
            }
        }
        return GATTToolSession(client: client, pump: pump)
    }

    func close() {
        pump.cancel()
    }

    /// Discover all primary services and their characteristics.
    func discoverAll() async throws -> [(service: Client.Service, characteristics: [Client.Characteristic])] {
        var result: [(service: Client.Service, characteristics: [Client.Characteristic])] = []
        let services = try await client.discoverAllPrimaryServices()
        for service in services {
            let characteristics = try await client.discoverAllCharacteristics(of: service)
            result.append((service, characteristics))
        }
        return result
    }

    /// Find a characteristic by its value handle.
    func characteristic(handle: UInt16) async throws -> (service: (declaration: Client.Service, characteristics: [Client.Characteristic]), characteristic: Client.Characteristic) {
        for (service, characteristics) in try await discoverAll() {
            if let characteristic = characteristics.first(where: { $0.handle.value == handle }) {
                return ((service, characteristics), characteristic)
            }
        }
        throw ValidationError("No characteristic with value handle \(handle.hexadecimal)")
    }

    /// Find characteristics by UUID.
    func characteristics(uuid: BluetoothUUID) async throws -> [(service: (declaration: Client.Service, characteristics: [Client.Characteristic]), characteristic: Client.Characteristic)] {
        var result: [(service: (declaration: Client.Service, characteristics: [Client.Characteristic]), characteristic: Client.Characteristic)] = []
        for (service, characteristics) in try await discoverAll() {
            for characteristic in characteristics where characteristic.uuid == uuid {
                result.append(((service, characteristics), characteristic))
            }
        }
        return result
    }
}

// MARK: - Argument Parsing

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

/// Parse an attribute handle from a command line argument (e.g. `0x0021` or `33`).
func parseHandle(_ argument: String) throws -> UInt16 {
    let handle: UInt16?
    if argument.hasPrefix("0x") || argument.hasPrefix("0X") {
        handle = UInt16(argument.dropFirst(2), radix: 16)
    } else {
        handle = UInt16(argument)
    }
    guard let handle else {
        throw ValidationError("Invalid handle '\(argument)'")
    }
    return handle
}

/// Parse a Bluetooth UUID from a command line argument (e.g. `180A` or a 128-bit UUID string).
func parseUUID(_ argument: String) throws -> BluetoothUUID {
    guard let uuid = BluetoothUUID(rawValue: argument) else {
        throw ValidationError("Invalid UUID '\(argument)'")
    }
    return uuid
}

/// Parse hexadecimal bytes from a command line argument (e.g. `0x0100` or `AABBCC`).
func parseHexData(_ argument: String) throws -> Data {
    var string = argument
    if string.hasPrefix("0x") || string.hasPrefix("0X") {
        string = String(string.dropFirst(2))
    }
    guard string.count % 2 == 0, string.isEmpty == false else {
        throw ValidationError("Invalid hexadecimal value '\(argument)'")
    }
    var data = Data(capacity: string.count / 2)
    var index = string.startIndex
    while index < string.endIndex {
        let next = string.index(index, offsetBy: 2)
        guard let byte = UInt8(string[index ..< next], radix: 16) else {
            throw ValidationError("Invalid hexadecimal value '\(argument)'")
        }
        data.append(byte)
        index = next
    }
    return data
}

extension UInt16 {

    var hexadecimal: String {
        String(format: "0x%04X", self)
    }
}

extension Data {

    var hexadecimal: String {
        map { String(format: "%02x", $0) }.joined(separator: " ")
    }
}
