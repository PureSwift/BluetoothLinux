# Ownership audit

What each exported symbol returns, who frees it, and how long it lives.

This table has to be filled in **before** a symbol is implemented, not
after: the return-value conventions in `libbluetooth` are not uniform,
and guessing produces leaks or double frees that no type checker
catches. Three conventions are already known to coexist:

- Caller-owned heap: `batostr` returns an 18-byte `bt_malloc` buffer the
  caller releases with `bt_free`; `strtoba` likewise.
- Caller-provided buffer: `ba2str`, `ba2strlc`, `ba2oui` and
  `bt_uuid_to_string` write into a buffer the caller supplies and return
  a length (or, for the last, a status).
- Static lifetime: `bt_compidtostr` returns a pointer into static
  storage that must never be freed. The `hci_*tostr` family is mixed —
  each one needs checking individually.

And two distinct error conventions:

- The UUID family returns `0` on success and `-EINVAL` on failure, with
  `errno` untouched. `bt_uuid16_cmp` inverts even that: `1` for equal,
  `0` for not equal *and* for a NULL or non-16-bit argument.
- The socket family returns `-1` and sets `errno`.

## Status

| Family | Symbols | Audited |
|---|---:|---|
| `bluetooth.c` | 17 | ✅ complete — implemented in PureSwift/Bluetooth |
| `bt_uuid_*` | 10 | ✅ complete — implemented in PureSwift/Bluetooth |
| `hci.c` | 101 | ❌ not started |
| `sdp.c` | 100 | ❌ not started |

## bluetooth.c

| Symbol | Returns | Who frees | Lifetime |
|---|---|---|---|
| `baswap` | `void` | — | writes through `dst` |
| `batostr` | `char *` (18 bytes) | caller, via `bt_free` | heap |
| `strtoba` | `bdaddr_t *` | caller, via `bt_free` | heap |
| `ba2str` | `int` (always 17) | — | writes into caller buffer, ≥18 bytes |
| `ba2strlc` | `int` (always 17) | — | writes into caller buffer, ≥18 bytes |
| `str2ba` | `int` (`0` / `-1`) | — | writes through `ba`; zeroes it on failure |
| `ba2oui` | `int` (always 8) | — | writes into caller buffer, ≥9 bytes |
| `bachk` | `int` (`0` / `-1`) | — | — |
| `baprintf` | `int` (chars written) | — | — |
| `bafprintf` | `int` (chars written) | — | — |
| `basprintf` | `int` (chars written) | — | writes into caller buffer, unbounded |
| `basnprintf` | `int` (chars *needed*) | — | writes into caller buffer, bounded |
| `bt_malloc` | `void *` | caller, via `bt_free` | heap |
| `bt_malloc0` | `void *` (zeroed) | caller, via `bt_free` | heap |
| `bt_free` | `void` | — | accepts NULL |
| `bt_error` | `int` (errno value) | — | — |
| `bt_compidtostr` | `const char *` | **nobody** | static |

Note `basprintf` writes without a bound (the reference passes
`(~0U) >> 1` as the size) and `basnprintf` returns the length the
formatted string *would* have needed, not the length written — both
inherited straight from `vsnprintf`.

## hci.c

Not yet audited. 101 symbols. The `hci_*tostr` family is the part that
needs the most care: the return lifetimes are mixed within it.

## sdp.c

Not yet audited. 100 symbols, and the highest-risk group in the port:
`sdp_data_alloc` / `sdp_data_free` / `sdp_seq_alloc` and the intrusive
`sdp_list_t` are not really an API but an ownership contract callers
depend on, including recursive-free semantics. A defensible fallback is
to keep the reference allocator and list code as vendored C and move
only the codec to Swift.
