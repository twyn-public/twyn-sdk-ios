import SwiftUI

// Minimal integration sample for the distributed Twyn cores.
//
// Both cores are static C libraries shipped as .xcframework; the C ABI is reached
// through Twyn-Bridging-Header.h. The higher-level Swift wrappers (TwynDevice,
// TwynCameraIntegrity, …) live in the private TwynIOSSDK layer and are layered on
// top of these same calls.
//
//   TwynTrustCore.sentinel_ios_analyze_with_schemes(...)  -> ThreatReport JSON (evidence)
//   TwynTrustCore.twyn_runtime_version()                  -> crate version
//   TwynDeviceCore.twyn_dc_install_id()                   -> installation id

struct ContentView: View {
    @State private var status = "Tap to run the Twyn checks"
    @State private var busy = false

    var body: some View {
        VStack(spacing: 20) {
            Text("Twyn iOS SDK — sample")
                .font(.headline)

            ScrollView {
                Text(status)
                    .font(.system(.footnote, design: .monospaced))
                    .textSelection(.enabled)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .frame(maxHeight: 320)
            .padding(10)
            .background(Color.secondary.opacity(0.12))
            .cornerRadius(8)

            Button {
                run()
            } label: {
                Text(busy ? "Running…" : "Run checks")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .disabled(busy)
        }
        .padding()
    }

    private func run() {
        busy = true
        defer { busy = false }

        var lines: [String] = []

        // TwynTrustCore — crate version.
        if let v = twyn_runtime_version() {
            lines.append("trust-core: \(String(cString: v))")
        }

        // TwynDeviceCore — installation id (persist this in the Keychain).
        if let c = twyn_dc_install_id() {
            lines.append("installation: \(String(cString: c))")
            twyn_dc_free(c)
        }

        // TwynTrustCore — full integrity scan, returns ThreatReport JSON.
        // (packages/config = NULL, shallow scan, empty URL-scheme list.)
        if let c = sentinel_ios_analyze_with_schemes(nil, nil, 0, "[]") {
            let json = String(cString: c)
            sentinel_ios_free(c)
            lines.append("report: \(json.prefix(400))…")
        }

        status = lines.joined(separator: "\n\n")
    }
}
