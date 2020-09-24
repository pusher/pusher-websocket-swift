// swift-tools-version:5.0

import PackageDescription

let package = Package(
    name: "PusherSwift",
    products: [
        .library(name: "PusherSwift", targets: ["PusherSwift", "PusherSwiftWithEncryption"])
    ],
    dependencies: [
        .package(url: "https://github.com/ashleymills/Reachability.swift.git", .upToNextMajor(from: "5.1.0")),
        .package(url: "https://github.com/daltoniam/Starscream.git", .upToNextMajor(from: "3.1.0")),
        .package(url: "https://github.com/jedisct1/swift-sodium", .upToNextMajor(from: "0.9.0")),
    ],
    targets: [
        .target(
            name: "PusherSwift",
            dependencies: [
                "Reachability",
                "Starscream",
            ],
            path: "Sources",
        ),
        .target(
            name: "PusherSwiftWithEncryption",
            dependencies: [
                "Reachability",
                "Starscream",
                "Sodium",
            ],
            path: "Sources",
        ),
        .testTarget(
            name: "PusherSwiftTests",
            dependencies: ["PusherSwift"],
            path: "Tests",
        ),
        .testTarget(
            name: "PusherSwiftWithEncryptionTests",
            dependencies: ["PusherSwiftWithEncryption"],
            path: "Tests",
        )
    ],
    swiftLanguageVersions: [.v5]
)
