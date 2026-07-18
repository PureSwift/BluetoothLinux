//
//  HCITool.swift
//  BluetoothLinux
//
//  Configure Bluetooth connections and query controller state.
//

import Foundation
import ArgumentParser
import Bluetooth
import BluetoothHCI
import BluetoothLinux

@main
struct HCITool: AsyncParsableCommand {

    static let configuration = CommandConfiguration(
        commandName: "hcitool",
        abstract: "Configure Bluetooth connections and query controller state.",
        subcommands: [
            DeviceList.self,
            Inquiry.self,
            LowEnergyScan.self
        ],
        defaultSubcommand: DeviceList.self
    )
}
