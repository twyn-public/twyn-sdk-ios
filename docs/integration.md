# iOS integration guide — Twyn SDK

> Goal: get the SDK running in **your** app in ~10 minutes.
> Copy the snippets, replace the placeholders, done.

---

## 1. Get access to the SDK

The binaries are **private**. Ask Twyn to add your GitHub account to
`twyn-internal/twyn-sdk-dist`. CocoaPods then pulls the binaries with **your git
credentials** — no tokens go in the `Podfile`.

## 2. Add the binaries (CocoaPods — recommended)

**`Podfile`**
```ruby
platform :ios, '15.6'

target 'YourApp' do
  use_frameworks!

  # Twyn binaries (private repo, git credentials).
  pod 'TwynTrustCore', :git => 'https://github.com/twyn-internal/twyn-sdk-dist.git', :tag => 'ios-0.1.1'
  pod 'TwynDeviceCore', :git => 'https://github.com/twyn-internal/twyn-sdk-dist.git', :tag => 'ios-0.1.1'

  # Vendor liveness SDK (provided by Twyn).
  pod 'T4Touchless'
end
```

```bash
export LANG=en_US.UTF-8   # avoids a CocoaPods/Ruby encoding error
pod install
```

> Run `pod install` inside your project folder (CocoaPods needs an `.xcodeproj`).

### Option B — Swift Package Manager

SwiftPM `binaryTarget` downloads **without** credentials, so a **private** GitHub
release returns `404`. If you need SwiftPM, host the `.xcframework.zip` on a server
reachable with `.netrc` and point the `binaryTarget` there (see `Package.swift`).

## 3. Device identity / continuity

```swift
import TwynDeviceCore

let ev = try await TwynDevice.shared.evaluate(personId: personId)
// ev.logicalDeviceId, ev.installationId, ev.continuityStatus,
// ev.deviceTrustScore, ev.riskLevel, ev.appAttestRecorded, ev.deviceCheckRecorded
```

Attach the `logical_device_id` to the transaction so the backend can apply
device-graph risk.

## 4. Liveness (vendor SDK)

The face capture UI is provided by `T4Touchless` (`T4FastIDSDK`). Register the
delegate and present it:

```swift
import T4Touchless

let sdk = T4FastIDSDK()
sdk.delegate = self
sdk.personId = personId
sdk.canal = "TWYN"
sdk.env = "dev"                 // "dev" or "prod"
sdk.requestSteps = ["T4_FACE"]
present(sdk, animated: true)
```

Delegate callbacks:

```swift
func onEnrollFaceCompleted(isAlive: Bool, imageDataString: String, tcn: String) { }
func onEnrollFaceError(code: Int, message: String) { }
```

## 5. Runtime integrity (TwynTrustCore)

`TwynTrustCore` runs structural anti-instrumentation probes (anonymous executable
regions, thread names, function-prologue integrity, exception ports) and produces
**evidence**. It does not make the trust decision — that is server-side.

```swift
import TwynTrustCore
// The core is invoked by the RASP integration layer; see SampleApp.
```

## 6. Decision is server-side

The SDK produces capture + integrity **evidence**. The gateway returns the
authoritative decision (`APPROVED` / `CHALLENGE` / `REJECTED`) and the reason
codes (`SENTINEL_BLOCK`, `KEYATTEST_FAIL`, `ENGINE_FAKE`, …). Always read the
verdict from your backend, not from the local callback alone.

## 7. App Attest / DeviceCheck

The device-identity flow uses Apple **App Attest** (Secure Enclave) and
**DeviceCheck**. Enable the capability for your App ID; on jailbroken devices the
flow is refused in enforce mode.

## Options reference

| Field | Values | Meaning |
|---|---|---|
| `personId` | string | the identity being enrolled |
| `canal` | string | channel (default `TWYN`) |
| `env` | `dev` / `prod` | environment |
| `requestSteps` | `T4_FACE`, `T4_FINGER`, `T4_DOCUMENT` | which captures to run |

## Troubleshooting

| Symptom | Fix |
|---|---|
| `pod install` can't find the pod | your GitHub account isn't added to `twyn-internal/twyn-sdk-dist` |
| `Encoding::CompatibilityError` | `export LANG=en_US.UTF-8` before `pod install` |
| "Could not select an Xcode project" | run `pod install` inside your project folder |
| SwiftPM `badResponseStatusCode(404)` | private release — use CocoaPods (or a `.netrc` host) |
