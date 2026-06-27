// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "Companion",
    platforms: [
        .iOS(.v17)
    ],
    products: [
        .library(
            name: "Companion",
            targets: ["Companion"]
        ),
    ],
    targets: [
        .target(
            name: "Companion",
            dependencies: [],
            path: "Companion"
        ),
        .testTarget(
            name: "CompanionTests",
            dependencies: ["Companion"],
            path: "CompanionTests"
        ),
    ]
)
