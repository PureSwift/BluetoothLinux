//
//  GATTServer.swift
//  BluetoothLinux
//
//  Created by Alsey Coleman Miller on 2/29/16.
//  Copyright © 2016 PureSwift. All rights reserved.
//

import struct SwiftFoundation.UUID

public final class GATTServer {
    
    // MARK: - Properties
    
    public var log: (String -> ())?
    
    public var database = GATTDatabase()
    
    // MARK: - Private Properties
    
    private let connection: ATTConnection
    
    // MARK: - Initialization
    
    public init(socket: L2CAPSocket, maximumTransmissionUnit: Int = ATT.MTU.LowEnergy.Default) {
        
        // set initial MTU and register handlers
        self.connection = ATTConnection(socket: socket)
        self.connection.maximumTransmissionUnit = maximumTransmissionUnit
        self.registerATTHandlers()
    }
    
    // MARK: - Methods
    
    /// Performs the actual IO for sending data.
    @inline(__always)
    public func read() throws {
        
        try connection.read()
    }
    
    /// Performs the actual IO for recieving data.
    @inline(__always)
    public func write() throws -> Bool {
        
        return try connection.write()
    }
    
    // MARK: - Private Methods
    
    @inline(__always)
    private func registerATTHandlers() {
        
        // Exchange MTU
        connection.register(exchangeMTU)
        
        // Read By Group Type
        connection.register(readByGroupType)
        
        // Read By Type
        connection.register(readByType)
        
        // Find Information
        connection.register(findInformation)
        
        // Find By Type Value
        connection.register(findByTypeValue)
        
        // Write Request
        connection.register(writeRequest)
        
        // Write Command
        connection.register(writeCommand)
        
        // Read Request
        connection.register(readRequest)
        
        // Read Blob Request
        connection.register(readBlobRequest)
        
        // Read Multiple Request
        
        
        // Prepare Write Request
        
        // Execute Write Request
    }
    
    @inline(__always)
    private func errorResponse(opcode: ATT.Opcode, _ error: ATT.Error, _ handle: UInt16 = 0) {
        
        log?("Error \(error) - \(opcode) (\(handle))")
        
        connection.sendError(opcode, error: error, handle: handle)
    }
    
    @noreturn @inline(__always)
    private func fatalErrorResponse(message: String, _ opcode: ATT.Opcode, _ handle: UInt16 = 0, line: UInt = #line) {
        
        errorResponse(opcode, ATT.Error.UnlikelyError, handle)
        
        do { try connection.write() }
        
        catch { print("Could not send UnlikelyError to client. (\(error))") }
        
        fatalError(message, line: line)
    }
    
    @inline(__always)
    private func respond<T: ATTProtocolDataUnit>(response: T) {
        
        log?("Response: \(response)")
        
        connection.send(response) { _ in }
    }
    
    private func checkPermissions(permissions: [ATT.AttributePermission], _ attribute: GATTDatabase.Attribute) -> ATT.Error? {
        
        guard attribute.permissions != permissions else { return nil }
        
        // check permissions
        
        if permissions.contains(.Read) && !attribute.permissions.contains(.Read) {
            
            return .ReadNotPermitted
        }
        
        if permissions.contains(.Write) && !attribute.permissions.contains(.Write) {
            
            return .WriteNotPermitted
        }
        
        // check security
        
        let security = connection.socket.securityLevel
        
        if attribute.permissions.contains(.ReadAuthentication)
            || attribute.permissions.contains(.WriteAuthentication)
            && security < .High {
            
            return .Authentication
        }
        
        if attribute.permissions.contains(.ReadEncrypt)
            || attribute.permissions.contains(.WriteEncrypt)
            && security < .Medium {
            
            return .InsufficientEncryption
        }
        
        return nil
    }
    
