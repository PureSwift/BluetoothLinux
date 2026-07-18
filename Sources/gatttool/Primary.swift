//
//  Primary.swift
//  BluetoothLinux
//

import Foundation
import ArgumentParser
import Bluetooth
import BluetoothGATT
import BluetoothLinux

struct Primary: AsyncParsableCommand {

    static let configuration = CommandConfiguration(
        commandName: "primary",
        abstract: "Discover all primary services."
    )

    @OptionGroup
    var options: ConnectionOptions

    func run() async throws {
        let session = try await GATTToolSession.connect(options)
        defer { session.close() }
        let services = try await session.client.discoverAllPrimaryServices()
        for service in services {
            print("attr handle \(service.handle.hexadecimal), end grp handle \(service.end.hexadecimal) uuid: \(service.uuid)")
        }
    }
}
