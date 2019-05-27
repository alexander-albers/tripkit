// swift-tools-version:5.0

import PackageDescription

let package = Package(
    name: "TripKit",
    platforms: [
        .macOS(.v10_13),
        .iOS(.v11),
        .watchOS(.v4),
        .tvOS(.v11)
    ],
    products: [
        .library(
            name: "TripKit",
            targets: ["TripKit"]),
    ],
    dependencies: [
        .package(url: "https://github.com/1024jp/GzipSwift", from: "5.0.0"),
        .package(url: "https://github.com/drmohundro/SWXMLHash", from: "4.9.0"),
        .package(url: "https://github.com/SwiftyJSON/SwiftyJSON", from: "4.0.0")
    ],
    targets: [
        .target(
            name: "TripKit",
            dependencies: ["Gzip", "SWXMLHash", "SwiftyJSON"],
            path: "TripKit"),
        .testTarget(
            name: "TripKitTests",
            dependencies: ["TripKit"],
            path: "TripKitTests"),
    ]
)
