//
//  Deque.swift
//  Deque
//
//  Created by Károly Lőrentey on 2016-01-20.
//  Copyright © 2016 Károly Lőrentey.
//

//MARK: Deque

/// A double-ended queue type. `Deque` is an `Array`-like random-access collection of arbitrary elements
/// that provides efficient insertion and deletion at both ends.
///
/// Like arrays, deques are value types with copy-on-write semantics. `Deque` allocates a single buffer for
/// element storage, using an exponential growth strategy.
///
public struct Deque<Element> {
    /// The storage for this deque.
    internal private(set) var buffer: DequeBuffer<Element>

    /// Initializes an empty deque.
    public init() {
        buffer = DequeBuffer()
    }
    /// Initializes an empty deque that is able to store at least `minimumCapacity` items without reallocating its storage.
    public init(minimumCapacity: Int) {
        buffer = DequeBuffer(capacity: minimumCapacity)
    }

    /// Initialize a new deque from the elements of any sequence.
    public init<S: Sequence where S.Iterator.Element == Element>(_ elements: S) {
        self.init(minimumCapacity: elements.underestimatedCount)
        appendContentsOf(elements)
    }

    /// Initialize a deque of `count` elements, each initialized to `repeating`.
    public init(count: Int, repeating: Element) {
        buffer = DequeBuffer(count: count, repeating: repeating)
    }
}

//MARK: Uniqueness and Capacity

extension Deque {
    /// The maximum number of items this deque can store without reallocating its storage.
    var capacity: Int { return buffer.capacity }

    private func grow(capacity: Int) -> Int {
        guard capacity > self.capacity else { return self.capacity }
        return Swift.max(capacity, 2 * self.capacity)
    }

    /// Ensure that this deque is capable of storing at least `minimumCapacity` items without reallocating its storage.
    public mutating func reserveCapacity(minimumCapacity: Int) {
        guard buffer.capacity < minimumCapacity else { return }
        if isUniquelyReferenced(&buffer) {
            buffer = buffer.realloc(minimumCapacity)
        }
        else {
            let new = DequeBuffer<Element>(capacity: minimumCapacity)
            new.insertContentsOf(buffer, at: 0)
            buffer = new
        }
    }

    internal var isUnique: Bool { mutating get { return isUniquelyReferenced(&buffer) } }

    private mutating func makeUnique() {
        self.makeUniqueWithCapacity(buffer.capacity)
    }

    private mutating func makeUniqueWithCapacity(capacity: Int) {
        guard !isUnique || buffer.capacity < capacity else { return }
        let copy = DequeBuffer<Element>(capacity: capacity)
        copy.insertContentsOf(buffer, at: 0)
        buffer = copy
    }
}

//MARK: MutableCollection

extension Deque: MutableCollection {
    public typealias Index = Int
    public typealias Generator = IndexingIterator<Deque<Element>>
    public typealias SubSequence = MutableSlice<Deque<Element>>

    /// The number of elements currently stored in this deque.
    public var count: Int { return buffer.count }
    /// The position of the first element in a non-empty deque (this is always zero).
    public var startIndex: Int { return 0 }
    /// The index after the last element in a non-empty deque (this is always the element count).
    public var endIndex: Int { return count }

    /// `true` iff this deque is empty.
    public var isEmpty: Bool { return count == 0 }

    @inline(__always)
    private func checkSubscript(index: Int) {
        precondition(index >= 0 && index < count)
    }

    // Returns or changes the element at `index`.
    public subscript(index: Int) -> Element {
        get {
            checkSubscript(index)
            return buffer[index]
        }
        set(value) {
            checkSubscript(index)
            buffer[index] = value
        }
    }
}

//MARK: ArrayLiteralConvertible

extension Deque: ArrayLiteralConvertible {
    public init(arrayLiteral elements: Element...) {
        self.buffer = DequeBuffer(capacity: elements.count)
        buffer.insertContentsOf(elements, at: 0)
    }
}

