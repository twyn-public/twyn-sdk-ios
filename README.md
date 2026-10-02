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

**1. Get access + credentials** — ask Twyn to add your GitHub account to the private
repo `twyn-internal/twyn-sdk-dist`. Git then needs to authenticate as you: GitHub no
longer accepts passwords, so configure a **PAT** or **SSH** (see
[Private repo credentials](#private-repo-credentials)).

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
export LANG=en_US.UTF-8   # avoids a CocoaPods/Ruby encoding error
pod install
```

The cores expose a **C ABI** (no Swift modulemap), so add a bridging header:

```objc
// YourApp-Bridging-Header.h
#import "twyn_device_core.h"   // TwynDeviceCore
#import "sentinel_ios.h"       // TwynTrustCore
#import "twyn_runtime.h"       // TwynTrustCore
```
```swift
// installation id (persist it in the Keychain)
if let c = twyn_dc_install_id() { print(String(cString: c)); twyn_dc_free(c) }

// full integrity scan -> ThreatReport JSON (evidence)
if let c = sentinel_ios_analyze_with_schemes(nil, nil, 0, "[]") {
    print(String(cString: c)); sentinel_ios_free(c)
}
```

See `SampleApp/` for the complete, buildable example. Higher-level Swift wrappers
(`TwynDevice`, camera integrity) live in the private `TwynIOSSDK` layer.

> ⚠️ The **final decision is server-side**. The SDK produces capture + integrity
> **evidence**; the authoritative APPROVED / REJECTED comes from your backend.

## Why CocoaPods (and not SwiftPM)

The binaries are **private**. CocoaPods pulls them with your **git credentials**
(private-safe). SwiftPM `binaryTarget` downloads the release asset **without**
credentials, so a private GitHub release returns `404`. If you need SwiftPM, host
the `.xcframework.zip` on a server reachable with `.netrc` (see `Package.swift`).

## Private repo credentials

The binaries live in the private repo `twyn-internal/twyn-sdk-dist`, so git must be
authenticated. GitHub does **not** accept passwords for git; use one of:

- **PAT (HTTPS)** — create a token with read access to the repo, then:
  ```bash
  git config --global url."https://<USER>:<TOKEN>@github.com/".insteadOf "https://github.com/"
  ```
  (or let git store it once in the macOS keychain)
- **SSH** — add your SSH key to GitHub and map HTTPS → SSH:
  ```bash
  git config --global url."git@github.com:".insteadOf "https://github.com/"
  ```

You must also be **added to `twyn-internal`** by Twyn — otherwise GitHub hides the
repo and returns `Repository not found`.

## Troubleshooting

| Symptom | Fix |
|---|---|
| `fatal: could not read Username for 'https://github.com'` | git has no credentials — configure a PAT/SSH (above) |
| `remote: Invalid username or token` / `Authentication failed` | token wrong/expired or lacks access |
| `Repository not found` (404) | your GitHub account isn't a member of `twyn-internal` |
| `pod install` can't find the pod | access/credentials (above) |
| `Encoding::CompatibilityError` | `export LANG=en_US.UTF-8` before `pod install` |
| "Could not select an Xcode project" | run `pod install` inside your project folder |
| `TwynDeviceCore` unresolved | check the tag `ios-0.1.1` and your git credentials |

## License

The **sample code** is released under the MIT License (see `LICENSE`). The SDK
binaries are proprietary and governed by a separate commercial agreement.
