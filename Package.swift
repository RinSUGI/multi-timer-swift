// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "multi-timer",
    platforms: [.macOS(.v13)],
    products: [
        .executable(name: "multi-timer", targets: ["MultiTimerApp"]),
    ],
    targets: [
        .target(
            name: "MultiTimerCore",
            dependencies: []
        ),
        .target(
            name: "MultiTimerStorage",
            dependencies: ["MultiTimerCore"]
        ),
        .executableTarget(
            name: "MultiTimerApp",
            dependencies: ["MultiTimerCore", "MultiTimerStorage"],
            resources: [.process("Resources")]
        ),
        .testTarget(
            name: "MultiTimerCoreTests",
            dependencies: ["MultiTimerCore"]
        ),
        .testTarget(
            name: "MultiTimerStorageTests",
            dependencies: ["MultiTimerStorage", "MultiTimerCore"]
        ),
    ]
)
