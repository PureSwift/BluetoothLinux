##
##  CMakeLists.txt
##  BluetoothLinux
##
##  Builds `libbluetooth.so.3` — a drop-in replacement for the shared
##  library BlueZ installs, implemented in Swift.
##
##  SwiftPM drives development and the test suites; CMake exists because
##  soname, symbol versioning and install name are not expressible in
##  `Package.swift`.
##
##  Phase 0's deliverable is a library that loads, resolves every one of
##  the 218 symbols the reference exports, and aborts loudly on every
##  call that is not implemented yet (see scripts/gen_stubs.py). Each
##  subsequent phase moves names from `scripts/symbols.txt` into
##  `scripts/implemented.txt` and the stubs disappear.
##
##  Replacing this library cannot break the Bluetooth stack itself:
##  nothing in the `bluez` package links it — bluetoothd, bluetoothctl,
##  btmon, hciconfig and sdptool all statically link
##  libbluetooth-internal.a. It exists solely for third-party consumers.
##  The corollary is that there is no "run bluetoothctl and see" smoke
##  test, which is why Conformance/ matters.
##
##  The Ninja generator is required — CMake does not support the Swift
##  language with Makefiles.
##
##  Usage:
##      cmake -B build -G Ninja -DCMAKE_BUILD_TYPE=Release \
##          -DBLUETOOTH_PACKAGE_PATH=../Bluetooth
##      cmake --build build
##      cmake --build build --target check-exports
##      cmake --install build --prefix /usr/local
##

cmake_minimum_required(VERSION 3.26)

if(NOT CMAKE_GENERATOR MATCHES "Ninja")
    message(FATAL_ERROR
        "The Ninja generator is required for Swift targets; "
        "re-run with -G Ninja.")
endif()

project(BluetoothLinuxABI
    VERSION 3.19.15
    DESCRIPTION "Swift implementation of the BlueZ libbluetooth ABI"
    LANGUAGES C Swift)

# Checked after project(), which is what sets CMAKE_SYSTEM_NAME.
if(NOT CMAKE_SYSTEM_NAME STREQUAL "Linux")
    message(FATAL_ERROR
        "libbluetooth.so.3 is a Linux library; this build is only "
        "supported on Linux.")
endif()

# ---------------------------------------------------------------------
# Options
# ---------------------------------------------------------------------

# Debian 5.85-4 ships libbluetooth.so.3.19.15 (libtool -version-info
# 22:15:19); master is heading to .3.19.16. The soname is what consumers
# actually bind to.
set(LIBBLUETOOTH_SOVERSION 3)
set(LIBBLUETOOTH_VERSION 3.19.15)

option(BLUETOOTH_ABI_STATIC_STDLIB
    "Statically link the Swift runtime into the shared library" OFF)

option(BLUETOOTH_ABI_INSTALL_HEADERS
    "Install the vendored BlueZ headers under <prefix>/include/bluetooth" ON)

# The Swift implementations of the non-socket half live in
# PureSwift/Bluetooth. Point this at a checkout of it.
set(BLUETOOTH_PACKAGE_PATH "${CMAKE_CURRENT_SOURCE_DIR}/../Bluetooth"
    CACHE PATH "Path to a PureSwift/Bluetooth checkout")

set(CMAKE_C_STANDARD 11)
set(CMAKE_C_STANDARD_REQUIRED ON)
set(CMAKE_POSITION_INDEPENDENT_CODE ON)

if(NOT CMAKE_BUILD_TYPE AND NOT CMAKE_CONFIGURATION_TYPES)
    set(CMAKE_BUILD_TYPE Release CACHE STRING "" FORCE)
endif()

include(GNUInstallDirs)

find_package(Python3 COMPONENTS Interpreter REQUIRED)

# ---------------------------------------------------------------------
# Generated sources
# ---------------------------------------------------------------------
#
# Both the stub table and the version script are derived from
# scripts/symbols.txt, so the export surface has exactly one source of
# truth. They are committed as well as generated, so that a plain
# `swift build` sees the same files.

set(LIBBLUETOOTH_STUBS
    "${CMAKE_CURRENT_SOURCE_DIR}/Sources/CBluetoothLinuxABI/gen/cbt_stubs.c")