//MARK: CustomStringConvertible

extension Deque: CustomStringConvertible, CustomDebugStringConvertible {
    @warn_unused_result
    private func makeDescription(debug debug: Bool) -> String {
        var result = debug ? "\(String(reflecting: Deque.self))([" : "Deque["
        var first = true
        for item in self {
            if first {
                first = false
            } else {
                result += ", "
            }
            if debug {
                debugPrint(item, terminator: "", to: &result)
            }
            else {
                print(item, terminator: "", to: &result)
            }
        }
        result += debug ? "])" : "]"
        return result
    }

    public var description: String {
        return makeDescription(debug: false)
    }
    public var debugDescription: String {
        return makeDescription(debug: true)
    }
}

//MARK: RangeReplaceableCollection

extension Deque: RangeReplaceableCollection {
    /// Replace the given `range` of elements with `newElements`.
    ///
    /// - Complexity: O(`range.count`) if storage isn't shared with another live deque, 
    ///   and `range` is a constant distance from the start or the end of the deque; otherwise O(`count + range.count`).
    public mutating func replaceSubrange<C: Collection where C.Iterator.Element == Element>(range: Range<Int>, with newElements: C) {
        precondition(range.startIndex >= 0 && range.endIndex <= count)
        let newCount: Int = numericCast(newElements.count)
        let delta = newCount - range.count
        if isUnique && count + delta <= capacity {
            buffer.replaceRange(range, with: newElements)
        }
        else {
            let b = DequeBuffer<Element>(capacity: grow(count + delta))
            b.insertContentsOf(self.buffer, subRange: 0 ..< range.startIndex, at: 0)
            b.insertContentsOf(newElements, at: b.count)
            b.insertContentsOf(self.buffer, subRange: range.endIndex ..< count, at: b.count)
            buffer = b
        }
    }

    /// Append `newElement` to the end of this deque.
    ///
    /// - Complexity: Amortized O(1) if storage isn't shared with another live deque; otherwise O(`count`).
    public mutating func append(newElement: Element) {
        makeUniqueWithCapacity(grow(count + 1))
        buffer.append(newElement)
    }

    /// Append `newElements` to the end of this queue.
    public mutating func appendContentsOf<S: Sequence where S.Iterator.Element == Element>(newElements: S) {
        makeUniqueWithCapacity(self.count + newElements.underestimatedCount)
        var capacity = buffer.capacity
        var count = buffer.count
        var generator = newElements.makeIterator()
        var next = generator.next()
        while next != nil {
            if capacity == count {
                reserveCapacity(grow(count + 1))
                capacity = buffer.capacity
            }
            var i = buffer.bufferIndexForDequeIndex(count)
            let p = buffer.elements
            while let element = next where count < capacity {
                p.advanced(by: i).initialize(with: element)
                i += 1
                if i == capacity { i = 0 }
                count += 1
                next = generator.next()
            }
            buffer.count = count
        }
    }

    /// Insert `newElement` at index `i` into this deque.
    ///
    /// - Complexity: O(`count`). Note though that complexity is O(1) if `i` is of a constant distance from the front or end of the deque.
    public mutating func insert(newElement: Element, atIndex i: Int) {
        makeUniqueWithCapacity(grow(count + 1))
        buffer.insert(newElement, at: i)
    }

    /// Insert the contents of `newElements` into this deque, starting at index `i`.
    ///
    /// - Complexity: O(`count`). Note though that complexity is O(1) if `i` is of a constant distance from the front or end of the deque.
    public mutating func insertContentsOf<C: Collection where C.Iterator.Element == Element>(newElements: C, at i: Int) {
        makeUniqueWithCapacity(grow(count + numericCast(newElements.count)))
        buffer.insertContentsOf(newElements, at: i)
    }

