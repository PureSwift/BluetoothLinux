//
//  Mocking.swift
//  BluetoothLinux
//
//  Syscall mocking support, modeled after Swift System's
//  `Sources/System/Internals/Mocking.swift`.
//
//  Mocking is contextual, accessible through `MockingDriver.withMockingEnabled`.
//  Mocking state, including whether it is enabled, is stored in thread-local
//  storage. Mocking is only compiled into debug builds (`ENABLE_MOCKING`),
//  so release builds pay no runtime overhead.
//

#if ENABLE_MOCKING
#if canImport(Glibc)
import Glibc
#elseif canImport(Darwin)
import Darwin
#endif

internal struct Trace {

    internal struct Entry: Equatable, Hashable {

        internal var name: String
        internal var arguments: [AnyHashable]

        internal init(name: String, _ arguments: [AnyHashable]) {
            self.name = name
            self.arguments = arguments
        }
    }

    private var entries: [Entry] = []
    private var firstEntry: Int = 0

    internal var isEmpty: Bool { firstEntry >= entries.count }

    internal mutating func dequeue() -> Entry? {
        guard !self.isEmpty else { return nil }
        defer { firstEntry += 1 }
        return entries[firstEntry]
    }

    fileprivate mutating func add(_ e: Entry) {
        entries.append(e)
    }
}

internal enum ForceErrno: Equatable {
    case none
    case always(errno: CInt)
    case counted(errno: CInt, count: Int)
}

// Provide access to the driver, context, and trace stack of mocking
internal final class MockingDriver {

    /// Record syscalls and their arguments
    internal var trace = Trace()

    /// Mock errors inside syscalls
    internal var forceErrno = ForceErrno.none

    /// Handler for mocked `ioctl()` calls, invoked after `forceErrno` is
    /// applied. Use it to populate the request's out-parameter (the same
    /// pointer the kernel would write to) and choose the return value; a
    /// handler returning -1 is responsible for setting `errno`. When `nil`,
    /// mocked calls succeed without touching the request.
    internal var ioctlHandler: ((_ fd: CInt, _ request: CUnsignedLong, _ pointer: UnsafeMutableRawPointer?) -> CInt)? = nil
}

private let driverKey: pthread_key_t = {
    var raw = pthread_key_t()
    guard 0 == pthread_key_create(&raw, nil) else {
        fatalError("Unable to create TLS key")
    }
    return raw
}()

internal var currentMockingDriver: MockingDriver? {
    guard let rawPtr = pthread_getspecific(driverKey) else { return nil }
    return Unmanaged<MockingDriver>.fromOpaque(rawPtr).takeUnretainedValue()
}

extension MockingDriver {

    /// Enables mocking for the duration of `f` with a clean trace queue.
    /// Restores prior mocking status and trace queue after execution.
    internal static func withMockingEnabled<R>(
        _ f: (MockingDriver) throws -> R
    ) rethrows -> R {
        let priorMocking = currentMockingDriver
        let driver = MockingDriver()

        defer {
            if let object = priorMocking {
                pthread_setspecific(driverKey, Unmanaged.passUnretained(object).toOpaque())
            } else {
                pthread_setspecific(driverKey, nil)
            }
            _fixLifetime(driver)
        }

        pthread_setspecific(driverKey, Unmanaged.passUnretained(driver).toOpaque())
        return try f(driver)
    }

    internal static var enabled: Bool { mockingEnabled }
}
#endif // ENABLE_MOCKING

@inline(__always)
internal var mockingEnabled: Bool {
    // Fast constant-foldable check for release builds
    #if ENABLE_MOCKING
    return currentMockingDriver != nil
    #else
    return false
    #endif
}

#if ENABLE_MOCKING
internal func _mockIOCTL(
    _ fd: CInt,
    _ request: CUnsignedLong,
    _ pointer: UnsafeMutableRawPointer?,
    arguments: [AnyHashable]
) -> CInt {
    precondition(mockingEnabled)
    guard let driver = currentMockingDriver else {
        fatalError("Mocking requested from non-mocking context")
    }
    driver.trace.add(Trace.Entry(name: "ioctl", arguments))

    switch driver.forceErrno {
    case .none:
        break
    case .always(let e):
        errno = e
        return -1
    case .counted(let e, let count):
        assert(count >= 1)
        errno = e
        driver.forceErrno = count > 1 ? .counted(errno: e, count: count - 1) : .none
        return -1
    }

    if let handler = driver.ioctlHandler {
        return handler(fd, request, pointer)
    }
    return 0
}
#endif // ENABLE_MOCKING
