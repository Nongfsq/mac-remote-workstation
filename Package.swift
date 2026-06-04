// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "MacRemoteWorkstation",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .executable(name: "RemoteWorkstationApp", targets: ["RemoteWorkstationApp"]),
        .executable(name: "RemoteWorkstationHelper", targets: ["RemoteWorkstationHelper"]),
        .library(name: "RemoteWorkstationCore", targets: ["RemoteWorkstationCore"]),
        .library(name: "RemoteWorkstationService", targets: ["RemoteWorkstationService"])
    ],
    targets: [
        .target(
            name: "RemoteWorkstationCore"
        ),
        .target(
            name: "RemoteWorkstationService",
            dependencies: ["RemoteWorkstationCore"]
        ),
        .executableTarget(
            name: "RemoteWorkstationApp",
            dependencies: [
                "RemoteWorkstationCore",
                "RemoteWorkstationService"
            ],
            linkerSettings: [
                .linkedFramework("AppKit"),
                .linkedFramework("IOKit"),
                .linkedFramework("ServiceManagement")
            ]
        ),
        .executableTarget(
            name: "RemoteWorkstationHelper",
            dependencies: [
                "RemoteWorkstationCore",
                "RemoteWorkstationService"
            ]
        ),
        .testTarget(
            name: "RemoteWorkstationCoreTests",
            dependencies: ["RemoteWorkstationCore"]
        ),
        .testTarget(
            name: "RemoteWorkstationServiceTests",
            dependencies: [
                "RemoteWorkstationCore",
                "RemoteWorkstationService"
            ]
        )
    ]
)
