# Command Line Tools

This package includes command line tools for interacting with Bluetooth controllers on Linux,
built on `BluetoothLinux` and the [Bluetooth](https://github.com/PureSwift/Bluetooth) protocol stack.
Most commands require root privileges.

## hcitool

Configure Bluetooth connections and query controller state.

- `hcitool dev` — list local Bluetooth controllers (default).
- `hcitool inq` — inquire remote devices (classic Bluetooth inquiry).
- `hcitool lescan` — scan for Bluetooth Low Energy devices, decoding the advertised local name.

## hciconfig

Configure local Bluetooth controllers.

- `hciconfig list` — print information for all local controllers (default).
- `hciconfig up hci0` — open and initialize a controller.
- `hciconfig down hci0` — close a controller.

## gatttool

GATT client for Bluetooth Low Energy peripherals. All subcommands take
`-b <address>` for the remote device, `-r` if it uses a random address,
`-i hci0` to select a controller, and `-v` for verbose logging.

- `gatttool primary` — discover all primary services.
- `gatttool characteristics` — discover all characteristics.
- `gatttool read -a 0x0021` / `gatttool read -u 2A00` — read a characteristic value by handle or UUID.
- `gatttool write -a 0x0021 0x0100` — write a characteristic value (`--no-response` for write without response).
- `gatttool notify -a 0x0021` — subscribe to notifications and listen until interrupted.

## gattserver

Advertise and serve a demo GATT database (Device Information and Battery services).

- `gattserver --name MyDevice` — advertise with the given local name and accept connections.

## beacon

Broadcast Bluetooth Low Energy beacons.

- `beacon ibeacon <uuid> --major 1 --minor 2 --rssi -59` — advertise as an iBeacon.
- `beacon stop` — stop advertising.

## Roadmap

Planned functionality, in rough priority order:

- Connection info commands (`hcitool con`, `rssi`, `lq`) — requires Swift wrappers for the
  connection list, connection info, and authentication info ioctls (identifiers already defined
  in `HostControllerIO`).
- Additional `hciconfig` commands (auth, encrypt, packet type, link policy, block list) over the
  remaining defined ioctls.
- Remote name request for classic devices.
- L2CAP echo ping — requires a raw (`SOCK_RAW`) L2CAP socket.
- Management API socket (`HCI_CHANNEL_CONTROL`) for modern adapter control
  (power, pairing, discoverable, bonding).
- Monitor channel and btsnoop capture for packet logging.
- ATT over BR/EDR (PSM 31) and Enhanced ATT (PSM 0x27).
