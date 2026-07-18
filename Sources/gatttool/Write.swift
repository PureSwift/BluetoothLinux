//
//  Write.swift
//  BluetoothLinux
//

import Foundation
import ArgumentParser
import Bluetooth
import BluetoothGATT
import BluetoothLinux

struct Write: AsyncParsableCommand {

    static let configuration = CommandConfiguration(
        commandName: "write",
        abstract: "Write a characteristic value."
    )

    @OptionGroup
    var options: ConnectionOptions

    @Option(name: [.customShort("a"), .long], help: "The value handle of the characteristic (e.g. 0x0021).", transform: parseHandle)
    var handle: UInt16

    @Argument(help: "The value to write, in hexadecimal (e.g. 0x0100).", transform: parseHexData)
    var value: Data

    @Flag(help: "Write without response (ATT Write Command).")
    var noResponse = false

    func run() async throws {
        let session = try await GATTToolSession.connect(options)
        defer { session.close() }
        let (_, characteristic) = try await session.characteristic(handle: handle)
        try await session.client.writeCharacteristic(
            characteristic,
            data: value,
            withResponse: !noResponse
        )
        print("Characteristic value was written successfully")
    }
}