set(LIBBLUETOOTH_VERSION_SCRIPT
    "${CMAKE_CURRENT_SOURCE_DIR}/cmake/libbluetooth.map")

add_custom_command(
    OUTPUT "${LIBBLUETOOTH_STUBS}"
    COMMAND "${Python3_EXECUTABLE}"
            "${CMAKE_CURRENT_SOURCE_DIR}/scripts/gen_stubs.py"
    DEPENDS
        "${CMAKE_CURRENT_SOURCE_DIR}/scripts/gen_stubs.py"
        "${CMAKE_CURRENT_SOURCE_DIR}/scripts/symbols.txt"
        "${CMAKE_CURRENT_SOURCE_DIR}/scripts/implemented.txt"
    COMMENT "Generating unimplemented-symbol stubs"
    VERBATIM)

add_custom_command(
    OUTPUT "${LIBBLUETOOTH_VERSION_SCRIPT}"
           "${CMAKE_CURRENT_SOURCE_DIR}/scripts/exported.txt"
    COMMAND "${Python3_EXECUTABLE}"
            "${CMAKE_CURRENT_SOURCE_DIR}/scripts/gen_symbols.py"
    DEPENDS
        "${CMAKE_CURRENT_SOURCE_DIR}/scripts/gen_symbols.py"
        "${CMAKE_CURRENT_SOURCE_DIR}/scripts/symbols.txt"
    COMMENT "Generating the version script"
    VERBATIM)

# ---------------------------------------------------------------------
# CBluetoothLinuxABI — the C surface
# ---------------------------------------------------------------------
#
# `include/bluetooth/` holds the eleven public headers vendored verbatim
# from BlueZ; they are GPL-2.0-or-later, unlike the rest of this
# repository. See Sources/CBluetoothLinuxABI/README.md.

add_library(CBluetoothLinuxABI STATIC ${LIBBLUETOOTH_STUBS})

target_include_directories(CBluetoothLinuxABI PUBLIC
    "${CMAKE_CURRENT_SOURCE_DIR}/Sources/CBluetoothLinuxABI/include")

# ---------------------------------------------------------------------
# BluetoothLinuxABI — the Swift implementations of the C entry points
# this repository owns (currently: the HCI string converter family)
# ---------------------------------------------------------------------

file(GLOB BLUETOOTH_LINUX_ABI_SOURCES CONFIGURE_DEPENDS
    "${CMAKE_CURRENT_SOURCE_DIR}/Sources/BluetoothLinuxABI/*.swift"
    "${CMAKE_CURRENT_SOURCE_DIR}/Sources/BluetoothLinuxABI/gen/*.swift")

add_library(BluetoothLinuxABI STATIC ${BLUETOOTH_LINUX_ABI_SOURCES})

set_target_properties(BluetoothLinuxABI PROPERTIES
    Swift_MODULE_NAME BluetoothLinuxABI)

target_link_libraries(BluetoothLinuxABI PUBLIC CBluetoothLinuxABI)

# ---------------------------------------------------------------------
# The non-socket half, from PureSwift/Bluetooth
# ---------------------------------------------------------------------

if(NOT EXISTS "${BLUETOOTH_PACKAGE_PATH}/CMakeLists.txt")
    message(FATAL_ERROR
        "PureSwift/Bluetooth not found at ${BLUETOOTH_PACKAGE_PATH}. "
        "Set -DBLUETOOTH_PACKAGE_PATH=<path to a checkout>.")
endif()

# Its own shared library is not wanted here — this build links the
# static archives into libbluetooth.so.3 instead.
set(BLUETOOTH_ABI_SHARED OFF CACHE BOOL "" FORCE)
set(BLUETOOTH_ABI_INSTALL_HEADERS OFF CACHE BOOL "" FORCE)

add_subdirectory("${BLUETOOTH_PACKAGE_PATH}" "${CMAKE_CURRENT_BINARY_DIR}/Bluetooth")

# ---------------------------------------------------------------------
# libbluetooth.so.3
# ---------------------------------------------------------------------

add_library(bluetooth3 SHARED cmake/empty.c)

