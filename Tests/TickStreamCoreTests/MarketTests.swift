import XCTest
@testable import TickStreamCore

final class MarketTests: XCTestCase {
    func testParsesATickerMessageWithStringNumbers() {
        let raw = #"{"stream":"btcusdt@ticker","data":{"s":"BTCUSDT","c":"65000.5","P":"-1.20","q":"123456.7","E":1700000000000}}"#
        let patch = Binance.patch(from: raw)
        XCTAssertEqual(patch?.symbol, "BTCUSDT")
        XCTAssertEqual(patch?.last, 65000.5)
        XCTAssertEqual(patch?.changePercent, -1.2)
        XCTAssertEqual(patch?.quoteVolume, 123456.7)
    }

    func testParsesABookTickerIntoBidAndAsk() {
        let raw = #"{"stream":"ethusdt@bookTicker","data":{"s":"ETHUSDT","b":"3000.1","B":"2","a":"3000.3","A":"1"}}"#
        let patch = Binance.patch(from: raw)
        XCTAssertEqual(patch?.bid, 3000.1)
        XCTAssertEqual(patch?.ask, 3000.3)
        XCTAssertNil(patch?.last)
    }

    func testDropsMessagesItCannotIdentify() {
        XCTAssertNil(Binance.patch(from: "not json"))
        XCTAssertNil(Binance.patch(from: #"{"data":{}}"#))
        XCTAssertNil(Binance.patch(from: #"{"stream":"btcusdt@ticker","data":{"s":"BTCUSDT","c":"abc","P":"1"}}"#))
        XCTAssertNil(Binance.patch(from: #"{"stream":"btcusdt@depth","data":{"s":"BTCUSDT"}}"#))
    }

    func testMergeKeepsFieldsThePatchDoesNotCarry() {
        let ticker = mergeTicker(nil, TickerPatch(symbol: "BTCUSDT", last: 10, changePercent: 1))
        let merged = mergeTicker(ticker, TickerPatch(symbol: "BTCUSDT", bid: 9, ask: 11))
        XCTAssertEqual(merged.last, 10)
        XCTAssertEqual(merged.changePercent, 1)
        XCTAssertEqual(merged.bid, 9)
        XCTAssertEqual(merged.ask, 11)
    }

    func testDisplayPriceUsesTheMidWhenTheBookIsValid() {
        XCTAssertEqual(Ticker(symbol: "X", last: 5, bid: 9, ask: 11).displayPrice, 10)
        XCTAssertEqual(Ticker(symbol: "X", last: 5, bid: 11, ask: 9).displayPrice, 5)
        XCTAssertEqual(Ticker(symbol: "X", last: 5).displayPrice, 5)
    }

    func testStreamURLIncludesBothStreamsPerSymbol() {
        let url = Binance.tickerStreamURL(["btcusdt"])?.absoluteString ?? ""
        XCTAssertTrue(url.contains("btcusdt@ticker/btcusdt@bookTicker"))
    }

    func testFrameRateMeterCountsFramesInTheWindow() {
        var meter = FrameRateMeter(window: 1.0)
        for i in 0...60 { meter.tick(at: Double(i) / 60.0) }
        XCTAssertEqual(meter.framesPerSecond, 60, accuracy: 0.5)
        meter.tick(at: 10)
        XCTAssertEqual(meter.framesPerSecond, 0)
    }
}
