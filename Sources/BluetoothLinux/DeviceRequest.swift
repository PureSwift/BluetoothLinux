//
//  DeviceRequest.swift
//  BluetoothLinux
//
//  Created by Alsey Coleman Miller on 1/3/16.
//  Copyright © 2016 PureSwift. All rights reserved.
//

#if os(Linux)
    import Glibc
#elseif os(OSX) || os(iOS)
    import Darwin.C
#endif

public extension Adapter {

    /// Sends a command to the device and waits for a response.
    func deviceRequest<T: HCICommandParameter>(command: T, timeout: Int = 1000) throws {
        
        
    }
    
    /*
    @inline(__always)
    func deviceCommand<T: HCICommand>(command: T) throws {
        
        try HCISendCommand(internalSocket, opcode: (command.rawValue, T.opcodeGroupField.rawValue))
    }
    
    @inline(__always)
    func deviceCommand<T: HCICommandParameter>(commandParameter: T) throws {
        
        let command = T.command
        
        let opcodeGroupField = command.dynamicType.opcodeGroupField
        
        let parameterData = commandParameter.byteValue
        
        try HCISendCommand(internalSocket, opcode: (command.rawValue, opcodeGroupField.rawValue), parameterData: parameterData)
    }*/
}

// MARK: - Internal HCI Functions

/// int hci_send_req(int dd, struct hci_request *r, int to)
internal func HCISendRequest(deviceDescriptor: CInt, opcode: (commandField: UInt16, groupField: UInt16), timeout: Int) throws {
    
    var eventBuffer = [UInt8](count: HCI.MaximumEventSize, repeatedValue: 0)
    
    let opcodePacked = HCICommandOpcodePack(opcode.commandField, opcode.groupField).littleEndian
    
    var newFilter = HCIFilter()
    
    var oldFilter = HCIFilter()
    
    let oldFilterPointer = withUnsafeMutablePointer(&oldFilter) { UnsafeMutablePointer<Void>($0) }
    
    var filterLength = socklen_t(sizeof(HCIFilter))
    
    guard getsockopt(deviceDescriptor, SOL_HCI, HCISocketOption.Filter.rawValue, oldFilterPointer, &filterLength) == 0
        else { throw POSIXError.fromErrorNumber! }
    
    var eventHeader = HCIEventHeader()
    
    
}

// MARK: - Internal Constants

let SOL_HCI: CInt = 0

// MARK: - Darwin Stubs

#if os(OSX) || os(iOS)

    /// Sends command and waits for response.
    func hci_send_req(dd: CInt, _ hcirequest: UnsafeMutablePointer<hci_request>, _ timeout: CInt) -> CInt { stub() }

    struct hci_request {

        var ogf: UInt16

        var ocf: UInt16

        /// The event code of the event to wait for.
        var event: CInt

        var cparam: UnsafeMutablePointer<Void>

        var clen: CInt

        var rparam: UnsafeMutablePointer<Void>

        var rlen: CInt

        init() { stub() }
    }

#endif
