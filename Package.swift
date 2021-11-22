// swift-tools-version:5.3
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "CustomToolTip",
    platforms: [.macOS(.v10_14)],
    products: [
        .library(
            name: "CustomToolTip",
            targets: ["CustomToolTip"]),
    ],
    dependencies: [
        .package(url: "https://github.com/chipjarred/SwizzleHelper.git", from: "1.0.0")
    ],
    targets: [
        // Targets are the basic building blocks of a package. A target can define a module or a test suite.
        // Targets can depend on other targets in this package, and on products in packages this package depends on.
        .target(
            name: "CustomToolTip",
            dependencies: ["SwizzleHelper"]),
        .testTarget(
            name: "CustomToolTipTests",
            dependencies: ["CustomToolTip"]),
    ]
)
