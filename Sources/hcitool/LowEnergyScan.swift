//
//  LowEnergyScan.swift
//  BluetoothLinux
//

import Foundation
import ArgumentParser
import Bluetooth
import BluetoothGAP
import BluetoothHCI
import BluetoothLinux

struct LowEnergyScan: AsyncParsableCommand {

    static let configuration = CommandConfiguration(
        commandName: "lescan",
        abstract: "Scan for Bluetooth Low Energy devices."
    )

    @Option(name: [.customShort("i"), .long], help: "The controller to use (e.g. hci0).", transform: HostController.ID.parse)
    var device: HostController.ID?

    @Option(help: "Scan duration in seconds (scans until interrupted by default).")
    var duration: UInt?

    @Flag(help: "Show duplicate advertising reports.")
    var duplicates = false

    func run() async throws {
        let controller = try await HostController.command(device: device)
        print("LE Scan ...")
        let stream = try await controller.lowEnergyScan(filterDuplicates: !duplicates)
        let scanTask = Task {
            for try await report in stream {
                var line = "\(report.address) \(report.addressType == .random ? "(random)" : "(public)")"
                if let name = report.responseData.localName {
                    line += " \(name)"
                }
                if let rssi = report.rssi {
                    line += " rssi: \(rssi.rawValue)"
                }
                print(line)
            }
        }
        if let duration {
            try await Task.sleep(nanoseconds: UInt64(duration) * 1_000_000_000)
            stream.stop()
            scanTask.cancel()
        } else {
            try await scanTask.value
        }
    }
}

internal extension LowEnergyAdvertisingData {

    /// Decode the local name from GAP advertising data.
    var localName: String? {
        let decoder = GAPDataDecoder<LowEnergyAdvertisingData>()
        guard let decoded = try? decoder.decode(from: self) else {
            return nil
        }
        if let name = decoded.compactMap({ $0 as? GAPCompleteLocalName }).first {
            return name.name
        }
        if let name = decoded.compactMap({ $0 as? GAPShortLocalName }).first {
            return name.name
        }
        return nil
    }
}
