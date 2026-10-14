public struct BatchStats: Equatable, Sendable {
    public var received: Int
    public var emitted: Int
    public var flushes: Int

    public var coalesced: Int { received - emitted }

    public init(received: Int = 0, emitted: Int = 0, flushes: Int = 0) {
        self.received = received
        self.emitted = emitted
        self.flushes = flushes
    }
}

public struct Batcher<Item> {
    private let keyOf: (Item) -> String
    private var order: [String] = []
    private var pendingItems: [String: Item] = [:]
    public private(set) var stats = BatchStats()

    public init(keyOf: @escaping (Item) -> String) {
        self.keyOf = keyOf
    }

    public var pending: Int { pendingItems.count }

    public mutating func push(_ item: Item) {
        stats.received += 1
        let key = keyOf(item)
        if pendingItems[key] == nil {
            order.append(key)
        }
        pendingItems[key] = item
    }

    public mutating func flush() -> [Item] {
        guard !pendingItems.isEmpty else { return [] }
        let out = order.compactMap { pendingItems[$0] }
        pendingItems.removeAll(keepingCapacity: true)
        order.removeAll(keepingCapacity: true)
        stats.emitted += out.count
        stats.flushes += 1
        return out
    }

    public mutating func reset() {
        pendingItems.removeAll()
        order.removeAll()
        stats = BatchStats()
    }
}

public func appendCapped<T>(_ buffer: [T], _ item: T, limit: Int) -> [T] {
    guard limit > 0 else { return [] }
    return Array(([item] + buffer).prefix(limit))
}

public func appendManyCapped<T>(_ buffer: [T], _ items: [T], limit: Int) -> [T] {
    guard limit > 0 else { return [] }
    guard !items.isEmpty else { return buffer }
    return Array((items.reversed() + buffer).prefix(limit))
}
