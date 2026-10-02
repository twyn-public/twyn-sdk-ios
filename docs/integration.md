# iOS integration guide

## 1. Requirements

- iOS **15.6+**
- Xcode 15+
- The vendor liveness SDK (`T4Touchless`) + the Twyn binaries (`TwynTrustCore`,
  `TwynDeviceCore`)

## 2. Add the binaries

### Option A â€” CocoaPods (recommended, private)

```ruby
# Podfile
platform :ios, '15.6'

source 'https://cdn.cocoapods.org'
source 'https://github.com/twyn-internal/twyn-sdk-dist.git'   # private spec repo

target 'YourApp' do
  use_frameworks!

  pod 'T4Touchless'
  pod 'TwynTrustCore', '~> 0.1'
  pod 'TwynDeviceCore', '~> 0.1'
end
```

```bash
pod install
```

The private spec repo needs read access â€” configure git credentials (SSH key or a
token in the keychain). Do **not** put tokens in the `Podfile`.

### Option B â€” Swift Package Manager

Add `github.com/twyn-public/twyn-sdk-ios` as a package dependency. The manifest declares
`binaryTarget`s; see `Package.swift`. Private hosting requires `.netrc` credentials
or a publicly reachable mirror.

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
sdk.canal = "SICTM"
sdk.env = "dev"
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
**evidence**. It does not make the trust decision â€” that is server-side.

```swift
import TwynTrustCore
// The core is invoked by the RASP integration layer; see SampleApp.
```

## 6. Decision is server-side

The SDK produces capture + integrity **evidence**. The gateway returns the
authoritative decision (`APPROVED` / `CHALLENGE` / `REJECTED`) and the reason
codes (`SENTINEL_BLOCK`, `KEYATTEST_FAIL`, `ENGINE_FAKE`, â€¦). Always read the
verdict from your backend, not from the local callback alone.

## 7. App Attest / DeviceCheck

The device-identity flow uses Apple **App Attest** (Secure Enclave) and
**DeviceCheck**. Ensure the capability is enabled for your App ID and that the
device is not jailbroken (the SDK will refuse on compromised devices in enforce
mode).
