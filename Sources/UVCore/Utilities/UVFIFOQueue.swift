import Collections
import Foundation

final class UVFIFOQueue<T> {
    private var items = Deque<T>()
    private let hasItemsWaiter = NSCondition()

    func enqueue(_ element: T) {
        hasItemsWaiter.lock()
        defer { hasItemsWaiter.unlock() }
        items.append(element)
        hasItemsWaiter.signal()
    }

    func dequeue() -> T? {
        hasItemsWaiter.lock()
        defer { hasItemsWaiter.unlock() }
        if items.isEmpty {
            return nil
        } else {
            return items.removeFirst()
        }
    }

    func waitForNextItem(until limit: Date? = nil) -> T? {
        hasItemsWaiter.lock()
        defer { hasItemsWaiter.unlock() }
        if let limit {
            while items.isEmpty {
                guard hasItemsWaiter.wait(until: limit) else { return nil }
            }
            return items.removeFirst()
        } else {
            while items.isEmpty {
                hasItemsWaiter.wait()
            }
            return items.removeFirst()
        }
    }

    var isEmpty: Bool {
        hasItemsWaiter.lock()
        defer { hasItemsWaiter.unlock() }
        return items.isEmpty
    }
}
