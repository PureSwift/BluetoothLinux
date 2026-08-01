//
//  HCIStrings.swift
//  BluetoothLinux
//
//  Swift implementations of the `hci_*tostr`/`hci_strto*` (and
//  `lmp_*`/`pal_*`) string converter family, bound to the declarations
//  in the vendored `hci_lib.h`. The lookup tables themselves are
//  generated (see `gen/HCITables.swift`) from BlueZ's own `hci_map`
//  arrays, to avoid transcription errors across the largest of them
//  (232 HCI command names).
//
//  One deliberate deviation from the reference: `hci_lmtostr` mallocs
//  a fixed 50-byte buffer for a "PERIPHERAL " prefix concatenated with
//  `hci_bit2str`'s (up to 120-byte) result — with enough link-mode
//  bits set simultaneously, the reference overflows its own buffer.
//  This is a real bug, not a documented contract; this implementation
//  allocates enough space for the actual output instead of reproducing
//  the overflow.
//

import CBluetoothLinuxABI

// MARK: - Table lookup helpers (BlueZ's hci_bit2str/hci_str2bit/hci_uint2str/hci_str2uint)

/// `static char *hci_bit2str(const hci_map *m, unsigned int val)`
///
/// Every set bit's name, space-separated, in table order. Returns an
/// empty (not NULL) string when no bits match, matching the reference.
private func bit2str(_ table: [(name: String, value: UInt32)], _ val: UInt32) -> UnsafeMutablePointer<CChar> {
    var result = ""
    for entry in table where entry.value & val != 0 {
        result += entry.name
        result += " "
    }
    return strdup(result)
}

/// `static int hci_str2bit(const hci_map *map, char *str, unsigned int *val)`
///
/// Comma-separated, case-insensitive; ORs every matching entry's bits
/// into `*val`. Returns whether anything matched.
private func str2bit(_ table: [(name: String, value: UInt32)], _ str: UnsafePointer<CChar>?) -> (matched: Bool, value: UInt32) {
    guard let str else { return (false, 0) }
    var value: UInt32 = 0
    var matched = false
    for token in String(cString: str).split(separator: ",") {
        let token = trimmed(token)
        for entry in table where entry.name.lowercased() == token.lowercased() {
            value |= entry.value
            matched = true
        }
    }
    return (matched, value)
}

/// `static char *hci_uint2str(const hci_map *m, unsigned int val)`
///
/// Exact match; empty (not NULL) string when nothing matches.
private func uint2str(_ table: [(name: String, value: UInt32)], _ val: UInt32) -> UnsafeMutablePointer<CChar> {
    for entry in table where entry.value == val {
        return strdup(entry.name)
    }
    return strdup("")
}

/// `static int hci_str2uint(const hci_map *map, char *str, unsigned int *val)`
private func str2uint(_ table: [(name: String, value: UInt32)], _ str: UnsafePointer<CChar>?) -> (matched: Bool, value: UInt32) {
    guard let str else { return (false, 0) }
    let token = String(cString: str)
    for candidate in token.split(separator: ",") {
        let candidate = trimmed(candidate)
        for entry in table where entry.name.lowercased() == candidate.lowercased() {
            return (true, entry.value)
        }
    }
    return (false, 0)
}

/// Strips leading/trailing spaces and tabs — a Foundation-free stand-in
/// for `CharacterSet.whitespaces`-based trimming.
private func trimmed(_ substring: Substring) -> Substring {
    var result = substring
    while let first = result.first, first == " " || first == "\t" { result.removeFirst() }
    while let last = result.last, last == " " || last == "\t" { result.removeLast() }
    return result
}

// MARK: - Static-lifetime strings (const char *, never freed)

private nonisolated(unsafe) let staticStrings: [String: UnsafePointer<CChar>] = [
    "Virtual": staticCString("Virtual"),
    "USB": staticCString("USB"),
    "PCCARD": staticCString("PCCARD"),
    "UART": staticCString("UART"),
    "RS232": staticCString("RS232"),
    "PCI": staticCString("PCI"),
    "SDIO": staticCString("SDIO"),
    "SPI": staticCString("SPI"),
    "I2C": staticCString("I2C"),
    "SMD": staticCString("SMD"),
    "VIRTIO": staticCString("VIRTIO"),
    "IPC": staticCString("IPC"),
    "Unknown": staticCString("Unknown"),
    "Primary": staticCString("Primary"),
    "AMP": staticCString("AMP")
]

private func staticCString(_ string: String) -> UnsafePointer<CChar> {
    UnsafePointer(strdup(string)!)
}

// MARK: - Bus / controller type

