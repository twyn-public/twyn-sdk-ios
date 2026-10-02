import SwiftUI
import TwynIOSSDK

// Thin host app: it only presents the Twyn SDK and shows the callbacks.
// All capture / liveness / integrity logic lives inside TwynIOSSDK.

struct ContentView: View {
    @StateObject private var coordinator = EnrollmentCoordinator()
    @State private var personId = "88888888888"

    var body: some View {
        VStack(spacing: 16) {
            Text("Twyn iOS SDK — sample")
                .font(.headline)

            TextField("personId", text: $personId)
                .textFieldStyle(.roundedBorder)
                .autocorrectionDisabled()
                .keyboardType(.numberPad)

            Button {
                coordinator.start(personId: personId)
            } label: {
                Text("Start enrollment").frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)

            ScrollView {
                Text(coordinator.log)
                    .font(.system(.footnote, design: .monospaced))
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .textSelection(.enabled)
            }
            .frame(maxHeight: 340)
            .padding(10)
            .background(Color.secondary.opacity(0.12))
            .cornerRadius(8)
        }
        .padding()
    }
}
