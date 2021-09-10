// swift-tools-version:5.3
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
        .package(name: "Gzip", url: "https://github.com/1024jp/GzipSwift", from: "5.1.1"),
        .package(name: "SwiftyJSON", url: "https://github.com/SwiftyJSON/SwiftyJSON", from: "5.0.0"),
        .package(name: "SWXMLHash", url: "https://github.com/drmohundro/SWXMLHash", from: "5.0.1"),
    ],
    targets: [
        .target(name: "TripKit", dependencies: ["Gzip", "SwiftyJSON", "SWXMLHash"], resources: [.process("Resources")]),
        
        // Tests
        .target(name: "TestsCommon", dependencies: ["TripKit"], path: "Tests/TestsCommon", resources: [.copy("Resources/Test Cases"), .copy("Resources/Fixtures")]),
        .testTarget(name: "StaticTripKitTests", dependencies: ["TripKit", "TestsCommon"]),
        .testTarget(name: "TripKitTests", dependencies: ["TripKit", "TestsCommon"]),
    ],
    swiftLanguageVersions: [.v5]
)
