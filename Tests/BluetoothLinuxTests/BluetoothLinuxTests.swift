//
//  BluetoothLinuxTests.swift
//  BluetoothLinuxTests
//
//  Created by Alsey Coleman Miller on 4/18/19.
//

import Foundation
import XCTest
import Bluetooth
@testable import BluetoothLinux

final class BluetoothLinuxTests: XCTestCase {
    
    static let allTests = [
        ("testPOSIXError", testPOSIXError)
    ]
    
    func testPOSIXError() {
        
        guard Locale.current.languageCode == "en"
            else { print("Can only run test with English locale"); return }
        
        let errors: [(POSIXErrorCode, String)] = [
            (.EPERM, "Operation not permitted"),
            (.ENOENT, "No such file or directory"),
            (.ESRCH, "No such process"),
            (.EINTR, "Interrupted system call"),
            (.EIO, "Input/output error")
        ]
        
        for (errorCode, string) in errors {
            
            let error = POSIXError(_nsError: NSPOSIXError(errorCode))
            #if os(macOS) || swift(>=5.1)
            // https://github.com/apple/swift-corelibs-foundation/pull/2113
            XCTAssertEqual(error.code, errorCode)
            #endif
            #if os(macOS)
            // https://github.com/apple/swift-corelibs-foundation/pull/2140
            XCTAssertEqual(error.localizedDescription, string)
            #endif
            XCTAssertEqual(error.errorCode, Int(errorCode.rawValue))
            XCTAssertEqual(error._nsError.localizedFailureReason, string)
            XCTAssertEqual(error._nsError.localizedDescription, string)
            XCTAssertEqual(error._nsError.domain, NSPOSIXErrorDomain)
            XCTAssertEqual(error._nsError.code, Int(errorCode.rawValue))
            let errorDescription = "Error Domain=\(NSPOSIXErrorDomain) Code=\(errorCode.rawValue) \"\(string)\""
            XCTAssertEqual("\(error)", errorDescription)
        }
    }
}
