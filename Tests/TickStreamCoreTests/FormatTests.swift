import XCTest
@testable import TickStreamCore

final class FormatTests: XCTestCase {
    func testPriceDecimalsDependOnMagnitude() {
        XCTAssertEqual(Format.price(65_432.1), "65432.10")
        XCTAssertEqual(Format.price(2.5), "2.500")
        XCTAssertEqual(Format.price(0.25), "0.25000")
        XCTAssertEqual(Format.price(0.000012), "0.00001200")
    }

    func testNonFiniteValuesRenderAsDashes() {
        XCTAssertEqual(Format.price(.nan), "--")
        XCTAssertEqual(Format.percent(.infinity), "--")
        XCTAssertEqual(Format.compact(.nan), "--")
    }

    func testPercentHasASignForGains() {
        XCTAssertEqual(Format.percent(1.25), "+1.25%")
        XCTAssertEqual(Format.percent(-0.5), "-0.50%")
        XCTAssertEqual(Format.percent(0), "0.00%")
    }

    func testCompactUsesSuffixes() {
        XCTAssertEqual(Format.compact(2_500_000_000), "2.5B")
        XCTAssertEqual(Format.compact(3_200_000), "3.2M")
        XCTAssertEqual(Format.compact(4_500), "4.5K")
        XCTAssertEqual(Format.compact(12.5), "12.50")
    }

    func testDisplaySymbolSplitsTheQuoteAsset() {
        XCTAssertEqual(Format.displaySymbol("btcusdt"), "BTC/USDT")
        XCTAssertEqual(Format.displaySymbol("ETHBTC"), "ETHBTC")
    }

    func testSpreadInBasisPoints() {
        XCTAssertEqual(Format.spreadBps(bid: 99, ask: 101)!, 200, accuracy: 1e-9)
        XCTAssertNil(Format.spreadBps(bid: 101, ask: 99))
        XCTAssertNil(Format.spreadBps(bid: 0, ask: 1))
    }
}
