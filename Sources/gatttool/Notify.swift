//
//  Notify.swift
//  BluetoothLinux
//

import Foundation
import ArgumentParser
import Bluetooth
import BluetoothGATT
import BluetoothLinux

struct Notify: AsyncParsableCommand {

    static let configuration = CommandConfiguration(
        commandName: "notify",
        abstract: "Subscribe to characteristic notifications and listen until interrupted."
    )

    @OptionGroup
    var options: ConnectionOptions

    @Option(name: [.customShort("a"), .long], help: "The value handle of the characteristic (e.g. 0x0021).", transform: parseHandle)
    var handle: UInt16

    func run() async throws {
        let session = try await GATTToolSession.connect(options)
        defer { session.close() }
        let (service, characteristic) = try await session.characteristic(handle: handle)
        let descriptors = try await session.client.discoverDescriptors(
            of: characteristic,
            service: service
        )
        let valueHandle = characteristic.handle.value
        var notification: GATTToolSession.Client.Notification? = nil
        if characteristic.properties.contains(.notify) {
            notification = { data in
                print("Notification handle = \(valueHandle.hexadecimal) value: \(data.hexadecimal)")
            }
        }
        var indication: GATTToolSession.Client.Notification? = nil
        if characteristic.properties.contains(.indicate) {
            indication = { data in
                print("Indication handle = \(valueHandle.hexadecimal) value: \(data.hexadecimal)")
            }
        }
        guard notification != nil || indication != nil else {
            throw ValidationError("Characteristic \(characteristic.uuid) does not support notifications or indications.")
        }
        try await session.client.clientCharacteristicConfiguration(
            characteristic,
            notification: notification,
            indication: indication,
            descriptors: descriptors
        )
        print("Listening for notifications (Ctrl-C to exit) ...")
        // keep the connection alive until interrupted
        try await session.pump.value
    }
}