set_target_properties(bluetooth3 PROPERTIES
    OUTPUT_NAME bluetooth
    SOVERSION ${LIBBLUETOOTH_SOVERSION}
    VERSION ${LIBBLUETOOTH_VERSION}
    # The link is driven by swiftc, and `bluetooth3` would collide with
    # the `Bluetooth` module; name the vestigial module explicitly.
    Swift_MODULE_NAME libbluetooth_abi)

# Every entry point is referenced only from outside, so the archives
# holding them must be linked whole or the linker drops the lot.
#
# The archives are named explicitly through `LINKER:` (which expands to
# `-Xlinker` here) rather than via `$<LINK_LIBRARY:WHOLE_ARCHIVE>`:
# swiftc's driver silently discards bare `.a` arguments, so the result
# would be a shared library with no symbols in it.
target_link_options(bluetooth3 PRIVATE
    "LINKER:--whole-archive"
    "LINKER:$<TARGET_FILE:BluetoothABI>"
    "LINKER:$<TARGET_FILE:BluetoothLinuxABI>"
    "LINKER:$<TARGET_FILE:CBluetooth>"
    "LINKER:$<TARGET_FILE:CBluetoothLinuxABI>"
    "LINKER:--no-whole-archive")

add_dependencies(bluetooth3 BluetoothABI BluetoothLinuxABI CBluetooth CBluetoothLinuxABI)

target_link_libraries(bluetooth3 PRIVATE Bluetooth)

# Pin the export list. Upstream exports everything and carries no
# version script; see scripts/gen_symbols.py for why we do not, and for
# the audit that owes before this list is final.
target_link_options(bluetooth3 PRIVATE
    "LINKER:--version-script=${LIBBLUETOOTH_VERSION_SCRIPT}")
set_target_properties(bluetooth3 PROPERTIES
    LINK_DEPENDS "${LIBBLUETOOTH_VERSION_SCRIPT}")

add_custom_target(generate-version-script
    DEPENDS "${LIBBLUETOOTH_VERSION_SCRIPT}")
add_dependencies(bluetooth3 generate-version-script)

if(BLUETOOTH_ABI_STATIC_STDLIB)
    # Any process loading libbluetooth.so.3 otherwise pulls in
    # libswiftCore. Measure the result against the 99 KB reference
    # package before making this the default.
    target_link_options(bluetooth3 PRIVATE "-static-stdlib")
endif()

# ---------------------------------------------------------------------
# Install
# ---------------------------------------------------------------------

configure_file(
    "${CMAKE_CURRENT_SOURCE_DIR}/cmake/bluez.pc.in"
    "${CMAKE_CURRENT_BINARY_DIR}/bluez.pc"
    @ONLY)

install(TARGETS bluetooth3
    LIBRARY DESTINATION "${CMAKE_INSTALL_LIBDIR}")

install(FILES "${CMAKE_CURRENT_BINARY_DIR}/bluez.pc"
    DESTINATION "${CMAKE_INSTALL_LIBDIR}/pkgconfig")

if(BLUETOOTH_ABI_INSTALL_HEADERS)
    # The eleven headers the reference package installs.
    file(GLOB LIBBLUETOOTH_HEADERS
        "${CMAKE_CURRENT_SOURCE_DIR}/Sources/CBluetoothLinuxABI/include/bluetooth/*.h")
    install(FILES ${LIBBLUETOOTH_HEADERS}
        DESTINATION "${CMAKE_INSTALL_INCLUDEDIR}/bluetooth")
endif()

# ---------------------------------------------------------------------
# Export verification
# ---------------------------------------------------------------------
#
# Diffs the built library's dynamic symbol table against the generated
# list. Both a missing and an extra symbol fail, so the export surface
# cannot drift silently — this is the check that makes "the library
# still resolves everything the reference did" an assertion rather than
# a hope.

add_custom_target(check-exports
    COMMAND "${CMAKE_CURRENT_SOURCE_DIR}/scripts/check-exports.sh"
            "$<TARGET_FILE:bluetooth3>"
            "${CMAKE_CURRENT_SOURCE_DIR}/scripts/exported.txt"
    DEPENDS bluetooth3 generate-version-script
    COMMENT "Checking exported symbols against scripts/exported.txt"
    VERBATIM)
