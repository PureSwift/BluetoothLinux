//
//  DevicePollEvent.swift
//  BluetoothLinux
//
//  Created by Alsey Coleman Miller on 3/27/18.
//

import Foundation
import BluetoothHCI

public extension HostController {
    
    /// Polls and waits for events.
    func pollEvent <T: HCIEventParameter> (_ eventParameterType: T.Type,
                                            shouldContinue: () -> (Bool),
                                            event: (T) throws -> ()) throws {
        
        assert(T.event is HCIGeneralEvent, "Can only parse \(HCIGeneralEvent.self)")
        
        let eventCode = T.event.rawValue
        
        try HCIPollEvent(internalSocket.fileDescriptor, shouldContinue: shouldContinue, event: eventCode) {
            
            guard let eventParameter = T.init(data: $0)
                else { throw Error.garbageResponse(Data($0)) }
            
            try event(eventParameter)
        }
    }
}

/// Poll for scanned devices
internal func HCIPollEvent(_ deviceDescriptor: CInt,
                           shouldContinue: () -> (Bool),
                           event: UInt8,
                           eventDataCallback: (Data) throws -> ()) throws {
    
    var eventBuffer = [UInt8](repeating: 0, count: HCI.maximumEventSize)
    
    var oldFilterLength = socklen_t(MemoryLayout<HCIFilter>.size)
    var oldFilter = HCIFilter()
    
    // get old filter
    guard withUnsafeMutablePointer(to: &oldFilter, {
        let pointer = UnsafeMutableRawPointer($0)
        return getsockopt(deviceDescriptor, SOL_HCI, HCISocketOption.filter.rawValue, pointer, &oldFilterLength) == 0
    }) else { throw POSIXError.fromErrno() }
    
    var newFilter = HCIFilter()
    newFilter.clear()
    newFilter.setPacketType(.event)
    newFilter.setEvent(event)
    
    // set new filter
    let newFilterLength = socklen_t(MemoryLayout<HCIFilter>.size)
    guard withUnsafeMutablePointer(to: &newFilter, {
        let pointer = UnsafeMutableRawPointer($0)
        return setsockopt(deviceDescriptor, SOL_HCI, HCISocketOption.filter.rawValue, pointer, newFilterLength) == 0
    }) else { throw POSIXError.fromErrno() }
    
    // restore old filter in case of error
    func restoreFilter(_ error: Error) -> Error {
        
        guard withUnsafeMutablePointer(to: &oldFilter, {
            let pointer = UnsafeMutableRawPointer($0)
            return setsockopt(deviceDescriptor, SOL_HCI, HCISocketOption.filter.rawValue, pointer, newFilterLength) == 0
        }) else { return BluetoothHostControllerError.couldNotRestoreFilter(error, POSIXError.fromErrno()) }
        
        return error
    }
    
    let queue = DispatchQueue(label: "Host Controller Event Polling Queue")
    
    // poll until timeout
    while shouldContinue() {
        
        var bytesRead = 0
        var didRead = false
        
        queue.async {
            bytesRead = read(deviceDescriptor, &eventBuffer, eventBuffer.count)
            didRead = true
        }
        
        while didRead == false {
            
            guard shouldContinue()
                else { return }
            
            usleep(1000)
        }
        
        // try for errors
        while bytesRead < 0 {
            
            // ignore these errors
            if (errno == EAGAIN || errno == EINTR) {
                
                // try again
                continue
                
            } else {
                
                // attempt to restore filter and throw
                throw restoreFilter(POSIXError.fromErrno())
            }
        }
        
        guard bytesRead > 0
            else { continue }
        
        let eventData = Data(eventBuffer[(1 + HCIEventHeader.length) ..< bytesRead])
        
        try eventDataCallback(eventData)
    }
}
