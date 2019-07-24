// swift-tools-version:5.0

import PackageDescription

let package = Package(
    name: "PusherSwift",
    products: [
        .library(name: "PusherSwift", targets: ["PusherSwift"])
    ],
    dependencies: [
        .package(url: "https://github.com/krzyzanowskim/CryptoSwift.git", from: "1.0.0"),
        .package(url: "https://github.com/ashleymills/Reachability.swift.git", from: "4.3.1"),
        .package(url: "https://github.com/daltoniam/Starscream.git", from: "3.1.0"),
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
        )
    ]
)
