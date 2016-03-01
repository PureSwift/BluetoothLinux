//
//  ATTProtocolDataUnit.swift
//  BlueZ
//
//  Created by Alsey Coleman Miller on 3/1/16.
//  Copyright © 2016 PureSwift. All rights reserved.
//

// MARK: - Protocol

public protocol ATTProtocolDataUnit {
    
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