    /// Remove the element at index `i` from this deque.
    ///
    /// - Complexity: O(`count`). Note though that complexity is O(1) if `i` is of a constant distance from the front or end of the deque.
    public mutating func removeAtIndex(i: Int) -> Element {
        checkSubscript(i)
        makeUnique()
        let element = buffer[i]
        buffer.removeRange(i...i)
        return element
    }

    /// Remove and return the first element from this deque.
    ///
    /// - Requires: `count > 0`
    /// - Complexity: O(1) if storage isn't shared with another live deque; otherwise O(`count`).
    public mutating func removeFirst() -> Element {
        precondition(count > 0)
        return buffer.popFirst()!
    }

    /// Remove the first `n` elements from this deque.
    ///
    /// - Requires: `count >= n`
    /// - Complexity: O(`n`) if storage isn't shared with another live deque; otherwise O(`count`).
    public mutating func removeFirst(n: Int) {
        precondition(count >= n)
        buffer.removeRange(0 ..< n)
    }

    /// Remove the first `n` elements from this deque.
    ///
    /// - Requires: `count >= n`
    /// - Complexity: O(`n`) if storage isn't shared with another live deque; otherwise O(`count`).
    public mutating func removeRange(range: Range<Int>) {
        precondition(range.startIndex >= 0 && range.endIndex <= count)
        buffer.removeRange(range)
    }

    /// Remove all elements from this deque.
    ///
    /// - Complexity: O(`count`).
    public mutating func removeAll(keepCapacity keepCapacity: Bool = false) {
        if keepCapacity {
            buffer.removeRange(0..<count)
        }
        else {
            buffer = DequeBuffer()
        }
    }
}

//MARK: Miscellaneous mutators
extension Deque {
    /// Remove and return the last element from this deque.
    ///
    /// - Requires: `count > 0`
    /// - Complexity: O(1) if storage isn't shared with another live deque; otherwise O(`count`).
    public mutating func removeLast() -> Element {
        precondition(count > 0)
        return buffer.popLast()!
    }

    /// Remove and return the last `n` elements from this deque.
    ///
    /// - Requires: `count >= n`
    /// - Complexity: O(`n`) if storage isn't shared with another live deque; otherwise O(`count`).
    public mutating func removeLast(n: Int) {
        let c = count
        precondition(c >= n)
        buffer.removeRange(c - n ..< c)
    }

    /// Remove and return the first element if the deque isn't empty; otherwise return nil.
    ///
    /// - Complexity: O(1) if storage isn't shared with another live deque; otherwise O(`count`).
    public mutating func popFirst() -> Element? {
        return buffer.popFirst()
    }

    /// Remove and return the last element if the deque isn't empty; otherwise return nil.
    ///
    /// - Complexity: O(1) if storage isn't shared with another live deque; otherwise O(`count`).
    public mutating func popLast() -> Element? {
        return buffer.popLast()
    }

    /// Prepend `newElement` to the front of this deque.
    ///
    /// - Complexity: Amortized O(1) if storage isn't shared with another live deque; otherwise O(count).
    public mutating func prepend(element: Element) {
        makeUniqueWithCapacity(grow(count + 1))
        buffer.prepend(element)
    }
}

//MARK: Equality operators

@warn_unused_result
func == <Element: Equatable>(a: Deque<Element>, b: Deque<Element>) -> Bool {
    let count = a.count
    if count != b.count { return false }
    if count == 0 || a.buffer === b.buffer { return true }

    var agen = a.makeIterator()
    var bgen = b.makeIterator()
    while let anext = agen.next() {
        let bnext = bgen.next()
        if anext != bnext { return false }
    }
    return true
}

@warn_unused_result
func != <Element: Equatable>(a: Deque<Element>, b: Deque<Element>) -> Bool {
    return !(a == b)
}

//MARK: DequeBuffer

/// Storage buffer for a deque.
final class DequeBuffer<Element>: NonObjectiveCBase {
    /// Pointer to allocated storage.
    internal private(set) var elements: UnsafeMutablePointer<Element>
    /// The capacity of this storage buffer.
    internal let capacity: Int
    /// The number of items currently in this deque.
    internal private(set) var count: Int
    /// The index of the first item.
    internal private(set) var start: Int

