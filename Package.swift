// swift-tools-version:5.1

import PackageDescription

let package = Package(
    name: "PusherSwift",
    products: [
        .library(name: "PusherSwift", targets: ["PusherSwift"])
    ],
    dependencies: [
        .package(url: "https://github.com/ashleymills/Reachability.swift.git", .upToNextMajor(from: "5.0.0")),
        .package(url: "https://github.com/daltoniam/Starscream.git", .exact("3.0.6")),
    ],
    targets: [
        .target(
            name: "PusherSwift",
            dependencies: [
                "Reachability",
                "Starscream",
            ],
            path: "Sources",
            exclude: ["PusherSwiftWithEncryption-Only"]
        ),
        .testTarget(
            name: "PusherSwiftTests",
            dependencies: ["PusherSwift"],
            path: "Tests",
            exclude: ["PusherSwiftWithEncryption-Only"]
        )
    ],
    swiftLanguageVersions: [.v5]
)
