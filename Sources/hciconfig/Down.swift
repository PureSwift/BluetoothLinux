//
//  Down.swift
//  BluetoothLinux
//

import Foundation
import ArgumentParser
import Bluetooth
import BluetoothLinux

struct Down: ParsableCommand {

    static let configuration = CommandConfiguration(
        commandName: "down",
        abstract: "Close a controller (requires root)."
    )

    @Argument(help: "The controller to disable (e.g. hci0).", transform: HostController.ID.parse)
    var device: HostController.ID

    func run() throws {
        try HostController.disable(device: device)
    }
}