    internal init(capacity: Int = 16) {
        // TODO: It would be nicer if element storage was tail-allocated after this instance.
        // ManagedBuffer is supposed to do that, but ManagedBuffer is surprisingly slow. :-/
        self.elements = UnsafeMutablePointer.init(allocatingCapacity: capacity)
        self.capacity = capacity
        self.count = 0
        self.start = 0
    }

    internal convenience init(count: Int, repeating: Element) {
        self.init(capacity: count)
        let p = elements
        self.count = count
        var q = p
        let limit = p + count
        while q != limit {
            q.initialize(with: repeating)
            q += 1
        }
    }

    deinit {
        let p = self.elements
        if start + count <= capacity {
            p.advanced(by: start).deinitialize(count: count)
        }
        else {
            let c = capacity - start
            p.advanced(by: start).deinitialize(count: c)
            p.deinitialize(count: count - c)
        }
        p.deallocateCapacity(capacity)
    }

    @warn_unused_result
    internal func realloc(capacity: Int) -> DequeBuffer {
        if capacity <= self.capacity { return self }
        let buffer = DequeBuffer(capacity: capacity)
        buffer.count = self.count
        let dst = buffer.elements
        let src = self.elements
        if self.start + self.count <= self.capacity {
            dst.moveInitializeFrom(src.advanced(by: start), count: count)
        }
        else {
            let c = self.capacity - self.start
            dst.moveInitializeFrom(src.advanced(by: self.start), count: c)
            dst.advanced(by: c).moveInitializeFrom(src, count: self.count - c)
        }
        self.count = 0
        return buffer
    }


    /// Returns the storage buffer index for a deque index.
    internal func bufferIndexForDequeIndex(index: Int) -> Int {
        let i = start + index
        if i >= capacity { return i - capacity }
        return i
    }

    /// Returns the deque index for a storage buffer index.
    internal func dequeIndexForBufferIndex(i: Int) -> Int {
        if i >= start {
            return i - start
        }
        return capacity - start + i
    }

    internal var isFull: Bool { return count == capacity }

    internal subscript(index: Int) -> Element {
        get {
            assert(index >= 0 && index < count)
            let i = bufferIndexForDequeIndex(index)
            return elements.advanced(by: i).pointee
        }
        set {
            assert(index >= 0 && index < count)
            let i = bufferIndexForDequeIndex(index)
            elements.advanced(by: i).pointee = newValue
        }
    }

    internal func prepend(element: Element) {
        precondition(count < capacity)
        let i = start == 0 ? capacity - 1 : start - 1
        elements.advanced(by: i).initialize(with: element)
        self.start = i
        self.count += 1
    }

    internal func popFirst() -> Element? {
        guard count > 0 else { return nil }
        let first = elements.advanced(by: start).move()
        self.start = bufferIndexForDequeIndex(1)
        self.count -= 1
        return first
    }

    internal func append(element: Element) {
        precondition(count < capacity)
        let endIndex = bufferIndexForDequeIndex(count)
        elements.advanced(by: endIndex).initialize(with: element)
        self.count += 1
    }

    internal func popLast() -> Element? {
        guard count > 0 else { return nil }
        let lastIndex = bufferIndexForDequeIndex(count - 1)
        let last = elements.advanced(by: lastIndex).move()
        self.count -= 1
        return last
    }

