// swift-tools-version:5.3

import PackageDescription

let package = Package(
    name: "PusherSwift",
    platforms: [
        .iOS(.v13),
//        .watchOS(.v6),
//        .tvOS(.v13),
//        .macOS(.v10_15)
    ],
    products: [
        .library(name: "PusherSwift", targets: ["PusherSwift"])
    ],
    dependencies: [
        .package(name: "Reachability", url: "https://github.com/ashleymills/Reachability.swift.git", .upToNextMajor(from: "5.0.0")),
        .package(url: "https://github.com/daltoniam/Starscream.git", .upToNextMajor(from: "3.1.0")),
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
