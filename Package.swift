// swift-tools-version: 5.9
// NovaBrowser - Swift Package Manager configuration
// This enables building without Xcode project dependencies

import PackageDescription

let package = Package(
    name: "NovaBrowser",
    platforms: [
        .iOS(.v15)
    ],
    products: [
        .library(
            name: "NovaBrowserLib",
            targets: ["NovaBrowserLib"]
        )
    ],
    targets: [
        .target(
            name: "NovaBrowserLib",
            path: "NovaBrowser/Sources"
        )
    ]
)
