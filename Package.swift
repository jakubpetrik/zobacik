// swift-tools-version: 6.2

import PackageDescription

let package = Package(
    name: "Zobacik",
    platforms: [.macOS(.v13)],
    products: [
        .executable(name: "Zobacik", targets: ["Zobacik"])
    ],
    targets: [
        .executableTarget(name: "Zobacik"),
        .testTarget(name: "ZobacikTests", dependencies: ["Zobacik"])
    ]
)
