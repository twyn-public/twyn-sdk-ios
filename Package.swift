// swift-tools-version:5.9
import PackageDescription

// Twyn iOS SDK â€” binary distribution.
//
// The engine is shipped as signed XCFrameworks. Replace the URLs/checksums with
// the values published by twyn-sdk-dist for each release.
//
// NOTE on private hosting: SwiftPM fetches binaryTarget URLs without an
// interactive login. For a private repo, either (a) host the release asset on a
// server reachable with credentials configured in ~/.netrc, or (b) use CocoaPods
// with the private spec repo (see README / docs/integration.md).
//
// checksum = `swift package compute-checksum <artifact>.zip`

let package = Package(
    name: "TwynSDK",
    platforms: [
        .iOS(.v15)
    ],
    products: [
        .library(name: "TwynTrustCore", targets: ["TwynTrustCore"]),
        .library(name: "TwynDeviceCore", targets: ["TwynDeviceCore"]),
    ],
    targets: [
        .binaryTarget(
            name: "TwynTrustCore",
            url: "https://github.com/twyn-internal/twyn-sdk-dist/releases/download/trustcore-0.1.0/TwynTrustCore.xcframework.zip",
            checksum: "0000000000000000000000000000000000000000000000000000000000000000"
        ),
        .binaryTarget(
            name: "TwynDeviceCore",
            url: "https://github.com/twyn-internal/twyn-sdk-dist/releases/download/devicecore-0.1.0/TwynDeviceCore.xcframework.zip",
            checksum: "0000000000000000000000000000000000000000000000000000000000000000"
        ),
    ]
)
