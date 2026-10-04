# iOS integration guide — Twyn SDK

> Goal: get the SDK running in **your** app in ~10 minutes.
> Copy the snippets, replace the placeholders, done.

---

## 1. Get access + credentials

The SDK is **private** (`twyn-internal/twyn-ios-sdk` + `twyn-internal/twyn-sdk-dist`).
Ask Twyn to add your GitHub account to `twyn-internal`. CocoaPods then pulls the
pods with **your git credentials** — no tokens go in the `Podfile`.

GitHub no longer accepts passwords for git, so authenticate with a **PAT** or **SSH**:

```bash
# PAT (HTTPS)
git config --global url."https://<USER>:<TOKEN>@github.com/".insteadOf "https://github.com/"
# or SSH
git config --global url."git@github.com:".insteadOf "https://github.com/"
```

Verify in one shot (prints an actionable message if it fails):

```bash
bash scripts/check-access.sh
```

## 2. Add the SDK (CocoaPods)

**`Podfile`**
```ruby
platform :ios, '15.6'

target 'YourApp' do
  use_frameworks! :linkage => :static

  pod 'TwynIOSSDK',    :git => 'https://github.com/twyn-internal/twyn-ios-sdk.git',  :tag => 'ios-0.3.3'
  pod 'TwynTrustCore', :git => 'https://github.com/twyn-internal/twyn-sdk-dist.git', :tag => 'ios-0.2.0'
  pod 'TwynDeviceCore',:git => 'https://github.com/twyn-internal/twyn-sdk-dist.git', :tag => 'ios-0.2.0'
end

post_install do |installer|
  installer.pods_project.targets.each do |t|
    t.build_configurations.each do |c|
      c.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = '15.6'
      c.build_settings['BUILD_LIBRARY_FOR_DISTRIBUTION'] = 'YES'
    end
  end
end
```

```bash
export LANG=en_US.UTF-8   # avoids a CocoaPods/Ruby encoding error
pod install
```

> Run `pod install` inside your project folder (CocoaPods needs an `.xcodeproj`).
> Then open the **`.xcworkspace`** (not the `.xcodeproj`) — that is what links the pods.

## 3. Present the SDK

The face capture is driven entirely by the SDK. Your app only creates it, sets the
params, presents it and receives the callbacks.

```swift
import TwynIOSSDK

final class Host: NSObject, T4FastIDDelegate {
    func start(personId: String, from vc: UIViewController) {
        let sdk = T4FastIDSDK()
        sdk.delegate = self
        sdk.sdkKey = "<your-sdk-key>"
        sdk.personId = personId
        sdk.canal = "TWYN"
        sdk.env = "dev"                 // "dev" or "prod"
        sdk.requestSteps = ["T4_FACE"]
        sdk.tot = ""
        sdk.actionTimeOut = 20000
        sdk.showSuccessDialog = false
        sdk.openT4Fingers = false
        sdk.language = "en"
        sdk.iBeta = true
        sdk.modalPresentationStyle = .fullScreen
        vc.present(sdk, animated: true)
    }

    // T4FastIDDelegate
    func onEnrollFaceCompleted(isAlive: Bool, imageDataString: String, tcn: String) { }
    func onEnrollFaceError(code: Int, message: String) { }
    func onEnrollDocumentCompleted(isValid: Bool, frontDataString: String?, backDataString: String?, tcn: String) { }
    func onEnrollDocumentError(code: Int, message: String) { }
    func onTransactionCompleted(workflowInstanceId: String, tot: String) { }
    func onTransactionFailed(code: Int, message: String) { }
    func onSDKStatusChanged(code: Int, message: String) { }
}
```

> The app bundle id must be **allowed on the gateway**. Ask Twyn to register it.

## 4. Result / decision (server-side)

On `onEnrollFaceCompleted` read the authoritative decision from the gateway audit
API and show it to the user (the sample does this — `APROVADO / REPROVADO / EM ANÁLISE`):

```swift
let url = URL(string: "https://<your-gateway>/api/audit/decisions?limit=1")!
let obj = try JSONSerialization.jsonObject(with: Data(contentsOf: url)) as? [String: Any]
let dec = (obj?["items"] as? [[String: Any]])?.first
// dec["decision"] -> APPROVED / CHALLENGE / REJECTED
// dec["riskScore"], dec["reasonCodes"], dec["signals"]["sentinel"]["decision"]
```

## 5. What the SDK does under the hood

- Face capture / liveness (`T4FastIDSDK`) + enrollment UI.
- **Twyn camera integrity** — instruments the capture session (exposure challenge,
  ownership, provenance) and submits the evidence bound to the transaction.
- **Sentinel** — runs the Rust device-integrity scan and submits it to the Sentinel
  dash (with App Attest), then links the report to the transaction.
- **App Attest / DeviceCheck** — device identity / continuity (`TwynDevice`).
- The Rust cores (`TwynTrustCore`, `TwynDeviceCore`) produce **evidence** only; the
  decision is made by the gateway.

## Options reference

| Field | Values | Meaning |
|---|---|---|
| `sdkKey` | string | SDK key issued by Twyn |
| `personId` | string | the identity being enrolled |
| `canal` | string | channel (default `TWYN`) |
| `env` | `dev` / `prod` | environment |
| `requestSteps` | `T4_FACE`, `T4_DOCUMENT`, … | which captures to run |
| `language` | `en` / `pt` | UI language |

## Troubleshooting

| Symptom | Fix |
|---|---|
| `fatal: could not read Username for 'https://github.com'` | git has no credentials — configure a PAT/SSH (§1) |
| `remote: Invalid username or token` / `Authentication failed` | token wrong/expired or lacks access |
| `Repository not found` (404) | your GitHub account isn't a member of `twyn-internal` |
| `transitive dependencies that include statically linked binaries` | use `use_frameworks! :linkage => :static` |
| `IPHONEOS_DEPLOYMENT_TARGET ... supported ... 15.0` | add the `post_install` forcing `15.6` |
| `Encoding::CompatibilityError` | `export LANG=en_US.UTF-8` before `pod install` |
| "Could not select an Xcode project" | run `pod install` inside your project folder |
| "no such module 'TwynIOSSDK'" | open the `.xcworkspace` (not the `.xcodeproj`) |
