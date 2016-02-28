//
//  ATT.swift
//  BlueZ
//
//  Created by Alsey Coleman Miller on 2/28/16.
//  Copyright © 2016 PureSwift. All rights reserved.
//

#if os(Linux)
    import CBlueZ
    import CBlueZInternal
    import Glibc
#elseif os(OSX) || os(iOS)
    import Darwin.C
#endif

/// Handles the transport and encoding/decoding for the ATT protocol.
public final class ATT {
    
    /// Whether the file descriptor will be closed on deallocation.
    public var closeFileDescriptor: Bool = false {
        
        willSet { bt_att_set_close_on_unref(internalPointer, newValue) }
    }
    
    // MARK: - Internal Properties
    
    internal let internalPointer: COpaquePointer
    
    // MARK: - Initialization
    
    deinit {
        
        bt_att_unref(internalPointer)
    }
    
    internal init(_ internalPointer: COpaquePointer) {
        
        assert(internalPointer != nil)
        
        self.internalPointer = internalPointer
    }
    
    public init?(fileDescriptor: CInt, externalCrypto: Bool = false) {
        
        self.internalPointer = bt_att_new(fileDescriptor, externalCrypto)
        
        guard internalPointer != nil else { return nil }
    }
    
    // MARK: - Methods
    
    
    
    // MARK: - Dynamic Properties
    
    public var fileDescriptor: CInt {
        
        return bt_att_get_fd(internalPointer)
    }
    
    public var hasCrypto: Bool {
        
        return bt_att_has_crypto(internalPointer)
    }
}

// MARK: - Darwin Stubs

#if os(OSX) || os(iOS)
    
    func bt_att_new(fd: CInt, _ externalCrypto: CBool) -> COpaquePointer { stub() }
    
    func bt_att_unref(att: COpaquePointer) { stub() }
    
    func bt_att_set_close_on_unref(att: COpaquePointer, _ doClose: CBool) { stub() }
    
    func bt_att_get_fd(att: COpaquePointer) -> CInt { stub() }
    
    func bt_att_has_crypto(att: COpaquePointer) -> CBool { stub() }
    
    
    
#endif
