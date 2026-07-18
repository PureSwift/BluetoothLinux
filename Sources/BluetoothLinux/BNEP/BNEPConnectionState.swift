//
//  BNEPConnectionState.swift
//  BluetoothLinux
//

/// BNEP connection state.
public enum BNEPConnectionState: UInt16, CaseIterable, Sendable {

    case unknown            = 0x00
    case connected          = 0x01
    case open               = 0x02
    case bound              = 0x03
    case listening          = 0x04
    case connecting         = 0x05
    case connecting2        = 0x06
    case config             = 0x07
    case disconnecting      = 0x08
    case closed             = 0x09
}