    /// Create a gap of `length` uninitialized slots starting at `index`.
    /// Existing elements are moved out of the way.
    /// You are expected to fill the gap by initializing all slots in it after calling this method.
    /// Note that all previously calculated buffer indexes are invalidated by this method.
    private func openGapAt(index: Int, length: Int) {
        assert(index >= 0 && index <= self.count)
        assert(count + length <= capacity)
        guard length > 0 else { return }
        let i = bufferIndexForDequeIndex(index)
        if index >= (count + 1) / 2 {
            // Make room by sliding elements at/after index to the right
            let end = start + count <= capacity ? start + count : start + count - capacity
            if i <= end { // Elements after index are not yet wrapped
                if end + length <= capacity { // Neither gap nor elements after it will be wrapped
                    // ....ABCD̲EF......
                    elements.advanced(by: i + length).moveInitializeBackwardFrom(elements.advanced(by: i), count: end - i)
                    // ....ABC.̲..DEF...
                }
                else if i + length <= capacity { // Elements after gap will be wrapped
                    // .........ABCD̲EF. (count = 3)
                    elements.moveInitializeFrom(elements.advanced(by: capacity - length), count: end + length - capacity)
                    // EF.......ABCD̲...
                    elements.advanced(by: i + length).moveInitializeBackwardFrom(elements.advanced(by: i), count: capacity - i - length)
                    // EF.......ABC.̲..D
                }
                else { // Gap will be wrapped
                    // .........ABCD̲EF. (count = 5)
                    elements.advanced(by: i + length - capacity).moveInitializeFrom(elements.advanced(by: i), count: end - i)
                    // .DEF.....ABC.̲...
                }
            }
            else { // Elements after index are already wrapped
                if i + length <= capacity { // Gap will not be wrapped
                    // F.......ABCD̲E (count = 1)
                    elements.advanced(by: length).moveInitializeBackwardFrom(elements, count: end)
                    // .F......ABCD̲E
                    elements.moveInitializeFrom(elements.advanced(by: capacity - length), count: length)
                    // EF......ABCD̲.
                    elements.advanced(by: i + length).moveInitializeBackwardFrom(elements.advanced(by: i), count: capacity - i - length)
                    // EF......ABC.̲D
                }
                else { // Gap will be wrapped
                    // F.......ABCD̲E (count = 3)
                    elements.advanced(by: length).moveInitializeBackwardFrom(elements, count: end)
                    // ...F....ABCD̲E
                    elements.advanced(by: i + length - capacity).moveInitializeFrom(elements.advanced(by: i), count: capacity - i)
                    // .DEF....ABC.̲.
                }
            }
            count += length
        }
        else {
            // Make room by sliding elements before index to the left, updating `start`.
            if i >= start { // Elements before index are not yet wrapped.
                if start >= length { // Neither gap nor elements before it will be wrapped.
                    // ....ABCD̲EF...
                    elements.advanced(by: start - length).moveInitializeFrom(elements.advanced(by: start), count: i - start)
                    // .ABC...D̲EF...
                }
                else if i >= length { // Elements before the gap will be wrapped.
                    // ..ABCD̲EF....
                    elements.advanced(by: capacity + start - length).moveInitializeFrom(elements.advanced(by: start), count: length - start)
                    // ...BCD̲EF...A
                    elements.moveInitializeFrom(elements.advanced(by: length), count: i - length)
                    // BC...D̲EF...A
                }
                else { // Gap will be wrapped
                    // .ABCD̲EF....... (count = 5)
                    elements.advanced(by: capacity + start - length).moveInitializeFrom(elements.advanced(by: start), count: i - start)
                    // ....D̲EF...ABC.
                }
            }
            else { // Elements before index are already wrapped.
                if i >= length { // Gap will not be wrapped.
                    // BCD̲EF......A (count = 1)
                    elements.advanced(by: start - length).moveInitializeFrom(elements.advanced(by: start), count: capacity - start)
                    // BCD̲EF.....A.
                    elements.advanced(by: capacity - length).moveInitializeFrom(elements, count: length)
                    // .CD̲EF.....AB
                    elements.moveInitializeFrom(elements.advanced(by: i - length), count: i - length)
                    // C.D̲EF.....AB
                }
                else { // Gap will be wrapped.
                    // CD̲EF......AB
                    elements.advanced(by: start - length).moveInitializeFrom(elements.advanced(by: start), count: capacity - start)
                    // CD̲EF...AB...
                    elements.advanced(by: capacity - length).moveInitializeFrom(elements, count: i)
                    // .D̲EF...ABC..
                }
            }
            start = start < length ? capacity + start - length : start - length
            count += length
        }
    }

