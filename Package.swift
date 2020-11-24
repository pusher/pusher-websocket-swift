// swift-tools-version:5.0

import PackageDescription

let package = Package(
    name: "PusherSwift",
    platforms: [.iOS("13.0"), .macOS("10.15"), .tvOS("13.0")],
    products: [
        .library(name: "PusherSwift", targets: ["PusherSwiftWithEncryption"])
    ],
    dependencies: [
        .package(url: "https://github.com/ashleymills/Reachability.swift.git", .upToNextMajor(from: "5.0.0")),
        .package(url: "https://github.com/pusher/NWWebSocket.git", .upToNextMajor(from: "0.3.0")),
        .package(url: "https://github.com/bitmark-inc/tweetnacl-swiftwrap", .upToNextMajor(from: "1.0.0")),
    ],
    targets: [
        .target(
            name: "PusherSwiftWithEncryption",
            dependencies: [
                "Reachability",
                "NWWebSocket",
                "TweetNacl",
            ],
            path: "Sources",
            exclude: ["PusherSwift-Only"]
        ),
        .testTarget(
            name: "PusherSwiftWithEncryptionTests",
            dependencies: ["PusherSwiftWithEncryption"],
            path: "Tests",
            exclude: ["Unit/PusherSwift-Only"],
            swiftSettings: [.define("WITH_ENCRYPTION")]
        )
    ],
    swiftLanguageVersions: [.v5]
)
