//
//  Characteristics.swift
//  BluetoothLinux
//

import Foundation
import ArgumentParser
import Bluetooth
import BluetoothGATT
import BluetoothLinux

struct Characteristics: AsyncParsableCommand {

    static let configuration = CommandConfiguration(
        commandName: "characteristics",
        abstract: "Discover all characteristics."
    )

    @OptionGroup
    var options: ConnectionOptions

    func run() async throws {
        let session = try await GATTToolSession.connect(options)
        defer { session.close() }
        for (service, characteristics) in try await session.discoverAll() {
            print("service: \(service.uuid) (\(service.handle.hexadecimal) - \(service.end.hexadecimal))")
            for characteristic in characteristics {
                print("\thandle \(characteristic.handle.declaration.hexadecimal), char properties \(String(format: "0x%02X", characteristic.properties.rawValue)), char value handle \(characteristic.handle.value.hexadecimal), uuid \(characteristic.uuid)")
            }
        }
    }
}
