// swift-tools-version: 5.8
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "TinodeChatSDK",
    defaultLocalization: "en",
    platforms: [
        .iOS(.v13)
    ],
    products: [
        // Products define the executables and libraries a package produces, and make them visible to other packages.
        .library(
            name: "TinodeChatSDK",
            targets: ["TinodeChatSDK"]),
    ],
    dependencies: [
        // Dependencies declare other packages that this package depends on.
        // .package(url: /* package url */, from: "1.0.0"),
        .package(url: "https://github.com/wirasetiawan29/TinodiosDB", branch: "main"),
        .package(url: "https://github.com/grpc/grpc-swift.git", exact: "1.7.3"),
        .package(url: "https://github.com/onevcat/Kingfisher", exact: "7.9.1"),
        .package(url: "https://github.com/instaply/MobileVLCKit.git", exact: "3.4.0"),
        .package(url: "https://github.com/stasel/WebRTC", exact: "116.0.0"),
        .package(url: "https://github.com/firebase/firebase-ios-sdk.git", exact: "10.15.0"),
        .package(url: "https://github.com/marmelroy/PhoneNumberKit", exact: "3.6.8")
    ],
    targets: [
        // Targets are the basic building blocks of a package. A target can define a module or a test suite.
        // Targets can depend on other targets in this package, and on products in packages this package depends on.
        .target(
            name: "TinodeChatSDK",
            dependencies: [
                .product(name: "TinodiosDB", package: "TinodiosDB"),
                .product(name: "GRPC", package: "grpc-swift"),
                .product(name: "Kingfisher", package: "Kingfisher"),
                .product(name: "MobileVLCKit", package: "MobileVLCKit"),
                .product(name: "WebRTC", package: "WebRTC"),
                .product(name: "FirebaseCrashlytics", package: "firebase-ios-sdk"),
                .product(name: "FirebaseAnalytics", package: "firebase-ios-sdk"),
                .product(name: "FirebaseMessaging", package: "firebase-ios-sdk"),
                .product(name: "PhoneNumberKit", package: "PhoneNumberKit"),
            ]),
        .testTarget(
            name: "TinodeChatSDKTests",
            dependencies: ["TinodeChatSDK"]),
    ]
)
