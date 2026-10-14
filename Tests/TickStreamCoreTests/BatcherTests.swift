import XCTest
@testable import TickStreamCore

final class BatcherTests: XCTestCase {
    struct Tick: Equatable {
        let symbol: String
        let price: Double
    }

    func testKeepsOnlyTheLatestValuePerKey() {
        var batcher = Batcher<Tick>(keyOf: { $0.symbol })
        batcher.push(Tick(symbol: "BTC", price: 1))
        batcher.push(Tick(symbol: "ETH", price: 2))
        batcher.push(Tick(symbol: "BTC", price: 3))
        XCTAssertEqual(batcher.pending, 2)
        XCTAssertEqual(batcher.flush(), [Tick(symbol: "BTC", price: 3), Tick(symbol: "ETH", price: 2)])
    }

    func testFlushEmptiesTheBufferAndCountsOnlyNonEmptyFlushes() {
        var batcher = Batcher<Tick>(keyOf: { $0.symbol })
        XCTAssertEqual(batcher.flush(), [])
        batcher.push(Tick(symbol: "BTC", price: 1))
        _ = batcher.flush()
        XCTAssertEqual(batcher.pending, 0)
        XCTAssertEqual(batcher.flush(), [])
        XCTAssertEqual(batcher.stats.flushes, 1)
    }

    func testStatsReportHowManyMessagesWereCoalesced() {
        var batcher = Batcher<Tick>(keyOf: { $0.symbol })
        for i in 0..<12 { batcher.push(Tick(symbol: "BTC", price: Double(i))) }
        batcher.push(Tick(symbol: "ETH", price: 1))
        _ = batcher.flush()
        XCTAssertEqual(batcher.stats, BatchStats(received: 13, emitted: 2, flushes: 1))
        XCTAssertEqual(batcher.stats.coalesced, 11)
    }

    func testResetClearsEverything() {
        var batcher = Batcher<Tick>(keyOf: { $0.symbol })
        batcher.push(Tick(symbol: "BTC", price: 1))
        batcher.reset()
        XCTAssertEqual(batcher.pending, 0)
        XCTAssertEqual(batcher.stats, BatchStats())
    }

    func testAppendCappedPutsNewestFirstAndTrims() {
        XCTAssertEqual(appendCapped([2, 1], 3, limit: 2), [3, 2])
        XCTAssertEqual(appendCapped([1], 2, limit: 0), [])
    }

    func testAppendManyCappedKeepsNewestFirst() {
        XCTAssertEqual(appendManyCapped([1], [2, 3, 4], limit: 3), [4, 3, 2])
        XCTAssertEqual(appendManyCapped([1, 2], [], limit: 5), [1, 2])
        XCTAssertEqual(appendManyCapped([1], [2], limit: 0), [])
    }
}
