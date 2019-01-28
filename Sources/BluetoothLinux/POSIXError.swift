//
//  POSIXError.swift
//  SwiftFoundation
//
//  Created by Alsey Coleman Miller on 7/22/15.
//  Copyright © 2015 PureSwift. All rights reserved.
//

import Foundation

internal extension POSIXError {
    
    /// Creates error from C ```errno```.
    static var errorno: POSIXError {
        
        guard let code = POSIXError.Code(rawValue: POSIXError.Code.RawValue(errno))
            else { return POSIXError(.EIO) } // default error
        
        return self.init(code)
    }
}
