//
//  Error.swift
//  
//
//  Created by Alsey Coleman Miller on 27/10/21.
//

import SystemPackage
import BluetoothHCI

public extension Errno {
    
    init(_ error: HCIError) {
        switch error {
        case .unknownCommand:
            self = .badMessage // EBADRQC
        case .noConnection:
            self = .socketNotConnected
        case .hardwareFailure:
            self = .ioError
        case .pageTimeout:
            self = .hostIsDown
        case .authenticationFailure:
            self = .permissionDenied
        case .keyMissing:
            self = .invalidArgument
        case .memoryFull:
            self = .noMemory
        case .connectionTimeout:
            self = .timedOut
        case .maxConnections,
            .maxSCOConnections:
            self = .tooManyLinks;
        case .aclConnectionExists:
            self = .alreadyInProcess;
        case .commandDisallowed,
             .differentTransactionCollision,
             .roleSwitchPending:
            self = .resourceBusy;
        case .rejectedLimitedResources,
            .rejectedAddress,
            .qosRejected:
            self = .connectionRefused;
        case .hostTimeout:
            self = .timedOut;
        case .unsupportedFeature,
         .requestedQoSNotSupported,
         .pairingWithUnitKeyNotSupported,
         .channelClassificationNotSupported,
         .unsupportedLMPParameterValue,
         .parameterOutOfMandatoryRange,
         .qosUnacceptableParameter:
            self = .notSupportedOnSocket;
        case .invalidParameters,
            .reservedSlotViolation:
            self = .invalidArgument;
        case .remoteUserEndedConnection,
          .remoteLowResources,
          .remotePowerOff:
            self = .connectionReset;
        case .connectionTerminated:
            self = .connectionAbort
        case .repeatedAttempts:
            self = .tooManySymbolicLinkLevels
        case .rejectedSecurity,
            .pairingNotAllowed,
            .insufficientSecurity:
            self = .permissionDenied;
        case .unsupportedRemoteFeature:
            self = .protocolNotSupported;
        case .scoOffsetRejected:
            self = .connectionRefused;
        case .unknownLMPPDU,
            .invalidLMPParameters,
          .lmpErrorTransactionCollision,
          .lmpPDUNotAllowed,
          .encryptionModeNotAcceptable:
            self = .protocolError;
        default:
            self = .noFunction;
        }
    }
}
