# ``BluetoothLinux``

Pure Swift Bluetooth Stack for Linux.

## Overview

Provides a variety of APIs for interacting with different Sockets and IOCTL that Linux provides for Bluetooth.

This library does not require the official [BlueZ](https://www.bluez.org) userland library, instead it communicates directly with the Linux kernel Bluetooth subsystem. 

## Topics

### Bluetooth Linux subsystem

- ``BluetoothSocketProtocol``
- ``BluetoothSocketAddress``
- ``BluetoothSocketOption``
- ``AddressType``
- ``LinkMode``

### Host Controller Interface

- ``HostController``
- ``HostControllerIO``
- ``HCISocketAddress``
- ``HCISocketOption``
- ``HCIBusType``
- ``HCIControllerType``
- ``HCIChannel``
- ``HCIDeviceOptions``
- ``HCIDeviceEvent``
- ``HCIDeviceFlag``
- ``HCIPacketType``

### L2CAP

- ``L2CAPSocket``
- ``L2CAPSocketAddress``
- ``L2CAPSocketOption``

### RFCOMM

- ``RFCOMMIO``
- ``RFCOMMSocket``
- ``RFCOMMSocketAddress``
- ``RFCOMMSocketOption``
- ``RFCOMMDevice``
- ``RFCOMMState``
- ``RFCOMMFlag``
- ``RFCOMMLinkMode``

### SCO

- ``SCOSocket``

### HIDP

- ``HIDPIO``

### CMTP

- ``CMTPIO``

### BNEP

- ``BNEPIO``
