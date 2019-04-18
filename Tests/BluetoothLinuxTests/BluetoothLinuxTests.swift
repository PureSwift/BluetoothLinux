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
        
        let errors: [(POSIXErrorCode, String)] = [
            (.EPERM, "Operation not permitted"),
            (.ENOENT, "No such file or directory"),
            (.ESRCH, "No such process"),
            (.EINTR, "Interrupted system call"),
            (.EIO, "Input/output error")
        ]
        
        for (errorCode, string) in errors {
            
            let error = POSIXError(_nsError: NSPOSIXError(errorCode))
            XCTAssertEqual(error._nsError.localizedFailureReason, string)
            XCTAssertEqual(error._nsError.localizedDescription, "The operation couldn’t be completed. " + string)
            let errorDescription = "Error Domain=\(NSPOSIXErrorDomain) Code=\(errorCode.rawValue) \"\(string)\""
            XCTAssertEqual("\(error)", "POSIXError(_nsError: \(errorDescription))")
        }
    }
}
