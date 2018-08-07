// swift-tools-version:4.0

import PackageDescription

let package = Package(
    name: "Swiftygram",
    products: [
        .library(
            name: "Swiftygram",
            targets: ["Swiftygram"]
        ),
    ],
    targets: [
        .target(
            name: "Swiftygram",
            dependencies: []
        ),
        .testTarget(
            name: "SwiftygramTests",
            dependencies: ["Swiftygram"]
        ),
    ]
)
