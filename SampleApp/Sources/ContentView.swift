import SwiftUI
import TwynDeviceCore
import TwynTrustCore

// Minimal integration sample.
//
// Shows how the app talks to the SDK's public surface:
//   - TwynDevice.evaluate(personId:)  -> device identity / continuity / App Attest
//   - TwynTrustCore                   -> runtime-integrity evidence (via the RASP layer)
//
// The liveness UI itself is driven by the vendor SDK (T4Touchless); see the app
// integration guide for the full flow.

@main
struct TwynSampleApp: App {
    var body: some Scene {
        WindowGroup { ContentView() }
    }
}

struct ContentView: View {
    @State private var status = "Tap to run device evaluation"
    @State private var busy = false

    var body: some View {
        VStack(spacing: 24) {
            Text("Twyn iOS SDK — sample")
                .font(.headline)
            Text(status)
                .font(.footnote)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            Button {
                Task { await evaluate() }
            } label: {
                Text(busy ? "Evaluating…" : "Evaluate device")
            }
            .disabled(busy)
        }
        .padding()
    }

    @MainActor
    private func evaluate() async {
        busy = true
        defer { busy = false }
        do {
            // Replace with the personId provided for your integration.
            let ev = try await TwynDevice.shared.evaluate(personId: "12345678900")
            status = """
            logical: \(ev.logicalDeviceId ?? "-")
            install: \(ev.installationId)
            continuity: \(ev.continuityStatus) / \(ev.continuityConfidence)
            trust: \(ev.deviceTrustScore)  risk: \(ev.riskLevel)
            attest: \(ev.appAttestRecorded)  deviceCheck: \(ev.deviceCheckRecorded)
            """
        } catch {
            status = "error: \(error.localizedDescription)"
        }
    }
}
