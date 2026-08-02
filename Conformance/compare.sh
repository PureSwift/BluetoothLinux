#!/usr/bin/env bash
#
# Differential conformance: build each driver twice — once against the
# reference libbluetooth.so.3, once against ours — and diff the output.
#
# Drivers:
#   conformance_hci_strings.c   the hci_*tostr/hci_strto*, lmp_*, pal_*
#                               family (21 symbols). Exported directly
#                               by the system library, so this driver
#                               links against it as-is.
#
# The phase-1 (bluetooth.c + bt_uuid_*) and SDP drivers live in the
# PureSwift/Bluetooth checkout instead, alongside the symbols they
# cover — see Conformance/README.md.
#
# Both sides of each comparison compile against the *same* (vendored)
# headers, so the only variable is which implementation is linked.
#
# Usage:
#     SWIFTPM_BLUETOOTH_CABI=1 swift build
#     Conformance/compare.sh [path-to-libBluetoothLinuxABI.so]
#
# Environment:
#     BT_REFERENCE_LIB   path to the reference libbluetooth.so.3
#
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BUILD="${ROOT}/.build/conformance"
TRIPLE="$(swift -print-target-info | sed -n 's/.*"unversionedTriple": "\([^"]*\)".*/\1/p' | head -1)"
OURS="${1:-${ROOT}/.build/${TRIPLE}/debug/libBluetoothLinuxABI.so}"

find_reference() {
    local found
    found="$(/sbin/ldconfig -p 2>/dev/null \
        | sed -n 's/.*libbluetooth\.so\.3 (libc6[^)]*) => \(.*\)/\1/p' | head -1)"
    if [[ -n "${found}" ]]; then
        echo "${found}"
        return
    fi
    local dir
    for dir in /usr/lib/"$(uname -m)"-linux-gnu /usr/lib64 /usr/lib /lib; do
        if [[ -f "${dir}/libbluetooth.so.3" ]]; then
            echo "${dir}/libbluetooth.so.3"
            return
        fi
    done
}

REFERENCE="${BT_REFERENCE_LIB:-$(find_reference)}"

if [[ ! -f "${OURS}" ]]; then
    echo "error: ${OURS} not found; run 'SWIFTPM_BLUETOOTH_CABI=1 swift build' first" >&2
    exit 1
fi

if [[ -z "${REFERENCE}" || ! -f "${REFERENCE}" ]]; then
    echo "error: reference libbluetooth.so.3 not found; install libbluetooth3 or set BT_REFERENCE_LIB" >&2
    exit 1
fi

mkdir -p "${BUILD}"

# The drivers include <bluetooth/...>, so stage the vendored headers
# under that prefix and use them for every build.
mkdir -p "${BUILD}/include/bluetooth"
cp "${ROOT}"/Sources/CBluetoothLinuxABI/include/bluetooth/*.h "${BUILD}/include/bluetooth/"

CFLAGS=(-O0 -g -I "${BUILD}/include")
status=0

compare() {
    local name="$1" reference="$2" ours="$3"

    "${reference}" > "${BUILD}/${name}.reference.txt" 2>&1 || true
    "${ours}" > "${BUILD}/${name}.ours.txt" 2>&1 || true

    if diff -u "${BUILD}/${name}.reference.txt" "${BUILD}/${name}.ours.txt" \
            > "${BUILD}/${name}.diff.txt"; then
        echo "conformance/${name}: identical output ($(wc -l < "${BUILD}/${name}.reference.txt") lines)"
        return 0
    fi

    grep -E '^[+-]' "${BUILD}/${name}.diff.txt" | grep -vE '^(\+\+\+|---)' | sed 's/^[+-]//' \
        | sort -u > "${BUILD}/${name}.changed.txt"

    if [[ -f "${ROOT}/Conformance/known-differences.txt" ]]; then
        grep -vE '^\s*(#|$)' "${ROOT}/Conformance/known-differences.txt" | sort -u \
            > "${BUILD}/known.txt"
    else
        : > "${BUILD}/known.txt"
    fi

    comm -23 "${BUILD}/${name}.changed.txt" "${BUILD}/known.txt" \
        > "${BUILD}/${name}.unexpected.txt"

    if [[ -s "${BUILD}/${name}.unexpected.txt" ]]; then
        echo "conformance/${name}: $(wc -l < "${BUILD}/${name}.unexpected.txt") unexpected differing line(s):" >&2
        head -50 "${BUILD}/${name}.unexpected.txt" >&2
        echo "(full diff: ${BUILD}/${name}.diff.txt)" >&2
        return 1
    fi

    echo "conformance/${name}: all $(wc -l < "${BUILD}/${name}.changed.txt") differing lines are known-accepted"
}

# --- HCI string converters ----------------------------------------------

cc "${CFLAGS[@]}" -o "${BUILD}/hci_strings.reference" \
    "${ROOT}/Conformance/conformance_hci_strings.c" "${REFERENCE}"
cc "${CFLAGS[@]}" -o "${BUILD}/hci_strings.ours" \
    "${ROOT}/Conformance/conformance_hci_strings.c" "${OURS}" \
    -Wl,-rpath,"$(dirname "${OURS}")"

compare hci_strings "${BUILD}/hci_strings.reference" "${BUILD}/hci_strings.ours" || status=1

exit "${status}"