    internal func insert(element: Element, at index: Int) {
        precondition(index >= 0 && index <= count && !isFull)
        openGapAt(index, length: 1)
        let i = bufferIndexForDequeIndex(index)
        elements.advanced(by: i).initialize(with: element)
    }

    internal func insertContentsOf(buffer: DequeBuffer, at index: Int) {
        self.insertContentsOf(buffer, subRange: 0 ..< buffer.count, at: index)
    }

    internal func insertContentsOf(buffer: DequeBuffer, subRange: Range<Int>, at index: Int) {
        assert(buffer !== self)
        assert(index >= 0 && index <= count)
        assert(count + subRange.count <= capacity)
        assert(subRange.startIndex >= 0 && subRange.endIndex <= buffer.count)
        guard subRange.count > 0 else { return }
        openGapAt(index, length: subRange.count)

        let dp = self.elements
        let sp = buffer.elements

        let dstStart = self.bufferIndexForDequeIndex(index)
        let srcStart = buffer.bufferIndexForDequeIndex(subRange.startIndex)

        let srcCount = subRange.count

        let dstEnd = self.bufferIndexForDequeIndex(index + srcCount)
        let srcEnd = buffer.bufferIndexForDequeIndex(subRange.endIndex)

        if srcStart < srcEnd && dstStart < dstEnd {
            dp.advanced(by: dstStart).initializeFrom(sp.advanced(by: srcStart), count: srcCount)
        }
        else if dstStart < dstEnd {
            let t = buffer.capacity - srcStart
            dp.advanced(by: dstStart).initializeFrom(sp.advanced(by: srcStart), count: t)
            dp.advanced(by: dstStart + t).initializeFrom(sp, count: srcCount - t)
        }
        else if srcStart < srcEnd {
            let t = self.capacity - dstStart
            dp.advanced(by: dstStart).initializeFrom(sp.advanced(by: srcStart), count: t)
            dp.initializeFrom(sp.advanced(by: srcStart + t), count: srcCount - t)
        }
        else {
            let st = buffer.capacity - srcStart
            let dt = self.capacity - dstStart

            if dt < st {
                dp.advanced(by: dstStart).initializeFrom(sp.advanced(by: srcStart), count: dt)
                dp.initializeFrom(sp.advanced(by: srcStart + dt), count: st - dt)
                dp.advanced(by: st - dt).initializeFrom(sp, count: srcCount - st)
            }
            else if dt > st {
                dp.advanced(by: dstStart).initializeFrom(sp.advanced(by: srcStart), count: st)
                dp.advanced(by: dstStart + st).initializeFrom(sp, count: dt - st)
                dp.initializeFrom(sp.advanced(by: dt - st), count: srcCount - dt)
            }
            else {
                dp.advanced(by: dstStart).initializeFrom(sp.advanced(by: srcStart), count: st)
                dp.initializeFrom(sp, count: srcCount - st)
            }
        }
    }

    internal func insertContentsOf<C: Collection where C.Iterator.Element == Element>(collection: C, at index: Int) {
        assert(index >= 0 && index <= count)
        let c: Int = numericCast(collection.count)
        assert(count + c <= capacity)
        guard c > 0 else { return }
        openGapAt(index, length: c)
        var q = elements.advanced(by: bufferIndexForDequeIndex(index))
        let limit = elements.advanced(by: capacity)
        for element in collection {
            q.initialize(with: element)
            q = q.successor()
            if q == limit {
                q = elements
            }
        }
    }

