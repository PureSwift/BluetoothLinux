# Conformance

Differential conformance for `libbluetooth.so.3`: C programs compiled
twice — once against the reference library, once against ours — with the
outputs diffed and accepted deltas recorded.

Because no BlueZ binary links the shared library (`bluetoothd`,
`bluetoothctl`, `btmon`, `hciconfig` and `sdptool` all statically link
`libbluetooth-internal.a`), "nothing crashed" tells us nothing. These
programs are the only signal that the replacement behaves like the
original.

## Phase 1 — done, and it lives in PureSwift/Bluetooth

The `bluetooth.c` and `bt_uuid_*` families are implemented there, so
their conformance harness is there too: `Conformance/compare.sh` in the
Bluetooth checkout, with `conformance_address.c` and
`conformance_uuid.c`.

It can be pointed at the library this repository builds:

```
cmake --build .build/cmake
BLUEZ_SOURCE=<bluez source tree> \
    ../Bluetooth/Conformance/compare.sh .build/cmake/libbluetooth.so.3.19.15
```

## Phases 2–4 — to be added here

One driver per symbol family, following the same shape:

| Driver | Covers | Phase |
|---|---|---|
| `conformance_hci_strings.c` | `hci_*tostr`, `lmp_*`, `pal_*` | 2 |
| `conformance_hci.c` | device and command wrappers | 3 |
| `conformance_sdp_codec.c` | `sdp_gen_pdu` / `sdp_extract_pdu` / `sdp_extract_attr` | 4a |
| `conformance_sdp_session.c` | session, registration, async requests | 4b |

Two cheaper sources of coverage come first, though:

- **BlueZ's own unit tests, reused directly.** `unit/test-uuid.c`,
  `unit/test-lib.c` and `unit/test-sdp.c` link
  `libbluetooth-internal.la` today; pointing them at our library instead
  is free coverage for phases 1 and 4.
- **Fuzzing the parsers.** `bt_string_to_uuid`, `str2ba`, `bachk` and
  `sdp_extract_pdu` against random and semi-structured input, comparing
  both implementations byte for byte. `sdp_extract_pdu` is the one place
  arbitrary remote bytes reach the library.

Then an `LD_PRELOAD` substitution run against a real external consumer,
once one is identified — `bluez-cups` and the Python bindings are the
obvious candidates.
