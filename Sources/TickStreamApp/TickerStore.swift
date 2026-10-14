import Foundation
import TickStreamCore

@MainActor
final class TickerStore: ObservableObject {
    enum Mode: String, CaseIterable, Identifiable {
        case batched = "Batched"
        case naive = "Naive"
        var id: String { rawValue }
    }

    @Published private(set) var tickers: [String: Ticker] = [:]
    @Published private(set) var renders = 0
    @Published private(set) var status = "connecting"
    @Published var mode: Mode = .batched

    private(set) var received = 0
    private var batcher = Batcher<TickerPatch>(keyOf: { $0.symbol })
    private var task: URLSessionWebSocketTask?
    private var flushTimer: Timer?

    var sortedSymbols: [String] { tickers.keys.sorted() }

    func start() {
        guard task == nil, let url = Binance.tickerStreamURL(Binance.symbols) else { return }
        let socket = URLSession.shared.webSocketTask(with: url)
        task = socket
        socket.resume()
        status = "open"
        receive(on: socket)
        flushTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            Task { @MainActor in self?.flush() }
        }
    }

    func stop() {
        task?.cancel(with: .goingAway, reason: nil)
        task = nil
        flushTimer?.invalidate()
        flushTimer = nil
        status = "closed"
    }

    private func receive(on socket: URLSessionWebSocketTask) {
        socket.receive { [weak self] result in
            Task { @MainActor in
                guard let self else { return }
                switch result {
                case .success(.string(let text)):
                    self.handle(text)
                    self.receive(on: socket)
                case .success:
                    self.receive(on: socket)
                case .failure:
                    self.status = "reconnecting"
                    self.task = nil
                    self.flushTimer?.invalidate()
                    self.flushTimer = nil
                    try? await Task.sleep(nanoseconds: 2_000_000_000)
                    self.start()
                }
            }
        }
    }

    private func handle(_ text: String) {
        guard let patch = Binance.patch(from: text) else { return }
        received += 1
        switch mode {
        case .naive:
            apply([patch])
        case .batched:
            batcher.push(patch)
        }
    }

    private func flush() {
        let patches = batcher.flush()
        guard !patches.isEmpty else { return }
        apply(patches)
    }

    private func apply(_ patches: [TickerPatch]) {
        var next = tickers
        for patch in patches {
            next[patch.symbol] = mergeTicker(next[patch.symbol], patch)
        }
        tickers = next
        renders += 1
    }
}
