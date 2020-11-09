// swift-tools-version:5.2

import PackageDescription

let package = Package(
    name: "PusherSwift",
    platforms: [
        .iOS(.v13),
        .tvOS(.v13),
        .macOS(.v10_15)
    ],
    products: [
        .library(name: "PusherSwift", targets: ["PusherSwift"])
    ],
    dependencies: [
        .package(name: "Reachability", 
                 url: "https://github.com/ashleymills/Reachability.swift.git", 
                 .upToNextMajor(from: "5.0.0")),
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
            exclude: ["PusherSwiftWithEncryption-Only"]
        )
    ],
    swiftLanguageVersions: [.v5]
)
