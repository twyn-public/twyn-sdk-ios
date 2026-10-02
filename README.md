# Twyn iOS SDK — integration sample

> Everything you need to integrate the **Twyn iOS SDK**: a working sample, a
> step-by-step guide, and the SDK shipped as signed `.xcframework` binaries from a
> private repository.
>
> This repo contains **no proprietary logic** — only the integration surface.

## Start here

| I want to… | Go to |
|---|---|
| **integrate the SDK in my app** | [`docs/integration.md`](docs/integration.md) (10-minute guide) |
| **see it working first** | `SampleApp/` — open in Xcode and run |
| **understand the options** | [`docs/integration.md`](docs/integration.md) → *Options reference* |

## SDK at a glance

| Artifact | Type | What it is |
|---|---|---|
| `TwynTrustCore` | `.xcframework` (static) | runtime-integrity probes (anti-instrumentation) |
| `TwynDeviceCore` | `.xcframework` (static) | device identity / continuity (App Attest, DeviceCheck) |
| `T4Touchless` | CocoaPod (vendor) | liveness / face capture UI |

- Deployment target: **iOS 15.6+**
- Architectures: `arm64` (device) + `arm64/x86_64` (simulator)

## Quick start (CocoaPods — recommended)

**1. Get access** — ask Twyn for access to the private repo `twyn-internal/twyn-sdk-dist`
(we add your GitHub account; you use your own git credentials).

**2. Podfile:**
```ruby
platform :ios, '15.6'

target 'YourApp' do
  use_frameworks!

  # Twyn binaries — pulled from the private repo with your git credentials.
  pod 'TwynTrustCore', :git => 'https://github.com/twyn-internal/twyn-sdk-dist.git', :tag => 'ios-0.1.1'
  pod 'TwynDeviceCore', :git => 'https://github.com/twyn-internal/twyn-sdk-dist.git', :tag => 'ios-0.1.1'

  # Vendor liveness SDK (provided by Twyn).
  pod 'T4Touchless'
end
```

**3. Install & code:**
```bash
pod install
```
```swift
import TwynTrustCore
import TwynDeviceCore

// device identity / continuity (App Attest + DeviceCheck)
let ev = try await TwynDevice.shared.evaluate(personId: personId)

// liveness — the vendor SDK drives the camera; see SampleApp for the wiring.
```

> ⚠️ The **final decision is server-side**. The SDK produces capture + integrity
> **evidence**; the authoritative APPROVED / REJECTED comes from your backend.

## Why CocoaPods (and not SwiftPM)

The binaries are **private**. CocoaPods pulls them with your **git credentials**
(private-safe). SwiftPM `binaryTarget` downloads the release asset **without**
credentials, so a private GitHub release returns `404`. If you need SwiftPM, host
the `.xcframework.zip` on a server reachable with `.netrc` (see `Package.swift`).

## Troubleshooting

| Symptom | Fix |
|---|---|
| `pod install` can't find the pod | your GitHub account isn't added to `twyn-internal/twyn-sdk-dist` |
| `Encoding::CompatibilityError` | `export LANG=en_US.UTF-8` before `pod install` |
| "Could not select an Xcode project" | run `pod install` inside your project folder |
| `TwynDeviceCore` unresolved | check the tag `ios-0.1.1` and your git credentials |

## License

The **sample code** is released under the MIT License (see `LICENSE`). The SDK
binaries are proprietary and governed by a separate commercial agreement.
