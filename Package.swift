// swift-tools-version: 6.0
// Slow Quit Apps - macOS utility to prevent accidental Cmd+Q presses

import PackageDescription

let package = Package(
    name: "SlowQuitApps",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .executable(name: "SlowQuitApps", targets: ["SlowQuitApps"])
    ],
    targets: [
        .executableTarget(
            name: "SlowQuitApps",
            path: "Sources/SlowQuitApps",
            resources: [
                .copy("Resources/Locales")
            ]
        )
    ]
)
