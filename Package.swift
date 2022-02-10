// swift-tools-version:5.3
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "ExtoleMobileSDK",
    platforms: [
        .iOS(.v12)
    ],
    products: [
        .library(
            name: "ExtoleMobileSDK",
            targets: ["ExtoleMobileSDK"])
    ],
    dependencies: [
        .package(name: "ExtoleClientAPI", url: "https://github.com/extole/ios-client-api.git", .upToNextMajor(from: "0.0.1")),
        .package(name: "ExtoleConsumerAPI", url: "https://github.com/extole/ios-consumer-api.git", .upToNextMajor(from: "0.0.1")),
        .package(url: "https://github.com/apple/swift-log.git", from: "1.0.0")
    ],
    targets: [
        .target(
            name: "ExtoleMobileSDK",
            dependencies: [
                "ExtoleClientAPI",
                "ExtoleConsumerAPI",
                .product(name: "Logging", package: "swift-log")
            ]),
        .testTarget(
            name: "ExtoleMobileSDKTests",
            dependencies: ["ExtoleMobileSDK"])
    ],
    swiftLanguageVersions: [.v5]
)
