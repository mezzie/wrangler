// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "Wrangler",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .library(
            name: "WranglerCore",
            targets: ["WranglerCore"]
        ),
        .executable(
            name: "wrangler",
            targets: ["WranglerCLI"]
        )
    ],
    targets: [
        .target(
            name: "WranglerCore",
            dependencies: [],
            path: "Sources/WranglerCore"
        ),
        .executableTarget(
            name: "WranglerCLI",
            dependencies: ["WranglerCore"],
            path: "Sources/WranglerCLI"
        ),
        .testTarget(
            name: "WranglerCoreTests",
            dependencies: ["WranglerCore"],
            path: "Tests/WranglerCoreTests"
        )
    ]
)
