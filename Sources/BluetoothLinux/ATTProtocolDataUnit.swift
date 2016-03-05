//
//  ATTProtocolDataUnit.swift
//  BluetoothLinux
//
//  Created by Alsey Coleman Miller on 3/1/16.
//  Copyright © 2016 PureSwift. All rights reserved.
//

import struct SwiftFoundation.UUID

// MARK: - Protocol

public protocol ATTProtocolDataUnit {
    
    /// The PDU's attribute opcode.
    static var attributeOpcode: ATT.Opcode { get }
    
    /// The PDU length in bytes.
    //static var length: Int { get }
    
    /// Converts PDU to raw bytes.
    var byteValue: [UInt8] { get }
    
    /// Initializes PDU from raw bytes.
    init?(byteValue: [UInt8])
}

// MARK: - ATT PDUs

/// The Error Response is used to state that a given request cannot be performed,
/// and to provide the reason.
///
/// - Note: The Write Command does not generate an Error Response.
public struct ATTErrorResponse: ATTProtocolDataUnit, ErrorType {
    
    /// The request that generated this error response
    public var requestOpcode: ATT.Opcode
    
    /// The attribute handle that generated this error response.
    public var attributeHandle: UInt16
    
    /// The reason why the request has generated an error response.
    public var error: ATT.Error
    
    public init(requestOpcode: ATT.Opcode, attributeHandle: UInt16, error: ATT.Error) {
        
        self.requestOpcode = requestOpcode
        self.attributeHandle = attributeHandle
        self.error = error
    }
    
    // MARK: ATTProtocolDataUnit
    
    public static let attributeOpcode = ATT.Opcode.ErrorResponse
    
    public static let length = 5
    
    public init?(byteValue: [UInt8]) {
        
        guard byteValue.count == ATTErrorResponse.length else { return nil }
        
        let attributeOpcodeByte     = byteValue[0]
        let requestOpcodeByte       = byteValue[1]
        let attributeHandleByte1    = byteValue[2]
        let attributeHandleByte2    = byteValue[3]
        let errorByte               = byteValue[4]
        
        guard attributeOpcodeByte == ATTErrorResponse.attributeOpcode.rawValue,
            let requestOpcode = ATTOpcode(rawValue: requestOpcodeByte),
            let error = ATTError(rawValue: errorByte)
            else { return nil }
        
        self.requestOpcode = requestOpcode
        self.error = error
        self.attributeHandle = UInt16(littleEndian: (attributeHandleByte1, attributeHandleByte2))
    }
    
    public var byteValue: [UInt8] {
        
        var bytes = [UInt8](count: ATTErrorResponse.length, repeatedValue: 0)
        
        bytes[0] = ATTErrorResponse.attributeOpcode.rawValue
        bytes[1] = requestOpcode.rawValue
        bytes[2] = attributeHandle.littleEndianBytes.0
        bytes[3] = attributeHandle.littleEndianBytes.1
        bytes[4] = error.rawValue
        
        return bytes
    }
}

/// Exchange MTU Request
///
/// The *Exchange MTU Request* is used by the client to inform the server of the client’s maximum receive MTU
/// size and request the server to respond with its maximum receive MTU size.
///
/// - Note: This request shall only be sent once during a connection by the client. 
/// The *Client Rx MTU* parameter shall be set to the maximum size of the attribute protocol PDU that the client can receive.
public struct ATTMaximumTransmissionUnitRequest: ATTProtocolDataUnit {
    
    public static let attributeOpcode = ATT.Opcode.MaximumTransmissionUnitRequest
    public static let length = 3
    
    /// Client Rx MTU
    var clientMTU: UInt16
    
    public init(clientMTU: UInt16 = 0) {
        
        self.clientMTU = clientMTU
    }
    
    public init?(byteValue: [UInt8]) {
        
        guard byteValue.count == self.dynamicType.length
            else { return nil }
        
        let attributeOpcodeByte = byteValue[0]
        
        guard attributeOpcodeByte == self.dynamicType.attributeOpcode.rawValue
            else { return nil }
        
        self.clientMTU = UInt16(littleEndian: (byteValue[1], byteValue[2]))
    }
    
    public var byteValue: [UInt8] {
        
        var bytes = [UInt8](count: ATTErrorResponse.length, repeatedValue: 0)
        
        bytes[0] = self.dynamicType.attributeOpcode.rawValue
        
        let mtuBytes = self.clientMTU.littleEndianBytes
        
        bytes[1] = mtuBytes.0
        bytes[2] = mtuBytes.1
        
        return bytes
    }
}

