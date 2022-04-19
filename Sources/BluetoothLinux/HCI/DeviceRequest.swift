//
//  DeviceRequest.swift
//  BluetoothLinux
//
//  Created by Alsey Coleman Miller on 1/3/16.
//  Copyright © 2016 PureSwift. All rights reserved.
//

import Foundation
import Bluetooth
import BluetoothHCI

public extension HostController {

    /// Send an HCI command with parameters to the controller and waits for a response.
    func deviceRequest<CP: HCICommandParameter, EP: HCIEventParameter> (
        _ commandParameter: CP,
        _ eventParameterType: EP.Type,
        timeout: HCICommandTimeout = .default
    ) async throws -> EP {
            
        let command = CP.command
        let parameterData = commandParameter.data
        let responseData = try await socket.sendRequest(
            command: command,
            commandParameterData: parameterData,
            event: EP.event.rawValue,
            eventParameterLength: EP.length,
            timeout: timeout
        )
        guard let eventParameter = EP(data: responseData)
            else { throw BluetoothHostControllerError.garbageResponse(responseData) }
        
        return eventParameter
    }
    
    /// Send an HCI command to the controller and waits for a response.
    func deviceRequest<C, EP>(
        _ command: C,
        _ eventParameterType: EP.Type,
        timeout: HCICommandTimeout = .default
    ) async throws -> EP where C : HCICommand, EP : HCIEventParameter {
        
        let data = try await socket.sendRequest(
            command: command,
            event: EP.event.rawValue,
            eventParameterLength: EP.length,
            timeout: timeout
        )
        
        guard let eventParameter = EP(data: data)
            else { throw BluetoothHostControllerError.garbageResponse(data) }
        
        return eventParameter
    }
    
    /// Send a command to the controller and wait for response. 
    func deviceRequest<C: HCICommand>(
        _ command: C,
        timeout: HCICommandTimeout = .default
    ) async throws {

        let data = try await socket.sendRequest(
            command: command,
            eventParameterLength: 1,
            timeout: timeout
        )
        
        guard let statusByte = data.first
            else { fatalError("Missing status byte!") }
        
        guard statusByte == 0x00
            else { throw HCIError(rawValue: statusByte)! }
        
    }
    
    func deviceRequest<CP: HCICommandParameter>(
        _ commandParameter: CP,
        timeout: HCICommandTimeout = .default
    ) async throws {
        
        let data = try await socket.sendRequest(
            command: CP.command,
            commandParameterData: commandParameter.data,
            eventParameterLength: 1,
            timeout: timeout
        )
        
        guard let statusByte = data.first
            else { fatalError("Missing status byte!") }
        
        guard statusByte == 0x00
            else { throw HCIError(rawValue: statusByte)! }
    }
    
    func deviceRequest <Return: HCICommandReturnParameter> (
        _ commandReturnType : Return.Type,
        timeout: HCICommandTimeout = .default
    ) async throws -> Return {
        
        let data = try await socket.sendRequest(
            command: commandReturnType.command,
            eventParameterLength: commandReturnType.length + 1, // status code + parameters
            timeout: timeout
        )
        
        guard let statusByte = data.first
            else { fatalError("Missing status byte!") }
        
        guard statusByte == 0x00
            else { throw HCIError(rawValue: statusByte)! }
        
        guard let response = Return(data: Data(data.suffix(from: 1)))
            else { throw BluetoothHostControllerError.garbageResponse(Data(data)) }
        
        return response
    }
    
    /// Sends a command to the device and waits for a response with return parameter values.
    func deviceRequest <CP: HCICommandParameter, Return: HCICommandReturnParameter> (
        _ commandParameter: CP,
        _ commandReturnType : Return.Type,
        timeout: HCICommandTimeout = .default
    ) async throws -> Return {
        
        assert(CP.command.opcode == Return.command.opcode)
        
        let data = try await socket.sendRequest(
            command: commandReturnType.command,
            commandParameterData: commandParameter.data,
            eventParameterLength: commandReturnType.length + 1,
            timeout: timeout
        )
        
        guard let statusByte = data.first
            else { fatalError("Missing status byte!") }
        
        guard statusByte == 0x00
            else { throw HCIError(rawValue: statusByte)! }
        
        guard let response = Return(data: Data(data.suffix(from: 1)))
            else { throw BluetoothHostControllerError.garbageResponse(Data(data)) }
        
        return response
    }
}
