//
//  HCIConfig.swift
//  BluetoothLinux
//
//  Configure local Bluetooth controllers.
//

import Foundation
import ArgumentParser
import Bluetooth
import BluetoothLinux

@main
struct HCIConfig: AsyncParsableCommand {

    static let configuration = CommandConfiguration(
        commandName: "hciconfig",
        abstract: "Configure local Bluetooth controllers.",
        subcommands: [
            List.self,
            Up.self,
            Down.self
        ],
        defaultSubcommand: List.self
    )
}

extension HostController.ID {

    /// Parse a controller identifier from a command line argument (e.g. `hci0` or `0`).
    static func parse(_ argument: String) throws -> HostController.ID {
        let string = argument.hasPrefix("hci") ? String(argument.dropFirst(3)) : argument
        guard let rawValue = UInt16(string) else {
            throw ValidationError("Invalid device identifier '\(argument)'")
        }
        return .init(rawValue: rawValue)
    }
}