///  Exchange MTU Response
///
/// The *Exchange MTU Response* is sent in reply to a received *Exchange MTU Request*.
public struct ATTMaximumTranssmissionUnitResponse: ATTProtocolDataUnit {
    
    public static let attributeOpcode = ATT.Opcode.MaximumTransmissionUnitResponse
    public static let length = 3
    
    /// Server Rx MTU
    public var serverMTU: UInt16
    
    public init(serverMTU: UInt16 = 0) {
        
        self.serverMTU = serverMTU
    }
    
    public init?(byteValue: [UInt8]) {
        
        guard byteValue.count == self.dynamicType.length
            else { return nil }
        
        let attributeOpcodeByte = byteValue[0]
        
        guard attributeOpcodeByte == self.dynamicType.attributeOpcode.rawValue
            else { return nil }
        
        self.serverMTU = UInt16(littleEndian: (byteValue[1], byteValue[2]))
    }
    
    public var byteValue: [UInt8] {
        
        var bytes = [UInt8](count: self.dynamicType.length, repeatedValue: 0)
        
        bytes[0] = self.dynamicType.attributeOpcode.rawValue
        
        let mtuBytes = self.serverMTU.littleEndianBytes
        
        bytes[1] = mtuBytes.0
        bytes[2] = mtuBytes.1
        
        return bytes
    }
}

/// The *Find Information Request* is used to obtain the mapping of attribute handles with their associated types. 
/// This allows a client to discover the list of attributes and their types on a server.
public struct ATTFindInformationRequest: ATTProtocolDataUnit {
    
    public static let attributeOpcode = ATT.Opcode.FindInformationRequest
    public static let length = 5
    
    public var startHandle: UInt16
    
    public var endHandle: UInt16
    
    public init(startHandle: UInt16 = 0, endHandle: UInt16 = 0) {
        
        self.startHandle = startHandle
        self.endHandle = endHandle
    }
    
    public init?(byteValue: [UInt8]) {
        
        guard byteValue.count == self.dynamicType.length
            else { return nil }
        
        let attributeOpcodeByte = byteValue[0]
        
        guard attributeOpcodeByte == self.dynamicType.attributeOpcode.rawValue
            else { return nil }
        
        self.startHandle = UInt16(littleEndian: (byteValue[1], byteValue[2]))
        self.endHandle = UInt16(littleEndian: (byteValue[3], byteValue[4]))
    }
    
    public var byteValue: [UInt8] {
        
        var bytes = [UInt8](count: self.dynamicType.length, repeatedValue: 0)
        
        bytes[0] = self.dynamicType.attributeOpcode.rawValue
        
        let startHandleBytes = self.startHandle.littleEndianBytes
        let endHandleBytes = self.endHandle.littleEndianBytes
        
        bytes[1] = startHandleBytes.0
        bytes[2] = startHandleBytes.1
        
        bytes[3] = endHandleBytes.0
        bytes[4] = endHandleBytes.1
        
        return bytes
    }
}

/// Find Information Response
///
/// The *Find Information Response* is sent in reply to a received *Find Information Request* 
/// and contains information about this server.
public struct ATTFindInformationResponse: ATTProtocolDataUnit {
    
    public static let attributeOpcode = ATT.Opcode.FindInformationRequest
    
    /// Length ranges from 6, to the maximum MTU size.
    public static let length = 8
    
    /// The information data whose format is determined by the Format field.
    public var data: Data
    
    public init(data: Data) {
        
        self.data = data
    }
    
    public init?(byteValue: [UInt8]) {
        
        guard byteValue.count >= ATTFindInformationResponse.length else { return nil }
        
        let attributeOpcodeByte = byteValue[0]
        let formatByte = byteValue[1]
        let remainderData = Array(byteValue.suffixFrom(2))
        
        guard attributeOpcodeByte == self.dynamicType.attributeOpcode.rawValue,
            let format = Format(rawValue: formatByte),
            let data = Data(byteValue: remainderData, format: format)
            else { return nil }
        
        self.data = data
    }
    
    public var byteValue: [UInt8] {
        
        // first 2 bytes are opcode and format
        return [self.dynamicType.attributeOpcode.rawValue, data.format.rawValue] + data.byteValue
    }
    
    public enum Format: UInt8 {
        
        /// A list of 1 or more handles with their 16-bit Bluetooth UUIDs.
        case Bit16      = 0x01
        
        /// A list of 1 or more handles with their 128-bit UUIDs.
        case Bit128     = 0x02
        
        public var length: Int {
            
            switch self {
            case .Bit16: return 2 + 2
            case .Bit128: return 2 + 16
            }
        }
    }
    
    public enum Data {
        
