//
//  DeviceList.swift
//  BluetoothLinux
//

import Foundation
import ArgumentParser
import Bluetooth
import BluetoothLinux

struct DeviceList: AsyncParsableCommand {

    static let configuration = CommandConfiguration(
        commandName: "dev",
        abstract: "List local Bluetooth controllers."
    )

    func run() async throws {
        let controllers = await HostController.controllers
        guard controllers.isEmpty == false else {
            throw CleanExit.message("No Bluetooth controllers found.")
        }
        print("Devices:")
        for controller in controllers {
            print("\t\(controller.name)\t\(controller.address)")
        }
    }
}
