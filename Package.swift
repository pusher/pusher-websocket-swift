// swift-tools-version:5.0

import PackageDescription

let package = Package(
    name: "PusherSwift",
    platforms: [.iOS("15.0"), .macOS("12.0"), .tvOS("15.0")],
    products: [
        .library(name: "PusherSwift", targets: ["PusherSwift"])
    ],
    dependencies: [
        .package(url: "https://github.com/pusher/NWWebSocket.git", .upToNextMajor(from: "1.0.0")),
        .package(url: "https://github.com/pusher/tweetnacl-swiftwrap", .upToNextMajor(from: "1.3.0")),
    ],
    targets: [
        .target(
            name: "PusherSwift",
            dependencies: [
                "NWWebSocket",
                "TweetNacl",
            ],
            path: "Sources"
        ),
        .testTarget(
            name: "PusherSwiftTests",
            dependencies: ["PusherSwift"],
            path: "Tests"
        )
    ],
    swiftLanguageVersions: [.v5]
)
