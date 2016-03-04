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
    static var length: Int { get }
    
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
            
            guard byteValue.count % pairLength == 0 else { return }
            
            let pairCount = byteValue.count / pairLength
            
            switch format {
                
            case .Bit16:
                
                
                
            case .Bit128:
                
                
            }
        }
        
        public var byteValue: [UInt8] {
            
            
        }
    }
}



