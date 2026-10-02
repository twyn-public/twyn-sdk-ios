// swift-tools-version:5.9
import PackageDescription

// Twyn iOS SDK â€” binary distribution.
//
// The engine is shipped as signed XCFrameworks. Replace the URLs/checksums with
// the values published by twyn-sdk-dist for each release.
//
// NOTE on private hosting: SwiftPM fetches binaryTarget URLs without an
// interactive login, so a PRIVATE GitHub release returns 404. The supported
// path is CocoaPods with `:git => ...twyn-sdk-dist.git` (see README /
// docs/integration.md). To use SwiftPM, host the release asset on a server
// reachable with credentials configured in ~/.netrc and point the URLs there.
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
            checksum: "437688c00493c2c66cb597d1eaa2217325998fcfad5431b05ebcf556cdf6331d"
        ),
        .binaryTarget(
            name: "TwynDeviceCore",
            url: "https://github.com/twyn-internal/twyn-sdk-dist/releases/download/devicecore-0.1.0/TwynDeviceCore.xcframework.zip",
            checksum: "17f58e779786e810c310be22d1562f18bde4106c2e22505ca15c235194d23de3"
        ),
    ]
)
