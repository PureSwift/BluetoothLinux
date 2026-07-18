//
//  ISOQualityOfService.swift
//  BluetoothLinux
//

import Bluetooth
import SystemPackage
import Socket

public extension BluetoothSocketOption {

    /// Bluetooth Isochronous Channel Quality of Service socket option
    ///
    /// Configures the connected isochronous stream parameters of an ISO socket
    /// (`bt_iso_qos`, unicast). Must be set before the connection is established.
    struct ISOQualityOfService: Equatable, Hashable, SocketOption, Sendable {

        @_alwaysEmitIntoClient
        public static var id: BluetoothSocketOption { .isoQualityOfService }

        /// The connected isochronous group identifier (`0xFF` for unset).
        public var group: UInt8 // cig

        /// The connected isochronous stream identifier (`0xFF` for unset).
        public var stream: UInt8 // cis

        /// The sleep clock accuracy.
        public var sleepClockAccuracy: UInt8 // sca

        /// The preferred method of arranging subevents of multiple streams.
        public var packing: UInt8

        /// The format of the sent data (unframed or framed).
        public var framing: UInt8

        /// Input (receive) parameters.
        public var input: IO

        /// Output (send) parameters.
        public var output: IO

        public init(
            group: UInt8 = 0xFF,
            stream: UInt8 = 0xFF,
            sleepClockAccuracy: UInt8 = 0,
            packing: UInt8 = 0,
            framing: UInt8 = 0,
            input: IO = IO(),
            output: IO = IO()
        ) {
            self.group = group
            self.stream = stream
            self.sleepClockAccuracy = sleepClockAccuracy
            self.packing = packing
            self.framing = framing
            self.input = input
            self.output = output
        }

        public func withUnsafeBytes<Result, Error>(_ body: ((UnsafeRawBufferPointer) throws(Error) -> (Result))) rethrows -> Result where Error: Swift.Error {
            return try Swift.withUnsafeBytes(of: self) { bufferPointer in
                try body(bufferPointer)
            }
        }

        public static func withUnsafeBytes<Error>(
            _ body: (UnsafeMutableRawBufferPointer) throws(Error) -> ()
        ) rethrows -> Self where Error: Swift.Error {
            var value = self.init()
            try Swift.withUnsafeMutableBytes(of: &value, body)
            return value
        }
    }
}

public extension BluetoothSocketOption.ISOQualityOfService {

    /// Isochronous stream input/output parameters.
    ///
    /// `bt_iso_io_qos`
    struct IO: Equatable, Hashable, Sendable {

        /// SDU interval in microseconds.
        public var interval: UInt32

        /// Maximum transport latency in milliseconds.
        public var latency: UInt16

        /// Maximum SDU size in octets.
        public var sdu: UInt16

        /// PHY to use.
        public var phy: UInt8

        /// Retransmission number.
        public var retransmissionNumber: UInt8 // rtn

        public init(
            interval: UInt32 = 0,
            latency: UInt16 = 0,
            sdu: UInt16 = 0,
            phy: UInt8 = 0,
            retransmissionNumber: UInt8 = 0
        ) {
            self.interval = interval
            self.latency = latency
            self.sdu = sdu
            self.phy = phy
            self.retransmissionNumber = retransmissionNumber
        }
    }
}
