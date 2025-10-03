// swift-tools-version:5.5
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "ExtoleMobileSDK",
    platforms: [
        .iOS(.v13)
    ],
    products: [
        .library(
            name: "ExtoleMobileSDK",
            targets: ["ExtoleMobileSDK"])
    ],
    dependencies: [
        .package(name: "ExtoleConsumerAPI", url: "https://github.com/extole/ios-consumer-api.git", .upToNextMajor(from: "0.0.1")),
        .package(url: "https://github.com/apple/swift-log.git", from: "1.0.0"),
        .package(url: "https://github.com/tristanhimmelman/ObjectMapper.git", from: "4.4.2"),
        .package(url: "https://github.com/daniftodi/SwiftEventBus.git", from: "5.1.4")
    ],
    targets: [
        .target(
            name: "ExtoleMobileSDK",
            dependencies: [
                "ExtoleConsumerAPI",
                .product(name: "Logging", package: "swift-log"),
                .product(name: "ObjectMapper", package: "ObjectMapper"),
                .product(name: "SwiftEventBus", package: "SwiftEventBus")
            ],
            cSettings: [
                .define("IPHONEOS_DEPLOYMENT_TARGET", to: "13.0")
            ]),
        .testTarget(
            name: "ExtoleMobileSDKTests",
            dependencies: ["ExtoleMobileSDK"])
    ]
)
