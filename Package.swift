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
            name: "Wrangler",
            targets: ["WranglerApp"]
        ),
        .executable(
            name: "wrangler-cli",
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
            name: "WranglerApp",
            dependencies: ["WranglerCore"],
            path: "Sources/WranglerApp"
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
