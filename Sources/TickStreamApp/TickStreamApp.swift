import SwiftUI
import TickStreamCore

@main
struct TickStreamApp: App {
    @StateObject private var store = TickerStore()

    var body: some Scene {
        WindowGroup("TickStream") {
            ContentView()
                .environmentObject(store)
                .frame(minWidth: 520, minHeight: 640)
                .onAppear { store.start() }
                .onDisappear { store.stop() }
        }
    }
}

struct ContentView: View {
    @EnvironmentObject private var store: TickerStore
    @State private var meter = FrameRateMeter()
    @State private var fps = 0.0

    var body: some View {
        VStack(spacing: 0) {
            header
            Divider()
            List(store.sortedSymbols, id: \.self) { symbol in
                if let ticker = store.tickers[symbol] {
                    TickerRow(ticker: ticker)
                }
            }
            .listStyle(.plain)
        }
        .background(
            TimelineView(.animation) { context in
                Color.clear.onChange(of: context.date) { _, date in
                    meter.tick(at: date.timeIntervalSinceReferenceDate)
                    fps = meter.framesPerSecond
                }
            }
        )
    }

    private var header: some View {
        HStack {
            Picker("Mode", selection: $store.mode) {
                ForEach(TickerStore.Mode.allCases) { Text($0.rawValue).tag($0) }
            }
            .pickerStyle(.segmented)
            .frame(width: 200)
            Spacer()
            VStack(alignment: .trailing, spacing: 2) {
                Text(String(format: "%.0f fps", fps)).monospacedDigit().bold()
                Text("\(store.received) msgs, \(store.renders) renders, \(store.status)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .monospacedDigit()
            }
        }
        .padding(12)
    }
}

struct TickerRow: View, Equatable {
    let ticker: Ticker

    static func == (lhs: TickerRow, rhs: TickerRow) -> Bool {
        lhs.ticker.symbol == rhs.ticker.symbol
            && lhs.ticker.displayPrice == rhs.ticker.displayPrice
            && lhs.ticker.changePercent == rhs.ticker.changePercent
            && lhs.ticker.quoteVolume == rhs.ticker.quoteVolume
    }

    var body: some View {
        HStack {
            Text(Format.displaySymbol(ticker.symbol)).bold()
            Spacer()
            Text(Format.price(ticker.displayPrice)).monospacedDigit()
            Text(Format.percent(ticker.changePercent))
                .monospacedDigit()
                .foregroundStyle(ticker.changePercent >= 0 ? .green : .red)
                .frame(width: 80, alignment: .trailing)
            Text(Format.compact(ticker.quoteVolume))
                .monospacedDigit()
                .foregroundStyle(.secondary)
                .frame(width: 70, alignment: .trailing)
        }
        .padding(.vertical, 2)
    }
}