/// `const char *hci_bustostr(int bus)`
@c(hci_bustostr)
public func hci_bustostr(_ bus: Int32) -> UnsafePointer<CChar>? {
    let name: String
    switch bus {
    case Int32(HCI_VIRTUAL): name = "Virtual"
    case Int32(HCI_USB): name = "USB"
    case Int32(HCI_PCCARD): name = "PCCARD"
    case Int32(HCI_UART): name = "UART"
    case Int32(HCI_RS232): name = "RS232"
    case Int32(HCI_PCI): name = "PCI"
    case Int32(HCI_SDIO): name = "SDIO"
    case Int32(HCI_SPI): name = "SPI"
    case Int32(HCI_I2C): name = "I2C"
    case Int32(HCI_SMD): name = "SMD"
    case Int32(HCI_VIRTIO): name = "VIRTIO"
    case Int32(HCI_IPC): name = "IPC"
    default: name = "Unknown"
    }
    return staticStrings[name]
}

/// `const char *hci_dtypetostr(int type)`
@c(hci_dtypetostr)
public func hci_dtypetostr(_ type: Int32) -> UnsafePointer<CChar>? {
    hci_bustostr(type & 0x0f)
}

/// `char *hci_typetostr(int type)`
@c(hci_typetostr)
public func hci_typetostr(_ type: Int32) -> UnsafeMutablePointer<CChar>? {
    let name: String
    switch type {
    case Int32(HCI_PRIMARY): name = "Primary"
    case Int32(HCI_AMP): name = "AMP"
    default: name = "Unknown"
    }
    return UnsafeMutablePointer(mutating: staticStrings[name])
}

// MARK: - Device flags

/// `char *hci_dflagstostr(uint32_t flags)`
@c(hci_dflagstostr)
public func hci_dflagstostr(_ flags: UInt32) -> UnsafeMutablePointer<CChar>? {
    var result = ""
    if flags & (1 << UInt32(HCI_UP)) == 0 {
        result += "DOWN "
    }
    for entry in hciDeviceFlagsMap where flags & (1 << entry.value) != 0 {
        result += entry.name
        result += " "
    }
    return strdup(result)
}

// MARK: - Packet types

/// `char *hci_ptypetostr(unsigned int ptype)`
@c(hci_ptypetostr)
public func hci_ptypetostr(_ ptype: UInt32) -> UnsafeMutablePointer<CChar>? {
    bit2str(hciPacketTypeMap, ptype)
}

/// `int hci_strtoptype(char *str, unsigned int *val)`
@c(hci_strtoptype)
public func hci_strtoptype(_ str: UnsafeMutablePointer<CChar>?, _ val: UnsafeMutablePointer<UInt32>?) -> Int32 {
    let (matched, value) = str2bit(hciPacketTypeMap, str)
    val?.pointee = value
    return matched ? 1 : 0
}

/// `char *hci_scoptypetostr(unsigned int ptype)`
@c(hci_scoptypetostr)
public func hci_scoptypetostr(_ ptype: UInt32) -> UnsafeMutablePointer<CChar>? {
    bit2str(hciSCOPacketTypeMap, ptype)
}

/// `int hci_strtoscoptype(char *str, unsigned int *val)`
@c(hci_strtoscoptype)
public func hci_strtoscoptype(_ str: UnsafeMutablePointer<CChar>?, _ val: UnsafeMutablePointer<UInt32>?) -> Int32 {
    let (matched, value) = str2bit(hciSCOPacketTypeMap, str)
    val?.pointee = value
    return matched ? 1 : 0
}

// MARK: - Link policy

/// `char *hci_lptostr(unsigned int lp)`
@c(hci_lptostr)
public func hci_lptostr(_ lp: UInt32) -> UnsafeMutablePointer<CChar>? {
    bit2str(hciLinkPolicyMap, lp)
}

/// `int hci_strtolp(char *str, unsigned int *val)`
@c(hci_strtolp)
public func hci_strtolp(_ str: UnsafeMutablePointer<CChar>?, _ val: UnsafeMutablePointer<UInt32>?) -> Int32 {
    let (matched, value) = str2bit(hciLinkPolicyMap, str)
    val?.pointee = value
    return matched ? 1 : 0
}

// MARK: - Link mode

/// `char *hci_lmtostr(unsigned int lm)`
///
/// See the file-level note: allocates enough space for the real
/// output instead of reproducing the reference's fixed-buffer overflow.
@c(hci_lmtostr)
public func hci_lmtostr(_ lm: UInt32) -> UnsafeMutablePointer<CChar>? {
    var result = ""
    if lm & UInt32(HCI_LM_MASTER) == 0 {
        result += "PERIPHERAL "
    }
    for entry in hciLinkModeMap where entry.value & lm != 0 {
        result += entry.name
        result += " "
    }
    return strdup(result)
}

/// `int hci_strtolm(char *str, unsigned int *val)`
@c(hci_strtolm)
public func hci_strtolm(_ str: UnsafeMutablePointer<CChar>?, _ val: UnsafeMutablePointer<UInt32>?) -> Int32 {
    var (matched, value) = str2bit(hciLinkModeMap, str)
    // Deprecated name, kept for compatibility.
    if let str, String(cString: str).lowercased().contains("master") {
        matched = true
        value |= UInt32(HCI_LM_MASTER)
    }
    val?.pointee = value
    return matched ? 1 : 0
}

