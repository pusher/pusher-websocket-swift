// swift-tools-version:4.2

import PackageDescription

let package = Package(
    name: "PusherSwift",
    products: [
        .library(name: "PusherSwift", targets: ["PusherSwift"])
    ],
    dependencies: [
        .package(url: "https://github.com/krzyzanowskim/CryptoSwift.git", .upToNextMajor(from: "0.9.0")),
        .package(url: "https://github.com/ashleymills/Reachability.swift.git", .exact("4.3.0")),
        .package(url: "https://github.com/daltoniam/Starscream.git", .upToNextMinor(from: "3.0.5")),
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