    private func handleWriteRequest(opcode: ATT.Opcode, handle: UInt16, value: [UInt8], shouldRespond: Bool) {
        
        /// Conditionally respond
        @inline(__always)
        func doResponse(@autoclosure block: () -> ()) {
            
            if shouldRespond { block() }
        }
        
        log?("Write \(shouldRespond ? "Request" : "Command") (\(handle)) \(value)")
        
        // no attributes, impossible to write
        guard database.attributes.isEmpty == false
            else { doResponse(errorResponse(opcode, .InvalidHandle, handle)); return }
        
        // validate handle
        guard (1 ... UInt16(database.attributes.count)).contains(handle)
            else { doResponse(errorResponse(opcode, .InvalidHandle, handle)); return }
        
        // get attribute
        let attribute = database[handle]
        
        // validate permissions
        if let error = checkPermissions([.Write, .WriteAuthentication, .WriteEncrypt], attribute) {
            
            doResponse(errorResponse(opcode, error, handle))
            return
        }
        
        database.write(value, handle)
        
        doResponse(respond(ATTWriteResponse()))
    }
    
    private func handleReadRequest(opcode: ATT.Opcode, handle: UInt16, offset: UInt16 = 0) -> [UInt8]? {
        
        // no attributes
        guard database.attributes.isEmpty == false
            else { errorResponse(opcode, .InvalidHandle, handle); return nil }
        
        // validate handle
        guard (1 ... UInt16(database.attributes.count)).contains(handle)
            else { errorResponse(opcode, .InvalidHandle, handle); return nil }
        
        // get attribute
        let attribute = database[handle]
        
        // validate permissions
        if let error = checkPermissions([.Read, .ReadAuthentication, .ReadEncrypt], attribute) {
            
            errorResponse(opcode, error, handle)
            return nil
        }
        
        // check boundary
        guard offset <= UInt16(attribute.value.count)
            else { errorResponse(opcode, .InvalidOffset, handle); return nil }
        
        let value: [UInt8]
        
        // Guard against invalid access if offset equals to value length
        if offset == UInt16(attribute.value.count) {
            
            value = []
            
        } else if offset > 0 {
            
            value = Array(attribute.value.suffixFrom(Int(offset)))
            
        } else {
            
            value = attribute.value
        }
        
        return value
    }
    
    // MARK: Callbacks
    
    private func exchangeMTU(pdu: ATTMaximumTransmissionUnitRequest) {
        
        let serverMTU = UInt16(connection.maximumTransmissionUnit)
        
        let finalMTU = max(min(pdu.clientMTU, serverMTU), UInt16(ATT.MTU.LowEnergy.Default))
        
        // Respond with the server MTU
        connection.send(ATTMaximumTranssmissionUnitResponse(serverMTU: serverMTU)) { _ in }
        
        // Set MTU to minimum
        connection.maximumTransmissionUnit = Int(finalMTU)
        
        log?("MTU Exchange (\(pdu.clientMTU) -> \(finalMTU))")
    }
    
    private func readByGroupType(pdu: ATTReadByGroupTypeRequest) {
        
        typealias AttributeData = ATTReadByGroupTypeResponse.AttributeData
        
        let opcode = pdu.dynamicType.attributeOpcode
        
        log?("Read by Group Type (\(pdu.startHandle) - \(pdu.endHandle))")
        
        // validate handles
        guard pdu.startHandle != 0 && pdu.endHandle != 0
            else { errorResponse(opcode, .InvalidHandle); return }
        
        guard pdu.startHandle <= pdu.endHandle
            else { errorResponse(opcode, .InvalidHandle, pdu.startHandle); return }
        
        // GATT defines that only the Primary Service and Secondary Service group types 
        // can be used for the "Read By Group Type" request. Return an error if any other group type is given.
        guard pdu.type == GATT.UUID.PrimaryService.toUUID() || pdu.type == GATT.UUID.SecondaryService.toUUID()
            else { errorResponse(opcode, .UnsupportedGroupType, pdu.startHandle); return }
        
        // search for only primary services
        let primary = pdu.type == GATT.UUID.PrimaryService.toUUID()
        
        let data = database.readByGroupType(pdu.startHandle ..< pdu.endHandle, primary: primary)
        
        guard data.isEmpty == false
            else { errorResponse(opcode, .AttributeNotFound, pdu.startHandle); return }
        
        let attributeData = data.map { AttributeData(attributeHandle: $0.start, endGroupHandle: $0.end, value: $0.UUID.byteValue) }
                
        guard let response = ATTReadByGroupTypeResponse(data: attributeData)
            else { fatalErrorResponse("Could not create ATTReadByGroupTypeResponse. Attribute Data: \(attributeData)", opcode, pdu.startHandle) }
        
        respond(response)
    }
    