        /// Handle and 16-bit Bluetooth UUID
        case Bit16([(UInt16, UInt16)])
        
        /// Handle and 128-bit UUIDs
        case Bit128([(UInt16, SwiftFoundation.UUID)])
        
        /// The data's format.
        public var format: Format {
            
            switch self {
                
            case .Bit16(_): return .Bit16
            case .Bit128(_): return .Bit128
                
            }
        }
        
        public init?(byteValue: [UInt8], format: Format) {
            
            let pairLength = format.length
            
            guard byteValue.count % pairLength == 0 else { return nil }
            
            let pairCount = byteValue.count / pairLength
            
            var bit16Pairs: [(UInt16, UInt16)] = []
            
            var bit128Pairs: [(UInt16, SwiftFoundation.UUID)] = []
            
            for pairIndex in 0 ..< pairCount {
                
                let byteIndex = pairIndex * pairLength
                
                let pairBytes = Array(byteValue[byteIndex ..< byteIndex + pairLength])
                
                let handle = UInt16(littleEndian: (pairBytes[0], pairBytes[1]))
                
                switch format {
                    
                case .Bit16:
                    
                    let uuid = UInt16(littleEndian: (pairBytes[2], pairBytes[3]))
                    
                    bit16Pairs.append((handle, uuid))
                    
                case .Bit128:
                    
                    let uuid = UUID(byteValue: (pairBytes[2], pairBytes[3], pairBytes[4], pairBytes[5], pairBytes[6], pairBytes[7], pairBytes[8], pairBytes[9], pairBytes[10], pairBytes[11], pairBytes[12], pairBytes[13], pairBytes[14], pairBytes[15], pairBytes[16], pairBytes[17]))
                    
                     bit128Pairs.append((handle, uuid))
                }
            }
            
            switch format {
                
            case .Bit16: self = .Bit16(bit16Pairs)
                
            case .Bit128: self = .Bit128(bit128Pairs)
            }
        }
        
        public var byteValue: [UInt8] {
            
            var bytes = [UInt8]()
            
            switch self {
                
            case let .Bit16(value):
                
                for pair in value {
                    
                    let handleBytes = pair.0.littleEndianBytes
                    
                    let uuidBytes = pair.1.littleEndianBytes
                    
                    bytes += [handleBytes.0, handleBytes.1, uuidBytes.0, uuidBytes.1]
                }
                
            case let .Bit128(value):
                
                for pair in value {
                    
                    let handleBytes = pair.0.littleEndianBytes
                    
                    let uuidBytes = pair.1.byteValue
                    
                    bytes += [handleBytes.0, handleBytes.1, uuidBytes.0, uuidBytes.1, uuidBytes.2, uuidBytes.3, uuidBytes.4, uuidBytes.5, uuidBytes.6, uuidBytes.7, uuidBytes.8, uuidBytes.9, uuidBytes.10, uuidBytes.11, uuidBytes.12, uuidBytes.13, uuidBytes.14, uuidBytes.15]
                }
            }
            
            return bytes
        }
    }
}

/// Find By Type Value Request
///
/// The *Find By Type Value Request* is used to obtain the handles of attributes that have a 16-bit UUID attribute type 
/// and attribute value. This allows the range of handles associated with a given attribute to be discovered when
/// the attribute type determines the grouping of a set of attributes. 
///
/// - Note: Generic Attribute Profile defines grouping of attributes by attribute type.
public struct ATTFindByTypeRequest: ATTProtocolDataUnit {
    
    public static let attributeOpcode = ATT.Opcode.FindByTypeRequest
    
    /// Minimum length.
    public static let length = 1 + 2 + 2 + 2 + 0
    
    /// First requested handle number
    public var startHandle: UInt16
    
    /// Last requested handle number
    public var endHandle: UInt16
    
    /// 2 octet UUID to find.
    public var attributeType: UInt16
    
    /// Attribute value to find.
    public var attributeValue: [UInt8]
    
    public init(startHandle: UInt16 = 0, endHandle: UInt16 = 0, attributeType: UInt16 = 0, attributeValue: [UInt8] = []) {
        
        self.startHandle = startHandle
        self.endHandle = endHandle
        self.attributeType = attributeType
        self.attributeValue = attributeValue
    }
    
    public init?(byteValue: [UInt8]) {
        
        guard byteValue.count >= ATTFindByTypeRequest.length else { return nil }
        
        let attributeOpcodeByte = byteValue[0]
        
        guard attributeOpcodeByte == self.dynamicType.attributeOpcode.rawValue
            else { return nil }
        
        self.startHandle = UInt16(littleEndian: (byteValue[1], byteValue[2]))
        
        self.endHandle = UInt16(littleEndian: (byteValue[3], byteValue[4]))
        
        self.attributeType = UInt16(littleEndian: (byteValue[5], byteValue[6]))
        
        /// if attributeValue is included
        if byteValue.count >= 7 {
            
            // rest of data is attribute
            self.attributeValue = Array(byteValue.suffixFrom(7))
            
        } else {
            
            self.attributeValue = []
        }
    }
    
