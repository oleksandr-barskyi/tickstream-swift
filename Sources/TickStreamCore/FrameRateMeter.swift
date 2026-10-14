public struct FrameRateMeter {
    public let window: Double
    private var stamps: [Double] = []

    public init(window: Double = 1.0) {
        self.window = window
    }

    public mutating func tick(at time: Double) {
        stamps.append(time)
        let cutoff = time - window
        if let firstKept = stamps.firstIndex(where: { $0 > cutoff }) {
            stamps.removeFirst(firstKept)
        }
    }

    public var framesPerSecond: Double {
        guard stamps.count > 1, let first = stamps.first, let last = stamps.last, last > first else { return 0 }
        return Double(stamps.count - 1) / (last - first)
    }
}
