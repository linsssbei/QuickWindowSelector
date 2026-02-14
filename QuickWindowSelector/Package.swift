// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "QuickWindowSelector",
    platforms: [.macOS(.v13)],
    products: [
        .executable(name: "QuickWindowSelector", targets: ["App"])
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-testing", from: "0.1.0")
    ],
    targets: [
        .executableTarget(
            name: "App",
            dependencies: [],
            path: "Sources"
        ),
        .testTarget(
            name: "AppTests",
            dependencies: ["App", .product(name: "Testing", package: "swift-testing")],
            path: "Tests"
        )
    ]
)
