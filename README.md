# tickstream-swift

A Swift and SwiftUI port of [TickStream](https://github.com/oleksandr-barskyi/tickstream),
a live market feed that renders thirty Binance symbols without dropping frames, with a
**Batched / Naive** switch so you can watch the difference. The original is React Native;
this is the same idea rebuilt natively, written as a learning project while I move from
React Native and Flutter into Swift.

## Run it

On macOS 14 or later:

```bash
swift run TickStreamApp
```

No API key, no account. The app connects to Binance's public WebSocket streams.

## The idea

A market feed is not a list that updates. It is dozens of symbols each pushing several
messages per second. Committing state on every message works on a fast machine and
stutters everywhere else.

- **Batched** pushes every message into a keyed buffer and commits on a 100 ms timer. If
  BTC ticks twelve times between commits, eleven of those are dropped, because nobody can
  see a price that was replaced 40 ms later.
- **Naive** commits every message immediately.

The header shows a live frame rate, how many messages arrived and how many became renders.

## Layout

```
Sources/TickStreamCore/   pure logic, no UI: Batcher, capped buffers, formatting,
                          Binance message parsing, ticker merge, frame-rate meter
Sources/TickStreamApp/    SwiftUI app: URLSessionWebSocketTask, store, rows
Tests/TickStreamCoreTests XCTest suites for the core
```

| TypeScript original | Swift port |
|---|---|
| `createBatcher` closure over a `Map` | `Batcher<Item>` value type, insertion order kept |
| `appendCapped`, `appendManyCapped` | generic free functions |
| `parseTicker`, `parseBookPatch` over `unknown` | `JSONSerialization` and optional binding, string numbers accepted |
| `mergeTicker` with `Partial<Ticker>` | `TickerPatch` with optional fields |
| memoised `TickerRow` comparator | `TickerRow: Equatable` on the drawn fields |

## Tests

```bash
swift test
```

The core builds on any platform with a Swift toolchain; the app target needs macOS
because of SwiftUI. CI runs both on `macos-latest`.
