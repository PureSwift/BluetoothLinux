//
//  DevicePollEvent.swift
//  BluetoothLinux
//
//  Created by Alsey Coleman Miller on 3/27/18.
//

import Foundation
import Bluetooth

public extension HostController {
    
    /// Polls and waits for events.
    func pollEvent <T: HCIEventParameter> (_ eventParameterType: T.Type,
                                            shouldContinue: () -> (Bool),
                                            event: (T) throws -> ()) throws {
        
        assert(T.event is HCIGeneralEvent, "Can only parse \(HCIGeneralEvent.self)")
        
        let eventCode = T.event.rawValue
        
        try HCIPollEvent(internalSocket, shouldContinue: shouldContinue, event: eventCode) {
            
            guard let eventParameter = T.init(byteValue: $0)
                else { throw Error.garbageResponse(Data($0)) }
            
            try event(eventParameter)
        }
    }
}

/// Poll for scanned devices
internal func HCIPollEvent(_ deviceDescriptor: CInt,
                           shouldContinue: () -> (Bool),
                           event: UInt8,
                           eventDataCallback: ([UInt8]) throws -> ()) throws {
    
    var eventBuffer = [UInt8](repeating: 0, count: HCI.maximumEventSize)
    
    var oldFilterLength = socklen_t(MemoryLayout<HCIFilter>.size)
    var oldFilter = HCIFilter()
    
    // get old filter
    guard withUnsafeMutablePointer(to: &oldFilter, {
        let pointer = UnsafeMutableRawPointer($0)
        return getsockopt(deviceDescriptor, SOL_HCI, HCISocketOption.Filter.rawValue, pointer, &oldFilterLength) == 0
    }) else { throw POSIXError.fromErrno! }
    
    var newFilter = HCIFilter()
    newFilter.clear()
    newFilter.setPacketType(.Event)
    newFilter.setEvent(event)
    
    // set new filter
    var newFilterLength = socklen_t(MemoryLayout<HCIFilter>.size)
    guard withUnsafeMutablePointer(to: &newFilter, {
        let pointer = UnsafeMutableRawPointer($0)
        return setsockopt(deviceDescriptor, SOL_HCI, HCISocketOption.Filter.rawValue, pointer, newFilterLength) == 0
    }) else { throw POSIXError.fromErrno! }
    
    // restore old filter in case of error
    func restoreFilter(_ error: Error) -> Error {
        
        guard withUnsafeMutablePointer(to: &oldFilter, {
            let pointer = UnsafeMutableRawPointer($0)
            return setsockopt(deviceDescriptor, SOL_HCI, HCISocketOption.Filter.rawValue, pointer, newFilterLength) == 0
        }) else { return BluetoothHostControllerError.couldNotRestoreFilter(error, POSIXError.fromErrno!) }
        
        return error
    }
    
    // poll until timeout
    while shouldContinue() {
        
        var actualBytesRead = 0
        
        func doRead() { actualBytesRead = read(deviceDescriptor, &eventBuffer, eventBuffer.count) }
        
        doRead()
        
        // try for errors
        while actualBytesRead < 0 {
            
            // ignore these errors
            if (errno == EAGAIN || errno == EINTR) {
                
                // try again
                doRead()
                continue
                
            } else {
                
                // attempt to restore filter and throw
                throw restoreFilter(POSIXError.fromErrno!)
            }
        }
        
        let eventData = Array(eventBuffer[(1 + HCIEventHeader.length) ..< actualBytesRead])
        
        try eventDataCallback(eventData)
    }
}
