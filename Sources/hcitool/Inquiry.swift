//
//  Inquiry.swift
//  BluetoothLinux
//

import Foundation
import ArgumentParser
import Bluetooth
import BluetoothLinux

struct Inquiry: AsyncParsableCommand {

    static let configuration = CommandConfiguration(
        commandName: "inq",
        abstract: "Inquire remote devices (classic Bluetooth inquiry)."
    )

    @Option(name: [.customShort("i"), .long], help: "The controller to use (e.g. hci0).", transform: HostController.ID.parse)
    var device: HostController.ID?

    @Option(help: "Inquiry duration (at most 1.28 * duration seconds).")
    var duration: Int = 8

    @Option(help: "Maximum amount of devices to scan.")
    var limit: Int = 255

    func run() async throws {
        let controller = try await HostController.command(device: device)
        print("Inquiring ...")
        let results = try controller.scan(duration: duration, limit: limit)
        for result in results {
            let deviceClass = String(
                format: "0x%02X%02X%02X",
                result.deviceClass.2,
                result.deviceClass.1,
                result.deviceClass.0
            )
            let clockOffset = String(format: "0x%04X", result.clockOffset)
            print("\t\(result.address)\tclass: \(deviceClass)\tclock offset: \(clockOffset)")
        }
    }
}
