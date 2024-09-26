import Foundation

final class UVIdArray<T: AnyObject> {
    struct Item {
        let id: UInt
        var item: T
    }

    private var items: [Item] = []
    private var lock = NSLock()
    public private(set) var currentId: UInt = 0

    @discardableResult
    func append(using: (UInt) -> T?) -> UnsafeMutablePointer<T>? {
        lock.lock()
        defer { lock.unlock() }

        currentId = currentId &+ 1
        guard let item = using(currentId) else { return nil }

        items.append(.init(id: currentId, item: item))

        let index = items.index(before: items.endIndex)

        return withUnsafeMutablePointer(to: &items[index].item) {
            $0
        }
    }

    @discardableResult
    func append(_ value: T) -> UnsafeMutablePointer<T> {
        lock.lock()
        defer { lock.unlock() }

        currentId = currentId &+ 1
        items.append(.init(id: currentId, item: value))

        let index = items.index(before: items.endIndex)

        return withUnsafeMutablePointer(to: &items[index].item) {
            $0
        }
    }

    func find(by id: UInt) -> T? {
        lock.lock()
        defer { lock.unlock() }

        let index = items.firstIndex(where: { $0.id == id })
        guard let index else { return nil }
        let item = items[index]
        return item.item
    }

    func update<U>(with id: UInt, using: (inout T) -> U) -> U? {
        lock.lock()
        defer { lock.unlock() }

        let index = items.firstIndex(where: { $0.id == id })
        guard let index else { return nil }
        return using(&items[index].item)
    }

    func remove(with id: UInt) {
        lock.lock()
        defer { lock.unlock() }

        let index = items.firstIndex(where: { $0.id == id })
        guard let index else { return }
        items.remove(at: index)
    }

    func removeAll() {
        lock.lock()
        defer { lock.unlock() }

        items.removeAll()
    }

    @discardableResult
    func removeFirst() -> T? {
        lock.lock()
        defer { lock.unlock() }

        return items.removeFirst().item
    }

    func first() -> T? {
        lock.lock()
        defer { lock.unlock() }

        return items.first?.item
    }

    @discardableResult
    func removeLast() -> T? {
        lock.lock()
        defer { lock.unlock() }

        return items.popLast()?.item
    }

    func last() -> T? {
        lock.lock()
        defer { lock.unlock() }

        return items.last?.item
    }

    func map<U>(using: (T) -> U) -> [U] {
        lock.lock()
        defer { lock.unlock() }

        return items.map { using($0.item) }
    }

    func forEach(using: (T) -> Void) {
        lock.lock()
        defer { lock.unlock() }

        for item in items {
            using(item.item)
        }
    }
}
