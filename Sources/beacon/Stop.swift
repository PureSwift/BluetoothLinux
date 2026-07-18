//
//  Stop.swift
//  BluetoothLinux
//

import Foundation
import ArgumentParser
import Bluetooth
import BluetoothHCI
import BluetoothLinux

struct Stop: AsyncParsableCommand {

    static let configuration = CommandConfiguration(
        commandName: "stop",
        abstract: "Stop advertising (requires root)."
    )

    @Option(name: [.customShort("i"), .long], help: "The controller to use (e.g. hci0).", transform: HostController.ID.parse)
    var device: HostController.ID?

    func run() async throws {
        let controller = try await HostController.command(device: device)
        do {
            try await controller.enableLowEnergyAdvertising(false)
        } catch HCIError.commandDisallowed {
            // already disabled
        }
        print("Stopped advertising on \(controller.name)")
    }
}