// MARK: - Commands

/// `char *hci_cmdtostr(unsigned int cmd)`
@c(hci_cmdtostr)
public func hci_cmdtostr(_ cmd: UInt32) -> UnsafeMutablePointer<CChar>? {
    uint2str(hciCommandsMap, cmd)
}

/// `char *hci_commandstostr(const uint8_t *commands, const char *pref, int width)`
///
/// Every supported-commands bit set in `commands` (a 64-byte bitmap,
/// per the HCI spec), quoted and space-separated, wrapped to `width`
/// columns with `pref` repeated at the start of each line.
///
/// BlueZ's `lib/bluetooth/hci.c` (as of 5.85, the version these
/// declarations are vendored from) trims the final trailing space
/// unconditionally (`ptr[-1] = '\0'` once anything was written). The
/// installed reference on this system is BlueZ 5.82, whose compiled
/// behavior — confirmed by differential conformance — keeps it. Since
/// conformance means matching the actual deployed library, not a
/// specific source revision, the trailing space is kept here too.
@c(hci_commandstostr)
public func hci_commandstostr(
    _ commands: UnsafePointer<UInt8>?,
    _ pref: UnsafePointer<CChar>?,
    _ width: Int32
) -> UnsafeMutablePointer<CChar>? {
    guard let commands else { return nil }
    let prefix = pref.map { String(cString: $0) } ?? ""
    let maxWidth = Int(width) - 3

    var result = prefix
    var lineStart = result.count

    for entry in hciCommandsMap {
        let bit = Int(entry.value)
        guard commands[bit / 8] & (1 << (bit % 8)) != 0 else { continue }
        let piece = "'\(entry.name)' "
        if !result.isEmpty && (result.count - lineStart) + entry.name.count > maxWidth {
            result.removeLast()
            result += "\n"
            result += prefix
            lineStart = result.count
        }
        result += piece
    }
    return strdup(result)
}

// MARK: - Versions

/// `char *hci_vertostr(unsigned int ver)`
@c(hci_vertostr)
public func hci_vertostr(_ ver: UInt32) -> UnsafeMutablePointer<CChar>? {
    uint2str(hciVersionMap, ver)
}

/// `int hci_strtover(char *str, unsigned int *ver)`
@c(hci_strtover)
public func hci_strtover(_ str: UnsafeMutablePointer<CChar>?, _ ver: UnsafeMutablePointer<UInt32>?) -> Int32 {
    let (matched, value) = str2uint(hciVersionMap, str)
    if matched { ver?.pointee = value }
    return matched ? 1 : 0
}

/// `char *lmp_vertostr(unsigned int ver)`
@c(lmp_vertostr)
public func lmp_vertostr(_ ver: UInt32) -> UnsafeMutablePointer<CChar>? {
    uint2str(hciVersionMap, ver)
}

/// `int lmp_strtover(char *str, unsigned int *ver)`
@c(lmp_strtover)
public func lmp_strtover(_ str: UnsafeMutablePointer<CChar>?, _ ver: UnsafeMutablePointer<UInt32>?) -> Int32 {
    let (matched, value) = str2uint(hciVersionMap, str)
    if matched { ver?.pointee = value }
    return matched ? 1 : 0
}

/// `char *pal_vertostr(unsigned int ver)`
@c(pal_vertostr)
public func pal_vertostr(_ ver: UInt32) -> UnsafeMutablePointer<CChar>? {
    uint2str(hciPALVersionMap, ver)
}

/// `int pal_strtover(char *str, unsigned int *ver)`
@c(pal_strtover)
public func pal_strtover(_ str: UnsafeMutablePointer<CChar>?, _ ver: UnsafeMutablePointer<UInt32>?) -> Int32 {
    let (matched, value) = str2uint(hciPALVersionMap, str)
    if matched { ver?.pointee = value }
    return matched ? 1 : 0
}

// MARK: - LMP features

/// `char *lmp_featurestostr(uint8_t *features, char *pref, int width)`
@c(lmp_featurestostr)
public func lmp_featurestostr(
    _ features: UnsafeMutablePointer<UInt8>?,
    _ pref: UnsafeMutablePointer<CChar>?,
    _ width: Int32
) -> UnsafeMutablePointer<CChar>? {
    guard let features else { return nil }
    let prefix = pref.map { String(cString: $0) }
    let maxWidth = Int(width) - 1

    var result = prefix ?? ""
    var lineStart = result.count

    for (byteIndex, row) in lmpFeaturesMap.enumerated() {
        let byte = features[byteIndex]
        for entry in row where entry.value & byte != 0 {
            if (result.count - lineStart) + entry.name.count > maxWidth {
                result += "\n"
                result += prefix ?? ""
                lineStart = result.count
            }
            result += entry.name
            result += " "
        }
    }

    return strdup(result)
}
