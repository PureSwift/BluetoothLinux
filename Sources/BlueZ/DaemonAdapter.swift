//
//  DaemonAdapter.swift
//  BlueZ
//
//  Created by Alsey Coleman Miller on 2/28/16.
//  Copyright © 2016 PureSwift. All rights reserved.
//

#if os(Linux)
    import CBlueZ
    import Glibc
#elseif os(OSX) || os(iOS)
    import Darwin.C
#endif

import SwiftFoundation

/// Adapter interface used in `bluetoothd`.
public final class DaemonAdapter {
    
    // MARK: - Class Properties
    
    public var defaultAdapter: DaemonAdapter? {
        
        let internalPointer = btd_adapter_get_default()
        
        guard internalPointer != nil else { return nil }
        
        let adapter = DaemonAdapter(internalPointer)
        
        return adapter
    }
    
    /// Check if workaround for broken ATT server socket behavior is needed
    /// where we need to connect an ATT client socket before pairing to get
    /// early access to the ATT channel.
    public var lowEnergyConnectBeforePairing: Bool {
        
        return btd_le_connect_before_pairing()
    }
    
    // MARK: - Internal Properties
    
    internal let internalPointer: COpaquePointer
    
    // MARK: - Initialization
    
    deinit {
        
        btd_adapter_unref(internalPointer)
    }
    
    internal init(_ internalPointer: COpaquePointer) {
        
        assert(internalPointer != nil)
        
        self.internalPointer = internalPointer
    }
    
    public init?(address: Address) {
        
        var addressCopy = address
        
        self.internalPointer = withUnsafeMutablePointer(&addressCopy) { adapter_find(COpaquePointer($0)) }
        
        guard internalPointer != nil else { return nil }
    }
    
    public init?(identifier: CInt) {
        
        self.internalPointer = adapter_find_by_id(identifier)
        
        guard internalPointer != nil else { return nil }
    }
    
    // MARK: - Class Methods
    
    public static func initialize() throws {
        
        let errorCode = adapter_init()
        
        guard errorCode == 0 else { throw POSIXError(rawValue: errorCode)! }
    }
    
    public static func cleanup() { adapter_cleanup() }
    
    public static func shutdown() { adapter_shutdown() }
    
    // MARK: - Methods
    
    public func setDeviceClass(mayor mayor: UInt8, minor: UInt8) {
        
        btd_adapter_set_class(internalPointer, mayor, minor)
    }
    
    public func setDeviceName(name: String) throws {
        
        let errorCode = adapter_set_name(internalPointer, name)
        
        guard errorCode == 0 else { throw POSIXError(rawValue: errorCode)! }
    }
    
    public func GATTServerStart() throws {
        
        let errorCode = btd_adapter_gatt_server_start(internalPointer)
        
        guard errorCode == 0 else { throw POSIXError(rawValue: errorCode)! }
    }
    
    public func GATTServerStop() {
        
        btd_adapter_gatt_server_stop(internalPointer)
    }
    
    // MARK: - Dynamic Properties
    
    public var index: UInt16 {
        
        return btd_adapter_get_index(internalPointer)
    }
    
    public var isDefault: Bool {
        
        return btd_adapter_is_default(internalPointer)
    }
    
    public var pairable: Bool {
        
        return btd_adapter_get_pairable(internalPointer)
    }
    
    public var powered: Bool {
        
        return btd_adapter_get_powered(internalPointer)
    }
    
    public var connectable: Bool {
        
        return btd_adapter_get_connectable(internalPointer)
    }
    
    public var deviceClass: UInt32 {
        
        return btd_adapter_get_class(internalPointer)
    }
    
    public var database: GATTDatabase? {
        
        let databaseInternalPointer = btd_adapter_get_database(internalPointer)
        
        guard databaseInternalPointer != nil else { return nil }
        
        let database = GATTDatabase(databaseInternalPointer)
        
        return database
    }
    
    public var deviceName: String {
        
        return String.fromCString(UnsafePointer<CChar>(btd_adapter_get_name(internalPointer))) ?? ""
    }
    
    public var address: Address {
        
        let addressOpaquePointer = btd_adapter_get_address(internalPointer)
        
        assert(addressOpaquePointer != nil, "Nil address pointer")
        
        let addressPointer = UnsafePointer<Address>(addressOpaquePointer)
        
        return addressPointer.memory
    }
}

// MARK: - Darwin Stubs

#if os(OSX) || os(iOS)
    
    func btd_adapter_unref(adapter: COpaquePointer) { stub() }
    
    func btd_adapter_get_default(_: Void) -> COpaquePointer { stub() }
    
    func adapter_find(address: COpaquePointer) -> COpaquePointer { stub() }
    
    func adapter_find_by_id(id: CInt) -> COpaquePointer { stub() }
    
    func adapter_init(_: Void) -> CInt { stub() }
    
    func adapter_cleanup(_: Void) { stub() }
    
    func adapter_shutdown(_: Void) { stub() }
    
    func btd_adapter_is_default(adapter: COpaquePointer) -> CBool { stub() }
    
    func btd_adapter_get_index(adapter: COpaquePointer) -> UInt16 { stub() }
    
    func btd_adapter_get_pairable(adapter: COpaquePointer) -> CBool { stub() }
    
    func btd_adapter_get_powered(adapter: COpaquePointer) -> CBool { stub() }
    
    func btd_adapter_get_connectable(adapter: COpaquePointer) -> CBool { stub() }
    
    func btd_adapter_get_database(adapter: COpaquePointer) -> COpaquePointer { stub() }
    
    func btd_adapter_get_class(adapter: COpaquePointer) -> UInt32 { stub() }
    
    func btd_adapter_get_name(adapter: COpaquePointer) -> UnsafePointer<CChar> { stub() }
    
    func adapter_get_path(adapter: COpaquePointer) -> UnsafePointer<CChar> { stub() }
    
    func btd_adapter_get_address(adapter: COpaquePointer) -> COpaquePointer { stub() }
    
    func adapter_set_name(adapter: COpaquePointer, _ name: UnsafePointer<CChar>) -> CInt { stub() }
    
    func btd_adapter_set_class(adapter: COpaquePointer, _ major: UInt8, _ minor: UInt8) { stub() }
    
    func btd_le_connect_before_pairing(_: Void) -> CBool { stub() }
    
    func btd_adapter_gatt_server_start(adapter: COpaquePointer) -> CInt { stub() }
    
    func btd_adapter_gatt_server_stop(adapter: COpaquePointer) { stub() }
    
#endif