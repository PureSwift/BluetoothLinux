//
//  GATTServer.swift
//  BluetoothLinux
//
//  Created by Alsey Coleman Miller on 2/29/16.
//  Copyright © 2016 PureSwift. All rights reserved.
//

import struct SwiftFoundation.UUID
import struct SwiftFoundation.Data
import Bluetooth

public final class GATTServer {
    
    // MARK: - Properties
    
    public var log: (String -> ())?
    
    public var database = GATTDatabase()
    
    public var willRead: ((UUID: Bluetooth.UUID, value: Data, offset: Int) -> ATT.Error?)?
    
    public var willWrite: ((UUID: Bluetooth.UUID, value: Data, newValue: (newValue: Data, newBytes: Data, offset: Int)) -> ATT.Error?)?
    
    public let maximumPreparedWrites: Int
    
    // MARK: - Private Properties
    
    private let connection: ATTConnection
    
    private var preparedWrites = [PreparedWrite]()
    
    // MARK: - Initialization
    
    public init(socket: L2CAPSocket, maximumTransmissionUnit: Int = ATT.MTU.LowEnergy.Default, maximumPreparedWrites: Int = 50) {
        
        // set initial MTU and register handlers
        self.maximumPreparedWrites = maximumPreparedWrites
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
        connection.register(readMultipleRequest)
        
        // Prepare Write Request
        connection.register(prepareWriteRequest)
        
        // Execute Write Request
        connection.register(executeWriteRequest)
    }
    
    @inline(__always)
    private func errorResponse(_ opcode: ATT.Opcode, _ error: ATT.Error, _ handle: UInt16 = 0) {
        
        log?("Error \(error) - \(opcode) (\(handle))")
        
        guard let _ = connection.send(error: error, opcode: opcode, handle: handle)
            else { fatalError("Could not add error PDU to queue: \(opcode) \(error) \(handle)") }
    }
    
    @noreturn @inline(__always)
    private func fatalErrorResponse(_ message: String, _ opcode: ATT.Opcode, _ handle: UInt16 = 0, line: UInt = #line) {
        
        errorResponse(opcode, ATT.Error.UnlikelyError, handle)
        
        do { try connection.write() }
        
        catch { print("Could not send UnlikelyError to client. (\(error))") }
        
        fatalError(message, line: line)
    }
    
    @inline(__always)
    private func respond<T: ATTProtocolDataUnit>(_ response: T) {
        
        log?("Response: \(response)")
        
        guard let _ = connection.send(PDU: response, response: { _ in })
            else { fatalError("Could not add PDU to queue: \(response)") }
    }
    
