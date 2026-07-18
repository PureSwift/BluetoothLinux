//
//  List.swift
//  BluetoothLinux
//

import Foundation
import ArgumentParser
import Bluetooth
import BluetoothLinux

struct List: AsyncParsableCommand {

    static let configuration = CommandConfiguration(
        commandName: "list",
        abstract: "Print information for all local controllers."
    )

    @Argument(help: "The controller to print information for (e.g. hci0).", transform: HostController.ID.parse)
    var device: HostController.ID?

    func run() async throws {
        let identifiers: [HostController.ID]
        if let device {
            identifiers = [device]
        } else {
            identifiers = await HostController.controllers.map { $0.id }
            guard identifiers.isEmpty == false else {
                throw CleanExit.message("No Bluetooth controllers found.")
            }
        }
        for (index, id) in identifiers.enumerated() {
            let info = try HostController.deviceInformation(for: id)
            if index > 0 {
                print()
            }
            print("\(info.name):\tType: \(info.type)  Bus: \(info.busType)")
            print("\tBD Address: \(info.address)")
            print("\t\(description(for: info.flags.flags))")
        }
    }

    private func description(for flags: HCIDeviceFlag) -> String {
        let names: [(HCIDeviceFlag, String)] = [
            (.up, "UP"),
            (.initialized, "INIT"),
            (.running, "RUNNING"),
            (.passiveScan, "PSCAN"),
            (.interactiveScan, "ISCAN"),
            (.authenticated, "AUTH"),
            (.encrypt, "ENCRYPT"),
            (.inquiry, "INQUIRY"),
            (.raw, "RAW")
        ]
        var components = names.compactMap { flags.contains($0.0) ? $0.1 : nil }
        if flags.contains(.up) == false {
            components.insert("DOWN", at: 0)
        }
        return components.joined(separator: " ")
    }
}
