# Twyn iOS SDK — integration sample

> Everything you need to integrate the **Twyn iOS SDK**: a working sample and a
> step-by-step guide. The SDK itself (face liveness + device integrity) is shipped
> as a private CocoaPod from a private repository.
>
> This repo contains **no proprietary logic** — only the integration surface.

## Start here

| I want to… | Go to |
|---|---|
| **integrate the SDK in my app** | [`docs/integration.md`](docs/integration.md) (10-minute guide) |
| **see it working first** | `SampleApp/` — open `TwynSampleApp.xcworkspace` and run |
| **understand the options** | [`docs/integration.md`](docs/integration.md) → *Options reference* |

## SDK at a glance

| Artifact | Type | What it is |
|---|---|---|
| `TwynIOSSDK` | CocoaPod (private, source) | the whole SDK: face liveness + enrollment UI + Twyn camera/device layers |
| `TwynTrustCore` | `.xcframework` (private) | runtime-integrity probes (anti-instrumentation) |
| `TwynDeviceCore` | `.xcframework` (private) | device identity / continuity (App Attest, DeviceCheck) |
| `TwynFastID` | CocoaPod (private, vendor) | optional on-device finger engine (not needed for the face flow) |

- Deployment target: **iOS 15.6+**
- Architectures: `arm64` (device) + `arm64/x86_64` (simulator)

## Quick start (CocoaPods)

**1. Get access + credentials** — ask Twyn to add your GitHub account to
`twyn-internal` (repos `twyn-ios-sdk` and `twyn-sdk-dist`). Git then needs to
authenticate as you: GitHub no longer accepts passwords, so configure a **PAT** or
**SSH** (see [Private repo credentials](#private-repo-credentials)). Verify first:

```bash
bash scripts/check-access.sh
```

**2. Podfile:**
```ruby
platform :ios, '15.6'

target 'YourApp' do
  use_frameworks! :linkage => :static   # the cores are static binaries

  # The Twyn SDK (private). Pulled with your git credentials.
  pod 'TwynIOSSDK',    :git => 'https://github.com/twyn-internal/twyn-ios-sdk.git',  :tag => 'ios-0.1.6'
  pod 'TwynTrustCore', :git => 'https://github.com/twyn-internal/twyn-sdk-dist.git', :tag => 'ios-0.2.0'
  pod 'TwynDeviceCore',:git => 'https://github.com/twyn-internal/twyn-sdk-dist.git', :tag => 'ios-0.2.0'
end

# Xcode 26+ requires iOS >= 15.0 for every pod target.
post_install do |installer|
  installer.pods_project.targets.each do |t|
    t.build_configurations.each do |c|
      c.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = '15.6'
      c.build_settings['BUILD_LIBRARY_FOR_DISTRIBUTION'] = 'YES'
    end
  end
end
```

**3. Install & code:**
```bash
export LANG=en_US.UTF-8   # avoids a CocoaPods/Ruby encoding error
pod install
```
```swift
import TwynIOSSDK

// Present the SDK and receive the callbacks — no capture logic in your app.
let sdk = T4FastIDSDK()
sdk.delegate = self
sdk.sdkKey = "<your-sdk-key>"
sdk.personId = personId
sdk.canal = "TWYN"
sdk.env = "dev"                 // "dev" or "prod"
sdk.requestSteps = ["T4_FACE"]
present(sdk, animated: true)

// T4FastIDDelegate
func onEnrollFaceCompleted(isAlive: Bool, imageDataString: String, tcn: String) { }
func onEnrollFaceError(code: Int, message: String) { }
```

The SDK runs the face capture, the Twyn camera-integrity challenge, the Sentinel
device scan, App Attest, and submits everything to the gateway. See `SampleApp/`
for the full example (including the **APROVADO / REPROVADO** result dialog read
from the gateway audit API).

> The **final decision is server-side**. The SDK produces capture + integrity
> **evidence**; the authoritative APPROVED / REJECTED comes from the gateway.

## Private repo credentials

The SDK lives in the private repos `twyn-ios-sdk` and `twyn-sdk-dist`, so git must
be authenticated. GitHub does **not** accept passwords for git; use one of:

- **PAT (HTTPS)** — create a token with read access, then:
  ```bash
  git config --global url."https://<USER>:<TOKEN>@github.com/".insteadOf "https://github.com/"
  ```
  (or let git store it once in the macOS keychain)
- **SSH** — add your SSH key to GitHub and map HTTPS → SSH:
  ```bash
  git config --global url."git@github.com:".insteadOf "https://github.com/"
  ```

You must also be **added to `twyn-internal`** by Twyn — otherwise GitHub hides the
repos and returns `Repository not found`.

## Troubleshooting

| Symptom | Fix |
|---|---|
| `fatal: could not read Username for 'https://github.com'` | git has no credentials — configure a PAT/SSH (above) |
| `remote: Invalid username or token` / `Authentication failed` | token wrong/expired or lacks access |
| `Repository not found` (404) | your GitHub account isn't a member of `twyn-internal` |
| `pod install` can't find the pod | access/credentials (above) |
| `transitive dependencies that include statically linked binaries` | use `use_frameworks! :linkage => :static` |
| `IPHONEOS_DEPLOYMENT_TARGET ... supported ... 15.0` | add the `post_install` forcing `15.6` |
| `Encoding::CompatibilityError` | `export LANG=en_US.UTF-8` before `pod install` |
| "Could not select an Xcode project" | run `pod install` inside your project folder |

## License

The **sample code** is released under the MIT License (see `LICENSE`). The SDK
binaries are proprietary and governed by a separate commercial agreement.
