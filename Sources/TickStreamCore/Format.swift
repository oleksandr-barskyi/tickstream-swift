import Foundation

public enum Format {
    public static func decimals(for price: Double) -> Int {
        let value = abs(price)
        if value >= 1000 { return 2 }
        if value >= 1 { return 3 }
        if value >= 0.01 { return 5 }
        return 8
    }

    public static func price(_ price: Double) -> String {
        guard price.isFinite else { return "--" }
        return String(format: "%.\(decimals(for: price))f", price)
    }

    public static func percent(_ percent: Double) -> String {
        guard percent.isFinite else { return "--" }
        let sign = percent > 0 ? "+" : ""
        return sign + String(format: "%.2f", percent) + "%"
    }

    public static func compact(_ value: Double) -> String {
        guard value.isFinite else { return "--" }
        let magnitude = abs(value)
        if magnitude >= 1_000_000_000 { return String(format: "%.1fB", value / 1_000_000_000) }
        if magnitude >= 1_000_000 { return String(format: "%.1fM", value / 1_000_000) }
        if magnitude >= 1_000 { return String(format: "%.1fK", value / 1_000) }
        return String(format: "%.2f", value)
    }

    public static func displaySymbol(_ symbol: String) -> String {
        let upper = symbol.uppercased()
        guard upper.hasSuffix("USDT") else { return upper }
        return String(upper.dropLast(4)) + "/USDT"
    }

    public static func spreadBps(bid: Double, ask: Double) -> Double? {
        guard bid.isFinite, ask.isFinite, bid > 0, ask > 0, ask >= bid else { return nil }
        let mid = (bid + ask) / 2
        guard mid != 0 else { return nil }
        return (ask - bid) / mid * 10_000
    }
}