    private func checkPermissions(_ permissions: [ATT.AttributePermission], _ attribute: GATTDatabase.Attribute) -> ATT.Error? {
        
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
    
    /// Handler for Write Request and Command
    private func handleWriteRequest(opcode: ATT.Opcode, handle: UInt16, value: [UInt8], shouldRespond: Bool) {
        
        /// Conditionally respond
        @inline(__always)
        func doResponse(@autoclosure _ block: () -> ()) {
            
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
        
        let newData = Data(byteValue: value)
        
        // validate application errors with write callback
        if let error = willWrite?(UUID: attribute.UUID, value: attribute.value, newValue: (newData, newData, 0)) {
            
            doResponse(errorResponse(opcode, error, handle))
            return
        }
        
        database.write(newData, forAttribute: handle)
        
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
        guard offset <= UInt16(attribute.value.byteValue.count)
            else { errorResponse(opcode, .InvalidOffset, handle); return nil }
        
        let value: [UInt8]
        
        // Guard against invalid access if offset equals to value length
        if offset == UInt16(attribute.value.byteValue.count) {
            
            value = []
            
        } else if offset > 0 {
            
            value = Array(attribute.value.byteValue.suffix(Int(offset)))
            
        } else {
            
            value = attribute.value.byteValue
        }
        
        // validate application errors with read callback
        if let error = willRead?(UUID: attribute.UUID, value: Data(byteValue: value), offset: Int(offset)) {
            
            errorResponse(opcode, error, handle)
            return nil
        }
        
        return value
    }
    
    private func prepareNewValue(currentValue: [UInt8], newBytes: [UInt8], offset: UInt16) -> [UInt8] {
        
        let offsetIndex = Int(offset)
        
        let prefixBytes = currentValue.isEmpty ? [] : Array(currentValue[0 ... offsetIndex])
        
        let suffixIndex = offsetIndex + newBytes.count
        
        let suffixBytes = currentValue.endIndex < suffixIndex ? [] : Array(currentValue[suffixIndex ... currentValue.endIndex])
        
        return prefixBytes + newBytes + suffixBytes
    }
    
    // MARK: Callbacks
    
    private func exchangeMTU(pdu: ATTMaximumTransmissionUnitRequest) {
        
        let serverMTU = UInt16(connection.maximumTransmissionUnit)
        
        let finalMTU = max(min(pdu.clientMTU, serverMTU), UInt16(ATT.MTU.LowEnergy.Default))
        
        // Respond with the server MTU
        connection.send(PDU: ATTMaximumTranssmissionUnitResponse(serverMTU: serverMTU)) { _ in }
        
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
        
        let data = database.readByGroupType(handle: (pdu.startHandle, pdu.endHandle), type: pdu.type)
        
        guard data.isEmpty == false
            else { errorResponse(opcode, .AttributeNotFound, pdu.startHandle); return }
        
        let attributeData = data.map { AttributeData(attributeHandle: $0.start, endGroupHandle: $0.end, value: $0.UUID.littleEndian) }
        
        var limitedAttributes = [attributeData[0]]
        
        var response = ATTReadByGroupTypeResponse(data: limitedAttributes)!
        
        // limit for MTU if first handle is too large
        if response.byteValue.count > connection.maximumTransmissionUnit {
            
            let maxLength = min(min(connection.maximumTransmissionUnit - 6, 251), limitedAttributes[0].value.count)
            
            limitedAttributes[0].value = Array(limitedAttributes[0].value.prefix(maxLength))
            
            response = ATTReadByGroupTypeResponse(data: limitedAttributes)!
            
        } else {
            
            // limit for MTU for subsequential attribute handles
            for data in attributeData[1 ..< attributeData.count] {
                
                limitedAttributes.append(data)
                
                guard let limitedResponse = ATTReadByGroupTypeResponse(data: limitedAttributes)
                    else { fatalErrorResponse("Could not create ATTReadByGroupTypeResponse. Attribute Data: \(attributeData)", opcode, pdu.startHandle) }
                
                guard limitedResponse.byteValue.count <= connection.maximumTransmissionUnit else { break }
                
                response = limitedResponse
            }
        }
        
        assert(response.byteValue.count <= connection.maximumTransmissionUnit,
               "Response \(response.byteValue.count) bytes > MTU (\(connection.maximumTransmissionUnit))")
        
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
        
        let attributes = database.readByType(handle: (pdu.startHandle, pdu.endHandle), type: pdu.attributeType)
        
        guard attributes.isEmpty == false
            else { errorResponse(opcode, .AttributeNotFound, pdu.startHandle); return }
        
        let attributeData = attributes.map { AttributeData(handle: $0.handle, value: $0.value.byteValue) }
        
        var limitedAttributes = [attributeData[0]]
        
        var response = ATTReadByTypeResponse(data: limitedAttributes)!
        
        // limit for MTU if first handle is too large
        if response.byteValue.count > connection.maximumTransmissionUnit {
            
            let maxLength = min(min(connection.maximumTransmissionUnit - 4, 253), limitedAttributes[0].value.count)
            
            limitedAttributes[0].value = Array(limitedAttributes[0].value.prefix(maxLength))
            
            response = ATTReadByTypeResponse(data: limitedAttributes)!
            
        } else {
            
            // limit for MTU for subsequential attribute handles
            for data in attributeData[1 ..< attributeData.count] {
                
                limitedAttributes.append(data)
                
                guard let limitedResponse = ATTReadByTypeResponse(data: limitedAttributes)
                    else { fatalErrorResponse("Could not create ATTReadByTypeResponse. Attribute Data: \(attributeData)", opcode, pdu.startHandle) }
                
                guard limitedResponse.byteValue.count <= connection.maximumTransmissionUnit else { break }
                
                response = limitedResponse
            }
        }
        
        assert(response.byteValue.count <= connection.maximumTransmissionUnit,
               "Response \(response.byteValue.count) bytes > MTU (\(connection.maximumTransmissionUnit))")
        
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
        
        let attributes = database.findInformation(handle: (pdu.startHandle, pdu.endHandle))
        
        guard attributes.isEmpty == false
            else { errorResponse(opcode, .AttributeNotFound, pdu.startHandle); return }
        
        let format = Format(UUID: attributes[0].UUID)
        
        var bit16Pairs = [(UInt16, UInt16)]()
        
        var bit128Pairs = [(UInt16, UUID)]()
        
        for (index, attribute) in attributes.enumerated() {
            
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
        
        let handles = database.findByTypeValue(handle: (pdu.startHandle, pdu.endHandle), type: pdu.attributeType, value: pdu.attributeValue)
        
        guard handles.isEmpty == false
            else { errorResponse(opcode, .AttributeNotFound, pdu.startHandle); return }
        
        let handlesInformation = handles.map { Handle(foundAttribute: $0.0, groupEnd: $0.1) }
        
        let response = ATTFindByTypeResponse(handlesInformationList: handlesInformation)
        
        respond(response)
    }
    
    private func writeRequest(pdu: ATTWriteRequest) {
        
        let opcode = pdu.dynamicType.attributeOpcode
        
        handleWriteRequest(opcode: opcode, handle: pdu.handle, value: pdu.value, shouldRespond: true)
    }
    
    private func writeCommand(pdu: ATTWriteCommand) {
        
        let opcode = pdu.dynamicType.attributeOpcode
        
        handleWriteRequest(opcode: opcode, handle: pdu.handle, value: pdu.value, shouldRespond: false)
    }
    
    private func readRequest(pdu: ATTReadRequest) {
        
        let opcode = pdu.dynamicType.attributeOpcode
        
        log?("Read (\(pdu.handle))")
        
        if let value = handleReadRequest(opcode: opcode, handle: pdu.handle) {
            
            respond(ATTReadResponse(attributeValue: value))
        }
    }
    
    private func readBlobRequest(pdu: ATTReadBlobRequest) {
        
        let opcode = pdu.dynamicType.attributeOpcode
        
        log?("Read Blob (\(pdu.handle))")
        
        if let value = handleReadRequest(opcode: opcode, handle: pdu.handle, offset: pdu.offset) {
            
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
            
            // validate application errors with read callback
            if let error = willRead?(UUID: attribute.UUID, value: attribute.value, offset: 0) {
                
                errorResponse(opcode, error, handle)
                return
            }
            
            values += attribute.value.byteValue
        }
        
        let response = ATTReadMultipleResponse(values: values)
        
        respond(response)
    }
    
    private func prepareWriteRequest(_ pdu: ATTPrepareWriteRequest) {
        
        let opcode = pdu.dynamicType.attributeOpcode
        
        log?("Prepare Write Request (\(pdu.handle))")
        
        // no attributes, impossible to write
        guard database.attributes.isEmpty == false
            else { errorResponse(opcode, .InvalidHandle, pdu.handle); return }
        
        // validate handle
        guard (1 ... UInt16(database.attributes.count)).contains(pdu.handle)
            else { errorResponse(opcode, .InvalidHandle, pdu.handle); return }
        
        // validate that the prepared writes queue is not full
        guard preparedWrites.count <= maximumPreparedWrites
            else { errorResponse(opcode, .PrepareQueueFull); return }
        
        // validate handle
        guard (1 ... UInt16(database.attributes.count)).contains(pdu.handle)
            else { errorResponse(opcode, .InvalidHandle, pdu.handle); return }
        
        // get attribute
        let attribute = database[pdu.handle]
        
        // validate permissions
        if let error = checkPermissions([.Write, .WriteAuthentication, .WriteEncrypt], attribute) {
            
            errorResponse(opcode, error, pdu.handle)
            return
        }
        
        // The Attribute Value validation is done when an Execute Write Request is received.
        // Hence, any Invalid Offset or Invalid Attribute Value Length errors are generated 
        // when an Execute Write Request is received.
        
        // add queued write
        let preparedWrite = PreparedWrite(handle: pdu.handle, value: pdu.partValue, offset: pdu.offset)
        
        preparedWrites.append(preparedWrite)
        
        let response = ATTPrepareWriteResponse(handle: pdu.handle, offset: pdu.offset, partValue: pdu.partValue)
        
        respond(response)
    }
    
    private func executeWriteRequest(_ pdu: ATTExecuteWriteRequest) {
        
        let opcode = pdu.dynamicType.attributeOpcode
        
        log?("Execute Write Request (\(pdu.flag))")
        
        switch pdu.flag {
            
        case .Write:
            
            var newValues = [Data](repeating: Data(), count: preparedWrites.count)
            
            // validate
            for (index, write) in preparedWrites.enumerated() {
                
                let attribute = database[write.handle]
                
                let newData = prepareNewValue(currentValue: attribute.value.byteValue, newBytes: write.value, offset: write.offset)
                
                // validate application errors with write callback
                if let error = willWrite?(UUID: attribute.UUID, value: attribute.value, newValue: (Data(byteValue: newData), Data(byteValue: write.value), Int(write.offset))) {
                    
                    errorResponse(opcode, error, write.handle)
                    return
                }
                
                newValues[index] = Data(byteValue: newData)
            }
            
            // write
            for (index, write) in preparedWrites.enumerated() {
                
                let newValue = newValues[index]
                
                database.write(newValue, forAttribute: write.handle)
            }
            
        case .Cancel: break // queue always cleared
        }
        
        preparedWrites = []
        
        respond(ATTExecuteWriteRequest())
    }
}

// MARK: - Supporting Types

private extension GATTServer {
    
    struct PreparedWrite {
        
        let handle: UInt16
        
        let value: [UInt8]
        
        let offset: UInt16
    }
}

// MARK: - GATTDatabase Extensions

internal extension GATTDatabase {
    
    /// Used for Service discovery. Should return tuples with the Service start handle, end handle and UUID.
    func readByGroupType(handle: (start: UInt16, end: UInt16), type: Bluetooth.UUID) -> [(start: UInt16, end: UInt16, UUID: Bluetooth.UUID)] {
        
        let handleRange = handle.end < UInt16.max ? handle.start ... handle.end : handle.start ..< handle.end
        
        var data: [(start: UInt16, end: UInt16, UUID: Bluetooth.UUID)] = []
        
        for group in attributeGroups {
            
            guard group.service.UUID == type else { continue }
            
            let groupRange = group.startHandle ... group.endHandle
            
            guard groupRange.isSubset(handleRange) else { continue }
            
            let serviceUUID = Bluetooth.UUID(littleEndian: group.service.value.byteValue)!
            
            data.append((group.startHandle, group.endHandle, serviceUUID))
        }
        
        return data
    }
    
    func readByType(handle: (start: UInt16, end: UInt16), type: Bluetooth.UUID) -> [Attribute] {
        
        let range = handle.end < UInt16.max ? handle.start ... handle.end : handle.start ..< handle.end
        
        return attributes.filter { range.contains($0.handle) && $0.UUID == type }
    }
    
    func findInformation(handle: (start: UInt16, end: UInt16)) -> [Attribute] {
        
        let range = handle.end < UInt16.max ? handle.start ... handle.end : handle.start ..< handle.end
        
        return attributes.filter { range.contains($0.handle) }
    }
    
    func findByTypeValue(handle: (start: UInt16, end: UInt16), type: UInt16, value: [UInt8]) -> [(UInt16, UInt16)] {
        
        let range = handle.end < UInt16.max ? handle.start ... handle.end : handle.start ..< handle.end
        
        var results = [(UInt16, UInt16)]()
        
        for group in attributeGroups {
            
            for attribute in group.attributes {
                
                let match = range.contains(attribute.handle) && attribute.UUID == .Bit16(type) && attribute.value.byteValue == value
                
                guard match else { continue }
                
                results.append((group.startHandle, group.endHandle))
            }
        }
        
        return results
    }
}