    private func readByType(pdu: ATTReadByTypeRequest) {
        
        typealias AttributeData = ATTReadByTypeResponse.AttributeData
        
        let opcode = pdu.dynamicType.attributeOpcode
        
        if let log = self.log {
            
            let typeText: String
            
            if let gatt = GATT.UUID(UUID: pdu.attributeType) {
                
                typeText = "\(gatt)"
                
            } else {
                
                typeText = "\(pdu.attributeType)"
            }
            
            log("Read by Type (\(typeText)) (\(pdu.startHandle) - \(pdu.endHandle))")
        }
        
        guard pdu.startHandle != 0 && pdu.endHandle != 0
            else { errorResponse(opcode, .InvalidHandle); return }
        
        guard pdu.startHandle <= pdu.endHandle
            else { errorResponse(opcode, .InvalidHandle, pdu.startHandle); return }
        
        let attributes = database.readByType(pdu.startHandle ... pdu.endHandle, type: pdu.attributeType)
        
        guard attributes.isEmpty == false
            else { errorResponse(opcode, .AttributeNotFound, pdu.startHandle); return }
        
        let attributeData = attributes.map { AttributeData(handle: $0.handle, value: $0.value) }
        
        guard let response = ATTReadByTypeResponse(data: attributeData)
            else { fatalErrorResponse("Could not create ATTReadByTypeResponse. Attribute Data: \(attributeData)", opcode, pdu.startHandle) }
        
        respond(response)
    }
    
    private func findInformation(pdu: ATTFindInformationRequest) {
        
        typealias Data = ATTFindInformationResponse.Data
        
        typealias Format = ATTFindInformationResponse.Format
        
        let opcode = pdu.dynamicType.attributeOpcode
        
        log?("Find Information (\(pdu.startHandle) - \(pdu.endHandle))")
        
        guard pdu.startHandle != 0 && pdu.endHandle != 0
            else { errorResponse(opcode, .InvalidHandle); return }
        
        guard pdu.startHandle <= pdu.endHandle
            else { errorResponse(opcode, .InvalidHandle, pdu.startHandle); return }
        
        let attributes = database.findInformation(pdu.startHandle ... pdu.endHandle)
        
        guard attributes.isEmpty == false
            else { errorResponse(opcode, .AttributeNotFound, pdu.startHandle); return }
        
        let format = Format(UUID: attributes[0].UUID)
        
        var bit16Pairs = [(UInt16, UInt16)]()
        
        var bit128Pairs = [(UInt16, UUID)]()
        
        for (index, attribute) in attributes.enumerate() {
            
            // truncate if bigger than MTU
            let encodedLength = 2 + ((index + 1) * format.length)
            
            guard encodedLength <= connection.maximumTransmissionUnit
                else { break }
            
            // encode attribute
            switch (attribute.UUID, format) {
                
            case let (.Bit16(type), .Bit16):
                
                bit16Pairs.append((attribute.handle, type))
                
            case let (.Bit128(type), .Bit128):
                
                bit128Pairs.append((attribute.handle, type))
                
            default: break // mismatching types
            }
        }
        
        let data: Data
        
        switch format {
        case .Bit16: data = .Bit16(bit16Pairs)
        case .Bit128: data = .Bit128(bit128Pairs)
        }
        
        let response = ATTFindInformationResponse(data: data)
        
        respond(response)
    }
    
    private func findByTypeValue(pdu: ATTFindByTypeRequest) {
        
        typealias Handle = ATTFindByTypeResponse.HandlesInformation
        
        let opcode = pdu.dynamicType.attributeOpcode
        
        log?("Find By Type Value (\(pdu.startHandle) - \(pdu.endHandle)) (\(pdu.attributeType))")
        
        guard pdu.startHandle != 0 && pdu.endHandle != 0
            else { errorResponse(opcode, .InvalidHandle); return }
        
        guard pdu.startHandle <= pdu.endHandle
            else { errorResponse(opcode, .InvalidHandle, pdu.startHandle); return }
        
        let handles = database.findByTypeValue(pdu.startHandle ... pdu.endHandle, type: pdu.attributeType, value: pdu.attributeValue)
        
        guard handles.isEmpty == false
            else { errorResponse(opcode, .AttributeNotFound, pdu.startHandle); return }
        
        let handlesInformation = handles.map { Handle(foundAttribute: $0.0, groupEnd: $0.1) }
        
        let response = ATTFindByTypeResponse(handlesInformationList: handlesInformation)
        
        respond(response)
    }
    
