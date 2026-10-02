# twyn-sdk-ios â€” integration sample

> Public integration sample for the **Twyn iOS SDK** (runtime-integrity / device
> identity over the T4FastID liveness flow). This repository contains **no
> proprietary logic** â€” it consumes the engine as signed `.xcframework` binaries
> from the private distribution repo.

## What is here

| Path | Purpose |
|---|---|
| `SampleApp/` | Minimal iOS app wiring the SDK |
| `Package.swift` | Swift Package manifest (binary targets) |
| `docs/integration.md` | Step-by-step integration guide |
| `.github/workflows/ci.yml` | Builds the sample on macOS against the released binaries |

## SDK artifacts

| Artifact | Type | Notes |
|---|---|---|
| `TwynTrustCore` | `.xcframework` (static) | runtime-integrity probes (anti-instrumentation) |
| `TwynDeviceCore` | `.xcframework` (static) | device identity / continuity |
| `T4Touchless` | CocoaPod (vendor) | liveness / face capture UI |

- Deployment target: **iOS 15.6**
- Architectures: `arm64` (device) + `arm64/x86_64` (simulator)

## Distribution

The binaries are **private**. Two supported paths:

- **CocoaPods (recommended for private orgs)** â€” a private spec repo hosted at
  `github.com/twyn-internal/twyn-sdk-dist`, with the `.xcframework` zip as a signed release
  asset. See `docs/integration.md`.
- **Swift Package Manager** â€” a `binaryTarget` with `url` + `checksum`. Works when
  the host is reachable with credentials (e.g. `.netrc`); see `Package.swift`.

## Quick start (CocoaPods)

```ruby
# Podfile
platform :ios, '15.6'

source 'https://cdn.cocoapods.org'
source 'https://github.com/twyn-internal/twyn-sdk-dist.git'   # private spec repo

target 'YourApp' do
  use_frameworks!

  pod 'T4Touchless'                       # vendor liveness SDK
  pod 'TwynTrustCore', '~> 0.1'           # our runtime-integrity core
  pod 'TwynDeviceCore', '~> 0.1'          # device identity / continuity
end
```

Then in code:

```swift
import TwynTrustCore
import TwynDeviceCore

// 1) Device identity / continuity (App Attest + DeviceCheck).
let ev = try await TwynDevice.shared.evaluate(personId: personId)

// 2) Liveness â€” the vendor SDK drives the camera; results come back via delegate.
//    See SampleApp for the full wiring.
```

> **Security:** the authoritative decision (APPROVED / REJECTED) is made
> **server-side**. The SDK produces capture + integrity **evidence**; the decision
> comes from the gateway.

## License

The **sample code** is released under the MIT License (see `LICENSE`). The SDK
binaries are proprietary and governed by a separate commercial agreement.
