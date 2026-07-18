//
//  IBeacon.swift
//  BluetoothLinux
//

import Foundation
import ArgumentParser
import Bluetooth
import BluetoothHCI
import BluetoothLinux

struct IBeacon: AsyncParsableCommand {

    static let configuration = CommandConfiguration(
        commandName: "ibeacon",
        abstract: "Advertise as an Apple iBeacon (requires root)."
    )

    @Option(name: [.customShort("i"), .long], help: "The controller to use (e.g. hci0).", transform: HostController.ID.parse)
    var device: HostController.ID?

    @Argument(help: "The proximity UUID of the beacon.", transform: { argument in
        guard let uuid = UUID(uuidString: argument) else {
            throw ValidationError("Invalid UUID '\(argument)'")
        }
        return uuid
    })
    var uuid: UUID

    @Option(help: "The value identifying a group of beacons.")
    var major: UInt16 = 0

    @Option(help: "The value identifying a specific beacon within a group.")
    var minor: UInt16 = 0

    @Option(help: "The measured signal strength (in dBm) at 1 meter.")
    var rssi: Int8 = -59

    func run() async throws {
        let controller = try await HostController.command(device: device)
        let beacon = AppleBeacon(
            uuid: uuid,
            major: major,
            minor: minor,
            rssi: rssi
        )
        try await controller.iBeacon(beacon)
        print("Advertising iBeacon \(uuid) (major: \(major), minor: \(minor)) on \(controller.name)")
    }
}
