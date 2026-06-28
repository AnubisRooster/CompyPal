// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "Companion",
    platforms: [
        .iOS(.v17)
    ],
    dependencies: [
        .package(url: "https://github.com/groue/GRDB.swift", from: "6.29.0"),
    ],
    targets: [
        .target(
            name: "Companion",
            dependencies: [
                .product(name: "GRDB", package: "GRDB.swift"),
            ],
            path: "Companion"
        ),
        .testTarget(
            name: "CompanionTests",
            dependencies: ["Companion"],
            path: "CompanionTests"
        ),
    ]
)
