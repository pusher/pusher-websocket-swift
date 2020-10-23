// swift-tools-version:5.0

import PackageDescription

let package = Package(
    name: "PusherSwift",
    platforms: [.iOS("13.0"), .macOS("10.15"), .tvOS("13.0")],
    products: [
        .library(name: "PusherSwift", targets: ["PusherSwift"])
    ],
    dependencies: [
        .package(url: "https://github.com/ashleymills/Reachability.swift.git", .upToNextMajor(from: "5.0.0")),
        .package(url: "https://github.com/pusher/NWWebSocket.git", .upToNextMajor(from: "0.3.0")),
    ],
    targets: [
        .target(
            name: "PusherSwift",
            dependencies: [
                "Reachability",
                "NWWebSocket",
            ],
            path: "Sources",
            exclude: ["PusherSwiftWithEncryption-Only"]
        ),
        .testTarget(
            name: "PusherSwiftTests",
            dependencies: ["PusherSwift"],
            path: "Tests",
            exclude: ["Unit/PusherSwiftWithEncryption-Only"]
        )
    ],
    swiftLanguageVersions: [.v5]
)
