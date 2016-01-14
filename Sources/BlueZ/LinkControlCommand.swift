//
//  LinkControlCommand.swift
//  BlueZ
//
//  Created by Alsey Coleman Miller on 1/13/16.
//  Copyright © 2016 PureSwift. All rights reserved.
//

public extension Bluetooth {
    
    public enum LinkControlCommand: UInt16, HCICommand {
        
        public static let opcodeGroupField = OpcodeGroupField.LinkControl
        
        /// Command used to enter Inquiry mode where it discovers other Bluetooth devices.
        case Inquiry                    = 0x01
        
        /// Command to cancel the Inquiry mode in which the Bluetooth device is in.
        case InquiryCancel              = 0x02
        
        /// Command to set the device to enter Inquiry modes periodically according to the time interval set.
        case PeriodicInquiry            = 0x03
        
        /// Command to exit the periodic Inquiry mode.
        case ExitPeriodicInquiry        = 0x04
        
        /// Command to create an ACL connection to the device specified by the BD_ADDR in the parameters.
        case CreateConnection           = 0x05
        
        /// Command to terminate the existing connection to a device.
        case Disconnect                 = 0x06
        
        /// Create an SCO connection defined by the connection handle parameters.
        case AddSCOConnection           = 0x07
        
        /// Cancel Create Connection
        case CreateConnectionCancel     = 0x08
        
        /// Command to accept a new connection request.
        case AcceptConnection           = 0x09
        
        /// Command to reject a new connection request.
        case RejectConnection           = 0x0A
        
        /// Reply command to a link key request event sent from controller to the host.
        case LinkKeyReply               = 0x0B
        
        /// Reply command to a link key request event from the controller to the host if there is no link key associated with the connection.
        case LinkKeyNegativeReply       = 0x0C
        
        /// Reply command to a PIN code request event sent from a controller to the host.
        case PinCodeReply               = 0x0D
        
        /// Reply command to a PIN code request event sent from the controller to the host if there is no PIN associated with the connection.
        case PinCodeNegativeReply       = 0x0E
        
        /// Command to change the type of packets to be sent for an existing connection.
        case SetConnectionPacketType    = 0x0F
        
        /// Command to establish authentication between two devices specified by the connection handle.
        case AuthenticationRequested    = 0x11
        
        /// 
        case
    }
}

