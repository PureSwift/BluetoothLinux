//
//  Up.swift
//  BluetoothLinux
//

import Foundation
import ArgumentParser
import Bluetooth
import BluetoothLinux

struct Up: ParsableCommand {

    static let configuration = CommandConfiguration(
        commandName: "up",
        abstract: "Open and initialize a controller (requires root)."
    )

    @Argument(help: "The controller to enable (e.g. hci0).", transform: HostController.ID.parse)
    var device: HostController.ID

    func run() throws {
        try HostController.enable(device: device)
    }
}
