# iOS integration guide — Twyn SDK

> Goal: get the SDK running in **your** app in ~10 minutes.
> Copy the snippets, replace the placeholders, done.

---

## 1. Get access to the SDK

The binaries are **private**. Ask Twyn to add your GitHub account to
`twyn-internal/twyn-sdk-dist`. CocoaPods then pulls the binaries with **your git
credentials** — no tokens go in the `Podfile`.

Because GitHub no longer accepts passwords for git, authenticate with a **PAT** or
**SSH**:

```bash
# PAT (HTTPS)
git config --global url."https://<USER>:<TOKEN>@github.com/".insteadOf "https://github.com/"
# or SSH
git config --global url."git@github.com:".insteadOf "https://github.com/"
```

You must be **added to `twyn-internal`**; otherwise GitHub returns
`Repository not found` (it hides private repos you can't see).

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
> The cores expose a **C ABI** (no Swift modulemap): add a bridging header that
> imports `twyn_device_core.h`, `sentinel_ios.h` and `twyn_runtime.h`.

### Option B — Swift Package Manager

SwiftPM `binaryTarget` downloads **without** credentials, so a **private** GitHub
release returns `404`. If you need SwiftPM, host the `.xcframework.zip` on a server
reachable with `.netrc` and point the `binaryTarget` there (see `Package.swift`).

## 3. Device identity / continuity

```swift
// TwynDeviceCore — installation id (persist it in the Keychain)
if let c = twyn_dc_install_id() {
    let installationId = String(cString: c)
    twyn_dc_free(c)
}

// device_id / profile_hash from the device components (JSON)
if let c = twyn_dc_fingerprint(componentsJSON) {
    let deviceId = String(cString: c)
    twyn_dc_free(c)
}
```

Attach the device id to the transaction so the backend can apply device-graph risk.
Higher-level wrappers (`TwynDevice`, App Attest orchestration) live in the private
`TwynIOSSDK` layer.

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
// Full scan -> ThreatReport JSON. Collect the device's URL schemes first
// (LaunchServices) and pass them as a JSON array; NULL / "[]" is allowed.
if let c = sentinel_ios_analyze_with_schemes(nil, nil, 0, schemesJSON) {
    let report = String(cString: c)
    sentinel_ios_free(c)
}

// crate version (do not free)
if let v = twyn_runtime_version() { print(String(cString: v)) }
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
| `fatal: could not read Username for 'https://github.com'` | git has no credentials — configure a PAT/SSH (§1) |
| `remote: Invalid username or token` / `Authentication failed` | token wrong/expired or lacks access |
| `Repository not found` (404) | your GitHub account isn't a member of `twyn-internal` |
| `pod install` can't find the pod | access/credentials (§1) |
| `Encoding::CompatibilityError` | `export LANG=en_US.UTF-8` before `pod install` |
| "Could not select an Xcode project" | run `pod install` inside your project folder |
| SwiftPM `badResponseStatusCode(404)` | private release — use CocoaPods (or a `.netrc` host) |
