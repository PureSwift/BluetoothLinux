//
//  DeviceList.swift
//  
//
//  Created by Alsey Coleman Miller on 16/10/21.
//

import Bluetooth
import SystemPackage
import Socket

public extension HostControllerIO {
    
    /// HCI Device List 
    struct DeviceList: IOControlValue {
        
        @_alwaysEmitIntoClient
        public static var id: HostControllerIO { .getDeviceList }
        
        @usableFromInline
        internal private(set) var bytes: CInterop.HCIDeviceList
        
        @usableFromInline
        internal init(_ bytes: CInterop.HCIDeviceList) {
            self.bytes = bytes
        }
        
        public init(request count: Int = CInterop.HCIDeviceList.capacity) {
            self.init(.request(count: numericCast(count)))
        }
        
        public mutating func withUnsafeMutablePointer<Result>(_ body: (UnsafeMutableRawPointer) throws -> (Result)) rethrows -> Result {
            try Swift.withUnsafeMutableBytes(of: &bytes) { buffer in
                try body(buffer.baseAddress!)
            }
        }
    }
}

// MARK: - CustomStringConvertible

extension HostControllerIO.DeviceList: CustomStringConvertible, CustomDebugStringConvertible {
    
    public var description: String {
        return _buildDescription()
    }
    
    public var debugDescription: String {
        return description
    }
}

// MARK: - RandomAccessCollection

extension HostControllerIO.DeviceList: RandomAccessCollection {
    
    public func makeIterator() -> IndexingIterator<HostControllerIO.DeviceList> {
        return IndexingIterator(_elements: self)
    }
    
    public subscript (index: Int) -> Element {
        return Element(bytes[index])
    }
    
    public var count: Int {
        return bytes.count
    }
    
    /// The start `Index`.
    public var startIndex: Int {
        return 0
    }
    
    /// The end `Index`.
    ///
    /// This is the "one-past-the-end" position, and will always be equal to the `count`.
    public var endIndex: Int {
        return count
    }
    
    public func index(before i: Int) -> Int {
        return i - 1
    }
    
    public func index(after i: Int) -> Int {
        return i + 1
    }
    
    public subscript(bounds: Range<Int>) -> Slice<HostControllerIO.DeviceList> {
        return Slice<HostControllerIO.DeviceList>(base: self, bounds: bounds)
    }
}

// MARK: - Supporting Types

public extension HostControllerIO.DeviceList {
    
    /// HCI Device
    struct Element: Equatable, Hashable {
        
        public let id: HostController.ID
        
        public let options: HCIDeviceOptions
        
        @usableFromInline
        internal init(_ bytes: CInterop.HCIDeviceList.Element) {
            self.id = .init(rawValue: bytes.id)
            self.options = .init(rawValue: bytes.options)
        }
    }
}

// MARK: - File Descriptor

internal extension SocketDescriptor {
    
    /// List all HCI devices.
    @usableFromInline
    func deviceList(count: Int = CInterop.HCIDeviceList.capacity) throws -> HostControllerIO.DeviceList {
        var deviceList = HostControllerIO.DeviceList(request: count)
        try inputOutput(&deviceList)
        return deviceList
    }
}

// MARK: - Host Controller

public extension HostController {
    
    /// Get device information.
    static func deviceList(count: Int = CInterop.HCIDeviceList.capacity) throws -> HostControllerIO.DeviceList {
        let fileDescriptor = try SocketDescriptor.bluetooth(.hci, flags: [.closeOnExec])
        return try fileDescriptor.closeAfter {
            try fileDescriptor.deviceList(count: count)
        }
    }
}
