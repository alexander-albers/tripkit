// swift-tools-version:5.0
import PackageDescription

let package = Package(
    name: "TripKit",
    platforms: [
        .macOS(.v10_12), .iOS(.v10), .tvOS(.v10), .watchOS(.v3)
    ],
    products: [
        .library(name: "TripKit", targets: ["TripKit"])
    ],
    dependencies: [
        .package(url: "https://github.com/1024jp/GzipSwift", from: 5.1.1),
        .package(url: "https://github.com/SwiftyJSON/SwiftyJSON", from: 5.0.0),
        .package(url: "https://github.com/drmohundro/SWXMLHash", from: 5.0.1),
    ],
    targets: [
        .target(name: "TripKit", dependencies: ["Gzip", "SwiftyJSON", "SWXMLHash"]),
        .testTarget(name: "TripKitTests iOS", dependencies: ["TripKit"])
    ],
    swiftLanguageVersions: [.v5]
)
