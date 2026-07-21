// swift-tools-version: 5.9

import PackageDescription

let productName = "core"
    .split(separator: "_")
    .joined(separator: "-")

let package = Package(
    name: "core",
    platforms: [
        .iOS("13.0"),
    ],
    products: [
        .library(
            name: productName,
            targets: ["core"]
        ),
    ],
    dependencies: [
        .package(name: "FlutterFramework", path: "../FlutterFramework"),
    ],
    targets: [
        .target(
            name: "core",
            dependencies: [
                .product(name: "FlutterFramework", package: "FlutterFramework"),
            ]
        ),
    ]
)