    public var byteValue: [UInt8] {
        
        let startHandleBytes = self.startHandle.littleEndianBytes
        
        let endHandleBytes = self.endHandle.littleEndianBytes
        
        let attributeTypeBytes = self.attributeType.littleEndianBytes
        
        return [self.dynamicType.attributeOpcode.rawValue, startHandleBytes.0, startHandleBytes.1, endHandleBytes.0, endHandleBytes.1, attributeTypeBytes.0, attributeTypeBytes.1] + attributeValue
    }
}

/// Find By Type Value Response
///
/// The *Find By Type Value Response* is sent in reply to a received *Find By Type Value Request*
/// and contains information about this server.
public struct ATTFindByTypeResponse: ATTProtocolDataUnit {
    
    public static let attributeOpcode = ATT.Opcode.FindByTypeResponse
    
    /// Minimum length.
    public static let length = 1 + HandlesInformation.length
    
    /// A list of 1 or more Handle Informations.
    public var handlesInformationList: [HandlesInformation]
    
    public init(handlesInformationList: [HandlesInformation]) {
        
        assert(handlesInformationList.count >= 1, "Must have at least one HandlesInformation")
        
        self.handlesInformationList = handlesInformationList
    }
    
    public init?(byteValue: [UInt8]) {
        
        guard byteValue.count >= ATTFindByTypeResponse.length
            else { return nil }
        
        let attributeOpcodeByte = byteValue[0]
        
        guard attributeOpcodeByte == self.dynamicType.attributeOpcode.rawValue
            else { return nil }
        
        let handleLength = HandlesInformation.length
        
        guard byteValue.count % handleLength == 0 else { return nil }
        
        let handleCount = byteValue.count / handleLength
        
        var handles = [HandlesInformation](count: handleCount, repeatedValue: HandlesInformation())
        
        for index in 0 ..< handleCount {
            
            let byteIndex = index * handleLength
            
            let handleBytes = Array(byteValue[byteIndex ..< byteIndex + handleLength])
            
            guard let handle = HandlesInformation(byteValue: handleBytes)
                else { return nil }
            
            handles[index] = handle
        }
        
        self.handlesInformationList = handles
    }
    
    public var byteValue: [UInt8] {
        
        // complex algorithm for better performance
        let handlesDataByteCount = handlesInformationList.count * HandlesInformation.length
        
        // preallocate memory to avoid performance penalty by increasing buffer
        var handlesData = [UInt8](count: handlesDataByteCount, repeatedValue: 0)
        
        for (handleIndex, handle) in handlesInformationList.enumerate() {
            
            let startByteIndex = handleIndex * HandlesInformation.length
            
            let byteRange = startByteIndex ..< startByteIndex + HandlesInformation.length
            
            handlesData.replaceRange(byteRange, with: handle.byteValue)
        }
        
        return [self.dynamicType.attributeOpcode.rawValue] + handlesData
    }
    
    /// Handles Information
    ///
    /// For each handle that matches the attribute type and attribute value in the *Find By Type Value Request* a *Handles Information* shall be returned. The Found Attribute Handle shall be set to the handle of the attribute that has the exact attribute type and attribute value from the Find By Type Value Request.
    public struct HandlesInformation {
        
        public static let length = 2 + 2
        
        /// Found Attribute Handle
        var foundAttribute: UInt16
        
        /// Group End Handle
        var groupEnd: UInt16
        
        public init(foundAttribute: UInt16 = 0, groupEnd: UInt16 = 0) {
            
            self.foundAttribute = foundAttribute
            self.groupEnd = groupEnd
        }
        
        public init?(byteValue: [UInt8]) {
         
            guard byteValue.count == HandlesInformation.length
                else { return nil }
            
            self.foundAttribute = UInt16(littleEndian: (byteValue[0], byteValue[1]))
            self.groupEnd = UInt16(littleEndian: (byteValue[3], byteValue[4]))
        }
        
        public var byteValue: [UInt8] {
            
            let foundAttributeBytes = foundAttribute.littleEndianBytes
            let groupEndBytes = groupEnd.littleEndianBytes
            
            return [foundAttributeBytes.0, foundAttributeBytes.1, groupEndBytes.0, groupEndBytes.1]
        }
    }
}