    /// Destroy elements in the range (index ..< index + count) and collapse the gap by moving remaining elements.
    /// Note that all previously calculated buffer indexes are invalidated by this method.
    private func removeRange(range: Range<Int>) {
        assert(range.startIndex >= 0)
        assert(range.endIndex <= self.count)
        guard range.count > 0 else { return }
        let rc = range.count
        let p = elements
        let i = bufferIndexForDequeIndex(range.startIndex)
        let j = i + rc <= capacity ? i + rc : i + rc - capacity

        // Destroy items in collapsed range
        if i <= j {
            // ....ABC̲D̲E̲FG...
            p.advanced(by: i).deinitialize(count: rc)
            // ....AB...FG...
        }
        else {
            // D̲E̲FG.......ABC̲
            p.advanced(by: i).deinitialize(count: capacity - i)
            // D̲E̲FG.......AB.
            p.deinitialize(count: j)
            // ..FG.......AB.
        }

        if count - range.startIndex - rc < range.startIndex {
            let end = start + count < capacity ? start + count : start + count - capacity

            // Slide trailing items to the left
            if i <= end { // No wrap anywhere after start of collapsed range
                // ....AB.̲..CD...
                p.advanced(by: i).moveInitializeFrom(p.advanced(by: i + rc), count: end - i - rc)
                // ....ABC̲D......
            }
            else if i + rc > capacity { // Collapsed range is wrapped
                if end <= rc { // Result will not be wrapped
                    // .CD......AB.̲..
                    p.advanced(by: i).moveInitializeFrom(p.advanced(by: i + rc - capacity), count: capacity + end - i - rc)
                    // .........ABC̲D.
                }
                else { // Result will remain wrapped
                    // .CDEFG...AB.̲..
                    p.advanced(by: i).moveInitializeFrom(p.advanced(by: i + rc - capacity), count: capacity - i)
                    // ....FG...ABC̲DE
                    p.moveInitializeFrom(p.advanced(by: rc), count: end - rc)
                    // FG.......ABC̲DE
                }
            }
            else { // Wrap is after collapsed range
                if end <= rc { // Result will not be wrapped
                    // D.......AB.̲..C
                    p.advanced(by: i).moveInitializeFrom(p.advanced(by: i + rc), count: capacity - i - rc)
                    // D.......ABC̲...
                    p.advanced(by: capacity - rc).moveInitializeFrom(p, count: end)
                    // ........ABC̲D..
                }
                else { // Result will remain wrapped
                    // DEFG....AB.̲..C
                    p.advanced(by: i).moveInitializeFrom(p.advanced(by: i + rc), count: capacity - i - rc)
                    // DEFG....ABC̲...
                    p.advanced(by: capacity - rc).moveInitializeFrom(p, count: rc)
                    // ...G....ABC̲DEF
                    p.moveInitializeFrom(p.advanced(by: rc), count: end - rc)
                    // G.......ABC̲DEF
                }
            }
            count -= rc
        }
        else {
            // Slide preceding items to the right
            if j >= start { // No wrap anywhere before end of collapsed range
                // ...AB...C̲D...
                p.advanced(by: start + rc).moveInitializeBackwardFrom(p.advanced(by: start), count: j - start - rc)
                // ......ABC̲D...
            }
            else if j < rc { // Collapsed range is wrapped
                if  start + rc >= capacity  { // Result will not be wrapped
                    // ...C̲D.....AB..
                    p.advanced(by: start + rc - capacity).moveInitializeFrom(p.advanced(by: start), count: capacity + j - start - rc)
                    // .ABC̲D.........
                }
                else { // Result will remain wrapped
                    // ..E̲F.....ABCD..
                    p.moveInitializeFrom(p.advanced(by: capacity - rc), count: j)
                    // CDE̲F.....AB....
                    p.advanced(by: start + rc).moveInitializeBackwardFrom(p.advanced(by: start), count: capacity - start - rc)
                    // CDE̲F.........AB
                }
            }
            else { // Wrap is before collapsed range
                if capacity - start <= rc { // Result will not be wrapped
                    // CD...E̲F.....AB
                    p.advanced(by: rc).moveInitializeBackwardFrom(p, count: j - rc)
                    // ...CDE̲F.....AB
                    p.advanced(by: start + rc - capacity).moveInitializeFrom(p.advanced(by: start), count: capacity - start)
                    // .ABCDE̲F.......
                }
                else { // Result will remain wrapped
                    // EF...G̲H...ABCD
                    p.advanced(by: rc).moveInitializeBackwardFrom(p, count: j - rc)
                    // ...EFG̲H...ABCD
                    p.moveInitializeFrom(p.advanced(by: capacity) - rc, count: rc)
                    // BCDEFG̲H...A...
                    p.advanced(by: start + rc).moveInitializeBackwardFrom(p.advanced(by: start), count: capacity - start - rc)
                    // BCDEFG̲H......A
                }
            }
            start = (start + rc < capacity ? start + rc : start + rc - capacity)
            count -= rc
        }
    }

