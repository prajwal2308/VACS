// swift-tools-version: 5.9
// Convenience manifest for people with full Xcode installed (File → Open → Package.swift).
// The primary, Xcode-free build is ./scripts/build-app.sh (plain swiftc — works with
// just Command Line Tools).
import PackageDescription

let package = Package(
    name: "VACS",
    platforms: [.macOS(.v14)],
    targets: [
        .executableTarget(
            name: "VACS",
            path: "Sources/VACS",
            resources: [.process("Resources")]
        ),
    ]
)
