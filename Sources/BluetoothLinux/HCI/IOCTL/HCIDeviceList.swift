//
//  DeviceList.swift
//  
//
//  Created by Alsey Coleman Miller on 16/10/21.
//

import Bluetooth
import SystemPackage

public extension HostControllerIO {
    
    struct DeviceList: IOControlValue {
        
        @_alwaysEmitIntoClient
        public static var id: HostControllerIO { .getDeviceList }
        
        internal private(set) var bytes: CInterop.HCIDeviceList
        
        internal init(_ bytes: CInterop.HCIDeviceList) {
            self.bytes = bytes
        }
        
        public init() {
            self.init(.request())
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

// MARK: - CustomStringConvertible

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
        
        internal init(_ bytes: CInterop.HCIDeviceList.Element) {
            self.id = .init(rawValue: bytes.id)
            self.options = .init(rawValue: bytes.options)
        }
    }
}

// MARK: - File Descriptor

internal extension FileDescriptor {
    
    /// List all HCI devices.
    @usableFromInline
    func deviceList() throws -> HostControllerIO.DeviceList {
        var deviceList = HostControllerIO.DeviceList()
        try inputOutput(&deviceList)
        return deviceList
    }
}
