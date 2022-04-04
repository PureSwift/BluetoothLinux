//
//  DevicePollEvent.swift
//  BluetoothLinux
//
//  Created by Alsey Coleman Miller on 3/27/18.
//

import Foundation
import Bluetooth
import BluetoothHCI
import SystemPackage

public extension HostController {
    
    func recieve<Event>(_ eventType: Event.Type) async throws -> Event where Event: HCIEventParameter, Event.HCIEventType == HCIGeneralEvent {
        var newFilter = HCISocketOption.Filter()
        newFilter.setPacketType(.event)
        newFilter.setEvent(Event.event)
        return try await socket.fileDescriptor.setFilter(newFilter) {
            let readData = try await socket.read(HCIEventHeader.maximumSize)
            let eventData = Data(readData[(1 + HCIEventHeader.length) ..< readData.count]) // create unsafe data pointer
            guard let eventParameter = Event.init(data: eventData)
                else { throw BluetoothHostControllerError.garbageResponse(eventData) }
            return eventParameter
        }
    }
}
