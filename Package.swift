// swift-tools-version: 6.1
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "bytecode-vm-swift",
    products: [
        .executable(name: "bytecode-vm-swift", targets: ["bytecode-vm-swift"])
    ],
    targets: [
        .target(
            name: "BytecodeVM",
            path: "Sources",
            exclude: ["CLI"]),
        .executableTarget(
            name: "bytecode-vm-swift",
            dependencies: ["BytecodeVM"],
            path: "Sources/CLI")
    ]
)
