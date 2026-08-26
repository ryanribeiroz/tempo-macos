// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "Tempo",
    platforms: [.macOS(.v14)],
    products: [
        .executable(name: "Tempo", targets: ["Tempo"])
    ],
    targets: [
        .executableTarget(
            name: "Tempo",
            path: "Sources/Tempo",
            exclude: ["Assets.xcassets"],
            swiftSettings: [.swiftLanguageMode(.v5)]
        ),
        .testTarget(
            name: "TempoTests",
            dependencies: ["Tempo"],
            path: "Tests/TempoTests",
            swiftSettings: [.swiftLanguageMode(.v5)]
        )
    ]
)
