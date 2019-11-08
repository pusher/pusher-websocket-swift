// swift-tools-version:4.2

import PackageDescription

let package = Package(
    name: "PusherSwift",
    products: [
        .library(name: "PusherSwift", targets: ["PusherSwift"])
    ],
    dependencies: [
        .package(url: "https://github.com/krzyzanowskim/CryptoSwift.git", .upToNextMajor(from: "1.1.3")),
        .package(url: "https://github.com/ashleymills/Reachability.swift.git", .exact("4.3.1")),
        .package(url: "https://github.com/daltoniam/Starscream.git", .exact("3.0.6")),
    ],
    targets: [
        .target(
            name: "PusherSwift",
            dependencies: [
                "CryptoSwift",
                "Reachability",
                "Starscream",
            ],
            path: "Sources"
        ),
        .testTarget(
            name: "PusherSwiftTests",
            dependencies: ["PusherSwift"],
            path: "Tests"
        )
    ],
    swiftLanguageVersions: [.v4_2]
)
