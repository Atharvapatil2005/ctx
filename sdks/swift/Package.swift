// swift-tools-version: 5.9

import PackageDescription

let package = Package(
    name: "CtxMemory",
    platforms: [
        .macOS(.v12)
    ],
    products: [
        .library(
            name: "CtxMemory",
            targets: ["CtxMemory"]
        ),
        .executable(
            name: "LocalMemorySmoke",
            targets: ["LocalMemorySmoke"]
        )
    ],
    targets: [
        .target(
            name: "CtxMemory"
        ),
        .executableTarget(
            name: "LocalMemorySmoke",
            dependencies: ["CtxMemory"],
            path: "Examples/LocalMemorySmoke"
        ),
        .testTarget(
            name: "CtxMemoryTests",
            dependencies: ["CtxMemory"]
        )
    ]
)
