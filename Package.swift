// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "TickStream",
    platforms: [.macOS(.v14), .iOS(.v17)],
    products: [
        .library(name: "TickStreamCore", targets: ["TickStreamCore"]),
        .executable(name: "TickStreamApp", targets: ["TickStreamApp"]),
    ],
    targets: [
        .target(name: "TickStreamCore"),
        .executableTarget(name: "TickStreamApp", dependencies: ["TickStreamCore"]),
        .testTarget(name: "TickStreamCoreTests", dependencies: ["TickStreamCore"]),
    ]
)
