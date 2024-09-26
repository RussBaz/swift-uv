final class UVIdArray<T: AnyObject> {
    struct Item {
        let id: UInt
        var item: T
    }

    private var items: [Item] = []
    public private(set) var currentId: UInt = 0

    @discardableResult
    func append(using: (UInt) -> T?) -> UnsafeMutablePointer<T>? {
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
        currentId = currentId &+ 1
        items.append(.init(id: currentId, item: value))

        let index = items.index(before: items.endIndex)

        return withUnsafeMutablePointer(to: &items[index].item) {
            $0
        }
    }

    func find(by id: UInt) -> T? {
        let index = items.firstIndex(where: { $0.id == id })
        guard let index else { return nil }
        let item = items[index]
        return item.item
    }

    func update<U>(with id: UInt, using: (inout T) -> U) -> U? {
        let index = items.firstIndex(where: { $0.id == id })
        guard let index else { return nil }
        return using(&items[index].item)
    }

    func remove(with id: UInt) {
        let index = items.firstIndex(where: { $0.id == id })
        guard let index else { return }
        items.remove(at: index)
    }

    func removeAll() {
        items.removeAll()
    }

    @discardableResult
    func removeFirst() -> T? {
        items.removeFirst().item
    }

    func first() -> T? {
        items.first?.item
    }

    @discardableResult
    func removeLast() -> T? {
        items.popLast()?.item
    }

    func last() -> T? {
        items.last?.item
    }

    func map<U>(using: (T) -> U) -> [U] {
        items.map { using($0.item) }
    }

    func forEach(using: (T) -> Void) {
        for item in items {
            using(item.item)
        }
    }
}