    internal func replaceRange<C: Collection where C.Iterator.Element == Element>(range: Range<Int>, with newElements: C) {
        let newCount: Int = numericCast(newElements.count)
        let delta = newCount - range.count
        assert(count + delta < capacity)
        let common = min(range.count, newCount)
        if common > 0 {
            let p = elements
            var q = p.advanced(by: bufferIndexForDequeIndex(range.startIndex))
            let limit = p.advanced(by: capacity)
            var i = common
            for element in newElements {
                q.pointee = element
                q = q.successor()
                if q == limit { q = p }
                i -= 1
                if i == 0 { break }
            }
        }
        if range.count > common {
            removeRange(range.startIndex + common ..< range.endIndex)
        }
        else if newCount > common {
            openGapAt(range.startIndex + common, length: newCount - common)
            let p = elements
            var q = p.advanced(by: bufferIndexForDequeIndex(range.startIndex + common))
            let limit = p.advanced(by: capacity)
            var i = newElements.startIndex.advanced(by: numericCast(common))
            while i != newElements.endIndex {
                q.initialize(with: newElements[i])
                i = i.successor()
                q = q.successor()
                if q == limit { q = p }
            }
        }
    }
}

//MARK: 

extension DequeBuffer {
    internal func forEach(@noescape body: (Element) throws -> ()) rethrows {
        if start + count <= capacity {
            var p = elements + start
            for _ in 0 ..< count {
                try body(p.pointee)
                p += 1
            }
        }
        else {
            var p = elements + start
            for _ in start ..< capacity {
                try body(p.pointee)
                p += 1
            }
            p = elements
            for _ in 0 ..< start + count - capacity {
                try body(p.pointee)
                p += 1
            }
        }
    }
}

extension Deque {
    public func forEach(@noescape body: (Element) throws -> ()) rethrows {
        try withExtendedLifetime(buffer) { buffer in
            try buffer.forEach(body)
        }
    }

    public func map<T>(@noescape transform: (Element) throws -> T) rethrows -> [T] {
        var result: [T] = []
        result.reserveCapacity(self.count)
        try self.forEach { result.append(try transform($0)) }
        return result
    }

    public func flatMap<T>(@noescape transform: (Element) throws -> T?) rethrows -> [T] {
        var result: [T] = []
        try self.forEach {
            if let r = try transform($0) {
                result.append(r)
            }
        }
        return result
    }

    public func flatMap<S: Sequence>(transform: (Element) throws -> S) rethrows -> [S.Iterator.Element] {
        var result: [S.Iterator.Element] = []
        try self.forEach {
            result.append(contentsOf: try transform($0))
        }
        return result
    }

    public func filter(@noescape includeElement: (Element) throws -> Bool) rethrows -> [Element] {
        var result: [Element] = []
        try self.forEach {
            if try includeElement($0) {
                result.append($0)
            }
        }
        return result
    }

    public func reduce<T>(initial: T, @noescape combine: (T, Element) throws -> T) rethrows -> T {
        var result = initial
        try self.forEach {
            result = try combine(result, $0)
        }
        return result
    }
}

