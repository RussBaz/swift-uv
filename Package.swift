// swift-tools-version: 6.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

// Libuv build pricess is inspired by
// https://github.com/MarSe32m/sebbu-c-libuv
var sources: [String] = []

let sourcesCommon = [
    "src/uv/errno.h",
    "src/uv/threadpool.h",
    "src/uv/tree.h",
    "src/uv.h",
    "src/uv/version.h",
    "src/fs-poll.c",
    "src/heap-inl.h",
    "src/idna.c",
    "src/idna.h",
    "src/inet.c",
    "src/queue.h",
    "src/random.c",
    "src/strscpy.c",
    "src/strscpy.h",
    "src/strtok.c",
    "src/strtok.h",
    "src/thread-common.c",
    "src/threadpool.c",
    "src/timer.c",
    "src/uv-common.c",
    "src/uv-common.h",
    "src/uv-data-getter-setters.c",
    "src/version.c",
]

let unixSourcesCommon = [
    "src/uv/unix.h",
    "src/unix/async.c",
    "src/unix/core.c",
    "src/unix/dl.c",
    "src/unix/fs.c",
    "src/unix/getaddrinfo.c",
    "src/unix/getnameinfo.c",
    "src/unix/internal.h",
    "src/unix/loop-watcher.c",
    "src/unix/loop.c",
    "src/unix/pipe.c",
    "src/unix/poll.c",
    "src/unix/process.c",
    "src/unix/random-devurandom.c",
    "src/unix/signal.c",
    "src/unix/stream.c",
    "src/unix/tcp.c",
    "src/unix/thread.c",
    "src/unix/tty.c",
    "src/unix/udp.c",
]

#if os(Windows)
    sources.append(contentsOf: sourcesCommon)
    sources.append("src/uv/win.h")
    sources.append("src/win")
#elseif canImport(Darwin)
    sources.append(contentsOf: sourcesCommon)
    sources.append("src/uv/darwin.h")
    sources.append(contentsOf: unixSourcesCommon)
    sources.append("src/unix/proctitle.c")
    sources.append("src/unix/darwin-proctitle.c")
    sources.append("src/unix/darwin-stub.h")
    sources.append("src/unix/darwin.c")
    sources.append("src/unix/fsevents.c")
    sources.append("src/unix/bsd-ifaddrs.c")
    sources.append("src/unix/kqueue.c")
    sources.append("src/unix/random-getentropy.c")
#elseif os(Linux)
    sources.append(contentsOf: sourcesCommon)
    sources.append("src/uv/linux.h")
    sources.append(contentsOf: unixSourcesCommon)
    sources.append("src/unix/proctitle.c")
    sources.append("src/unix/linux.c")
    sources.append("src/unix/procfs-exepath.c")
    sources.append("src/unix/random-getrandom.c")
    sources.append("src/unix/random-sysctl-linux.c")
#else
    #error("Unsupported platform")
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
    dependencies: [
        .package(url: "https://github.com/RussBaz/mini-alloc", from: "1.0.2"),
        .package(url: "https://github.com/apple/swift-collections.git", from: "1.1.4"),
    ],
    targets: [
        // Targets are the basic building blocks of a package, defining a module or a test suite.
        // Targets can depend on other targets in this package and products from dependencies.
        .target(
            name: "UVCore",
            dependencies: [
                "Clibuv",
                .product(name: "MA", package: "mini-alloc"),
                .product(name: "Collections", package: "swift-collections"),
            ],
            swiftSettings: swiftSettings
        ),
        .target(
            name: "Clibuv",
            sources: sources,
            cSettings: [
                .define("WIN32_LEAN_AND_MEAN", .when(platforms: [.windows])),
                .define("_WIN32_WINNT", to: "0x0602", .when(platforms: [.windows])),
                .define("_CRT_DECLARE_NONSTDC_NAMES", to: "0", .when(platforms: [.windows])),
                .define("_FILE_OFFSET_BITS", to: "64", .when(platforms: [.macOS, .iOS, .linux])),
                .define("_LARGEFILE_SOURCE", .when(platforms: [.macOS, .iOS, .linux])),
                .define("_DARWIN_UNLIMITED_SELECT", to: "1", .when(platforms: [.macOS, .iOS])),
                .define("_DARWIN_USE_64_BIT_INODE", to: "1", .when(platforms: [.macOS, .iOS])),
                .define("_GNU_SOURCE", .when(platforms: [.linux])),
                .define("_POSIX_C_SOURCE", to: "200112", .when(platforms: [.linux])),
                .headerSearchPath("./src"),
            ],
            linkerSettings: [
                .linkedLibrary("psapi", .when(platforms: [.windows])),
                .linkedLibrary("User32", .when(platforms: [.windows])),
                .linkedLibrary("AdvAPI32", .when(platforms: [.windows])),
                .linkedLibrary("iphlpapi", .when(platforms: [.windows])),
                .linkedLibrary("UserEnv", .when(platforms: [.windows])),
                .linkedLibrary("WS2_32", .when(platforms: [.windows])),
                .linkedLibrary("DbgHelp", .when(platforms: [.windows])),
                .linkedLibrary("ole32", .when(platforms: [.windows])),
                .linkedLibrary("shell32", .when(platforms: [.windows])),
                .linkedLibrary("pthread", .when(platforms: [.macOS, .iOS, .linux])),
                .linkedLibrary("dl", .when(platforms: [.linux])),
                .linkedLibrary("rt", .when(platforms: [.linux])),
            ]
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
