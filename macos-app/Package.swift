// swift-tools-version:5.10
import PackageDescription

let package = Package(
    name: "OverwatchNode",
    platforms: [.macOS(.v13)],
    dependencies: [
        .package(url: "https://github.com/httpswift/swifter.git", from: "1.5.0")
    ],
    targets: [
        .executableTarget(
            name: "OverwatchNode",
            dependencies: [
                .product(name: "Swifter", package: "swifter")
            ],
            // A bare SPM executable has no Info.plist by default, but
            // Bluetooth access is TCC-protected and requires one with
            // NSBluetoothAlwaysUsageDescription — without this the process
            // hard-crashes (SIGABRT) the first time it's accessed.
            linkerSettings: [
                .unsafeFlags([
                    "-Xlinker", "-sectcreate",
                    "-Xlinker", "__TEXT",
                    "-Xlinker", "__info_plist",
                    "-Xlinker", "Sources/OverwatchNode/Info.plist",
                ])
            ]
        )
    ]
)
