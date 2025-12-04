// swift-tools-version: 5.9

import PackageDescription

let package = Package(
    name: "PurchaseKit",
    platforms: [
        .iOS(.v16)
    ],
    products: [
        .library(
            name: "PurchaseKit",
            targets: ["PurchaseKit"]
        ),
    ],
    dependencies: [
        .package(url: "https://github.com/apphud/ApphudSDK.git", from: "3.0.0")
    ],
    targets: [
        .target(
            name: "PurchaseKit",
            dependencies: ["ApphudSDK"]
        ),
    ]
)

