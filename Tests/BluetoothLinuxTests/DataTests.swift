//
//  DataTests.swift
//  BluetoothLinux
//
//  Created by Alsey Coleman Miller on 12/8/17.
//
//

import XCTest
import Foundation
import Bluetooth
import CSwiftBluetoothLinux
@testable import BluetoothLinux

final class DataTests: XCTestCase {
    
    static let allTests = [
        ("testGATTClientData", testGATTClientData)
    ]
    
    func testGATTClientData() {
        
        do {
            
            let data: [UInt8] = [9, 21, 41, 0, 2, 42, 0, 199, 168, 213, 112, 224, 35, 224, 128, 229, 17, 111, 249, 76, 38, 125, 231]
            
            guard let pdu = ATTReadByTypeResponse(byteValue: data)
                else { XCTFail("Could not parse"); return }
            
            XCTAssert(pdu.byteValue == data)
            
            guard let foundCharacteristicData = pdu.data.first,
                pdu.data.count == 1
                else { XCTFail("Invalid response"); return }
            
            XCTAssert(foundCharacteristicData.handle == 41)
            XCTAssert(foundCharacteristicData.value.isEmpty == false)
            
            guard let characteristicDeclaration = GATTClient.CharacteristicDeclaration(littleEndian: foundCharacteristicData.value)
                else { XCTFail("Could not parse"); return }
            
            let characteristic = TestProfile.Read
            
            XCTAssert(characteristicDeclaration.valueHandle == 42)
            XCTAssert(characteristicDeclaration.uuid == characteristic.uuid)
            XCTAssert(characteristicDeclaration.properties.set == Set(characteristic.properties))
            XCTAssert(characteristicDeclaration.properties == characteristic.properties)
        }
    }
}

public struct TestProfile {
    
    public typealias Service = GATT.Service
    public typealias Characteristic = GATT.Characteristic
    
    public static let services = [TestProfile.TestService]
    
    public static let TestService = Service(uuid: BluetoothUUID(rawValue: "60F14FE2-F972-11E5-B84F-23E070D5A8C7")!,
                                            primary: true,
                                            characteristics: [TestProfile.Read,
                                                              TestProfile.ReadBlob,
                                                              TestProfile.Write,
                                                              TestProfile.WriteBlob])
    
    public static let Read = Characteristic(uuid: BluetoothUUID(rawValue: "E77D264C-F96F-11E5-80E0-23E070D5A8C7")!,
                                            value: "Test Read-Only".toUTF8Data(),
                                            permissions: [.read],
                                            properties: [.read])
    
    public static let ReadBlob = Characteristic(uuid: BluetoothUUID(rawValue: "0615FF6C-0E37-11E6-9E58-75D7DC50F6B1")!,
                                                value: Data(bytes: [UInt8](repeating: UInt8.max, count: 512)),
                                                permissions: [.read],
                                                properties: [.read])
    
    public static let Write = Characteristic(uuid: BluetoothUUID(rawValue: "37BBD7D0-F96F-11E5-8EC1-23E070D5A8C7")!,
                                             value: Data(),
                                             permissions: [.write],
                                             properties: [.write])
    
    public static let WriteValue = "Test Write".toUTF8Data()
    
    public static let WriteBlob = Characteristic(uuid: BluetoothUUID(rawValue: "2FDDB448-F96F-11E5-A891-23E070D5A8C7")!,
                                                 value: Data(),
                                                 permissions: [.write],
                                                 properties: [.write])
    
    public static let WriteBlobValue = Data(bytes: [UInt8](repeating: 1, count: 512))
}
