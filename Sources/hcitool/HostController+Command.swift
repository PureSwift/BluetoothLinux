//
//  HostController+Command.swift
//  BluetoothLinux
//

import Foundation
import ArgumentParser
import Bluetooth
import BluetoothLinux

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

extension HostController {

    /// Resolve the controller to use for a command.
    static func command(device id: HostController.ID?) async throws -> HostController {
        if let id {
            return try await HostController(id: id)
        }
        guard let controller = await HostController.controllers.first else {
            throw ValidationError("No Bluetooth controllers found.")
        }
        return controller
    }
}
