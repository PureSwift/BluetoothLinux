//
//  Read.swift
//  BluetoothLinux
//

import Foundation
import ArgumentParser
import Bluetooth
import BluetoothGATT
import BluetoothLinux

struct Read: AsyncParsableCommand {

    static let configuration = CommandConfiguration(
        commandName: "read",
        abstract: "Read a characteristic value."
    )

    @OptionGroup
    var options: ConnectionOptions

    @Option(name: [.customShort("a"), .long], help: "The value handle of the characteristic (e.g. 0x0021).", transform: parseHandle)
    var handle: UInt16?

    @Option(name: [.customShort("u"), .long], help: "The UUID of the characteristic (e.g. 2A00).", transform: parseUUID)
    var uuid: BluetoothUUID?

    func validate() throws {
        guard (handle != nil) != (uuid != nil) else {
            throw ValidationError("Specify either --handle or --uuid.")
        }
    }

    func run() async throws {
        let session = try await GATTToolSession.connect(options)
        defer { session.close() }
        if let handle {
            let (_, characteristic) = try await session.characteristic(handle: handle)
            let value = try await session.client.readCharacteristic(characteristic)
            print("Characteristic value/descriptor: \(value.hexadecimal)")
        } else if let uuid {
            let matches = try await session.characteristics(uuid: uuid)
            guard matches.isEmpty == false else {
                throw ValidationError("No characteristic with UUID \(uuid)")
            }
            for (_, characteristic) in matches {
                let value = try await session.client.readCharacteristic(characteristic)
                print("handle: \(characteristic.handle.value.hexadecimal) \t value: \(value.hexadecimal)")
            }
        }
    }
}