    private func writeRequest(pdu: ATTWriteRequest) {
        
        let opcode = pdu.dynamicType.attributeOpcode
        
        handleWriteRequest(opcode, handle: pdu.handle, value: pdu.value, shouldRespond: true)
    }
    
    private func writeCommand(pdu: ATTWriteCommand) {
        
        let opcode = pdu.dynamicType.attributeOpcode
        
        handleWriteRequest(opcode, handle: pdu.handle, value: pdu.value, shouldRespond: false)
    }
    
    private func readRequest(pdu: ATTReadRequest) {
        
        let opcode = pdu.dynamicType.attributeOpcode
        
        log?("Read (\(pdu.handle))")
        
        if let value = handleReadRequest(opcode, handle: pdu.handle) {
            
            respond(ATTReadResponse(attributeValue: value))
        }
    }
    
    private func readBlobRequest(pdu: ATTReadBlobRequest) {
        
        let opcode = pdu.dynamicType.attributeOpcode
        
        log?("Read Blob (\(pdu.handle))")
        
        if let value = handleReadRequest(opcode, handle: pdu.handle, offset: pdu.offset) {
            
            respond(ATTReadBlobResponse(partAttributeValue: value))
        }
    }
    
    private func readMultipleRequest(pdu: ATTReadMultipleRequest) {
        
        let opcode = pdu.dynamicType.attributeOpcode
        
        log?("Read Multiple Request \(pdu.handles)")
        
        // no attributes, impossible to write
        guard database.attributes.isEmpty == false
            else { errorResponse(opcode, .InvalidHandle, pdu.handles[0]); return }
        
        var values = [UInt8]()
        
        for handle in pdu.handles {
            
            // validate handle
            guard (1 ... UInt16(database.attributes.count)).contains(handle)
                else { errorResponse(opcode, .InvalidHandle, handle); return }
            
            // get attribute
            let attribute = database[handle]
            
            values += attribute.value
        }
        
        let response = ATTReadMultipleResponse(values: values)
        
        respond(response)
    }
}

// MARK: - GATTDatabase Extensions

internal extension GATTDatabase {
    
    /// Used for Service discovery. Should return tuples with the Service start handle, end handle and UUID.
    func readByGroupType(handle: Range<UInt16>, primary: Bool) -> [(start: UInt16, end: UInt16, UUID: BluetoothUUID)] {
        
        var data = [(start: UInt16, end: UInt16, UUID: BluetoothUUID)]()
        
        for (index, service) in self.services.enumerate() {
            
            guard service.primary == primary else { continue }
            
            let serviceHandle = self.serviceHandle(index)
            
            let endGroupHandle = self.serviceEndHandle(index)
            
            let serviceRange = serviceHandle ... endGroupHandle
            
            guard serviceRange.isSubset(handle) else { continue }
            
            data.append((serviceHandle, endGroupHandle, service.UUID))
        }
        
        return data
    }
    
    func readByType(handle: Range<UInt16>, type: BluetoothUUID) -> [Attribute] {
        
        return attributes.filter { handle.contains($0.handle) && $0.UUID == type }
    }
    
    func findInformation(handle: Range<UInt16>) -> [Attribute] {
        
        return attributes.filter { handle.contains($0.handle) }
    }
    
    func findByTypeValue(handle: Range<UInt16>, type: UInt16, value: [UInt8]) -> [(UInt16, UInt16)] {
        
        fatalError("Not Implemented")
        
        /*
        let matchingAttributes = attributes.filter { handle.contains($0.handle) && $0.UUID == .Bit16(type) && $0.value == value }
        
        let services = matchingAttributes.map { serviceOf($0.handle) }
        
        var handles = [(UInt16, UInt16)](count: services.count, repeatedValue: (0,0))
        
        for (index, service) in services.enumerate() {
            
            let serviceHandle = self.serviceHandle(index)
            
            handles[index].0 = serviceHandle
            handles[index].1 = serviceHandle + UInt16(service.characteristics.count)
        }
        
        return handles*/
    }
}

