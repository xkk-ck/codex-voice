// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "CodexVoice",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .executable(name: "CodexVoice", targets: ["CodexVoice"])
    ],
    targets: [
        .executableTarget(
            name: "CodexVoice",
            path: "Sources/CodexVoice"
        )
    ]
)
