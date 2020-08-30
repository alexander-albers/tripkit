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
    targets: [
        .target(name: "TripKit", dependencies: ["Gzip", "SwiftyJSON", "SWXMLHash"]),
        .testTarget(name: "TripKitTests iOS", dependencies: ["TripKit"])
    ],
    swiftLanguageVersions: [.v5]
)
