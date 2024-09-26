// swift-tools-version: 6.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

#if os(Windows)
    let libuvTarget: Target = .systemLibrary(
        name: "Clibuv",
        providers: [
            .brew(["libuv"]),
            .apt(["libuv1-dev"]),
        ]
    )
#else
    let libuvTarget: Target = .systemLibrary(
        name: "Clibuv",
        pkgConfig: "libuv",
        providers: [
            .brew(["libuv"]),
            .apt(["libuv1-dev"]),
        ]
    )
#endif

let package = Package(
    name: "swift-uv",
    platforms: [.macOS(.v14)],
    products: [
        // Products define the executables and libraries a package produces, making them visible to other packages.
        .library(
            name: "UVCore",
            targets: ["UVCore"]
        ),
        .library(
            name: "UVServer",
            targets: ["UVServer"]
        ),
    ],
    targets: [
        // Targets are the basic building blocks of a package, defining a module or a test suite.
        // Targets can depend on other targets in this package and products from dependencies.
        libuvTarget,
        .target(
            name: "UVCore",
            dependencies: [
                "Clibuv",
            ],
            swiftSettings: swiftSettings
        ),
        .target(
            name: "UVServer",
            dependencies: [
                "UVCore",
            ],
            swiftSettings: swiftSettings
        ),
        .executableTarget(
            name: "HelloServer",
            dependencies: [
                "UVCore",
                "UVServer",
            ]
        ),
        .testTarget(
            name: "uvTests",
            dependencies: ["UVCore"],
            swiftSettings: swiftSettings
        ),
    ]
)

let swiftSettings: [SwiftSetting] = [
    // Flags to warn about the type checking getting too slow
    .unsafeFlags(
        [
            "-Xfrontend",
            "-warn-long-function-bodies=100",
            "-Xfrontend",
            "-warn-long-expression-type-checking=100",
        ]
    ),
]
