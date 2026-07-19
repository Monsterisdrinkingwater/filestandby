// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "FileStandby",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .executable(name: "FileStandby", targets: ["FileStandby"])
    ],
    targets: [
        .executableTarget(
            name: "FileStandby",
            path: "Sources/FileStandby"
        ),
        .testTarget(
            name: "FileStandbyTests",
            dependencies: ["FileStandby"],
            path: "Tests/FileStandbyTests",
            exclude: ["EdgeHandleTests 2.swift"]
        )
    ]
)
