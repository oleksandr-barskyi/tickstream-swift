import Foundation

public struct Ticker: Equatable, Sendable {
    public var symbol: String
    public var last: Double
    public var bid: Double?
    public var ask: Double?
    public var changePercent: Double
    public var quoteVolume: Double
    public var at: Double

    public init(symbol: String, last: Double = 0, bid: Double? = nil, ask: Double? = nil,
                changePercent: Double = 0, quoteVolume: Double = 0, at: Double = 0) {
        self.symbol = symbol
        self.last = last
        self.bid = bid
        self.ask = ask
        self.changePercent = changePercent
        self.quoteVolume = quoteVolume
        self.at = at
    }

    public var displayPrice: Double {
        if let bid, let ask, ask >= bid { return (bid + ask) / 2 }
        return last
    }
}

public struct TickerPatch: Equatable, Sendable {
    public var symbol: String
    public var last: Double?
    public var bid: Double?
    public var ask: Double?
    public var changePercent: Double?
    public var quoteVolume: Double?
    public var at: Double?

    public init(symbol: String, last: Double? = nil, bid: Double? = nil, ask: Double? = nil,
                changePercent: Double? = nil, quoteVolume: Double? = nil, at: Double? = nil) {
        self.symbol = symbol
        self.last = last
        self.bid = bid
        self.ask = ask
        self.changePercent = changePercent
        self.quoteVolume = quoteVolume
        self.at = at
    }
}

public func mergeTicker(_ previous: Ticker?, _ patch: TickerPatch) -> Ticker {
    let base = previous ?? Ticker(symbol: patch.symbol)
    return Ticker(
        symbol: patch.symbol,
        last: patch.last ?? base.last,
        bid: patch.bid ?? base.bid,
        ask: patch.ask ?? base.ask,
        changePercent: patch.changePercent ?? base.changePercent,
        quoteVolume: patch.quoteVolume ?? base.quoteVolume,
        at: patch.at ?? base.at
    )
}

public enum Binance {
    public static let base = "wss://stream.binance.com:9443/stream"

    public static let symbols = [
        "btcusdt", "ethusdt", "solusdt", "bnbusdt", "xrpusdt", "adausdt",
        "dogeusdt", "avaxusdt", "linkusdt", "dotusdt", "ltcusdt", "trxusdt",
        "nearusdt", "atomusdt", "uniusdt", "aptusdt", "arbusdt", "opusdt",
        "filusdt", "injusdt", "suiusdt", "aaveusdt", "algousdt", "grtusdt",
    ]

    public static func tickerStreamURL(_ symbols: [String]) -> URL? {
        let streams = symbols.flatMap { ["\($0)@ticker", "\($0)@bookTicker"] }.joined(separator: "/")
        return URL(string: "\(base)?streams=\(streams)")
    }

    static func number(_ value: Any?) -> Double? {
        if let n = value as? Double, n.isFinite { return n }
        if let n = value as? Int { return Double(n) }
        if let s = value as? String, let n = Double(s), n.isFinite { return n }
        return nil
    }

    public static func parseEnvelope(_ raw: String) -> (stream: String, data: [String: Any])? {
        guard let bytes = raw.data(using: .utf8),
              let object = try? JSONSerialization.jsonObject(with: bytes) as? [String: Any],
              let stream = object["stream"] as? String else { return nil }
        return (stream, object["data"] as? [String: Any] ?? [:])
    }

    public static func parseTicker(_ d: [String: Any]) -> TickerPatch? {
        guard let symbol = d["s"] as? String,
              let last = number(d["c"]),
              let change = number(d["P"]) else { return nil }
        return TickerPatch(symbol: symbol, last: last, changePercent: change,
                           quoteVolume: number(d["q"]) ?? 0, at: number(d["E"]))
    }

    public static func parseBookPatch(_ d: [String: Any]) -> TickerPatch? {
        guard let symbol = d["s"] as? String,
              let bid = number(d["b"]),
              let ask = number(d["a"]) else { return nil }
        return TickerPatch(symbol: symbol, bid: bid, ask: ask)
    }

    public static func patch(from raw: String) -> TickerPatch? {
        guard let envelope = parseEnvelope(raw) else { return nil }
        if envelope.stream.hasSuffix("@bookTicker") { return parseBookPatch(envelope.data) }
        if envelope.stream.hasSuffix("@ticker") { return parseTicker(envelope.data) }
        return nil
    }
}
