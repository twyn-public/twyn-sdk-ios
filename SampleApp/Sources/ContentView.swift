import SwiftUI
import TwynIOSSDK

struct ContentView: View {
    @StateObject private var coordinator = EnrollmentCoordinator()
    @State private var personId = "88888888888"

    var body: some View {
        ZStack {
            Color(.systemGroupedBackground).ignoresSafeArea()
            ScrollView {
                VStack(spacing: 18) {
                    header
                    inputCard
                    startButton
                    if let r = coordinator.result { resultCard(r) }
                    logCard
                }
                .padding(20)
            }
        }
    }

    // MARK: - Sections

    private var header: some View {
        VStack(spacing: 8) {
            Image(systemName: "faceid")
                .font(.system(size: 46))
                .foregroundStyle(.tint)
            Text("Twyn SDK")
                .font(.largeTitle.bold())
            Text("Face liveness + device integrity")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 8)
    }

    private var inputCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Person ID")
                .font(.caption).bold()
                .foregroundStyle(.secondary)
            TextField("personId", text: $personId)
                .font(.body.monospaced())
                .keyboardType(.numberPad)
                .autocorrectionDisabled()
                .padding(12)
                .background(Color(.secondarySystemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
        }
        .padding(16)
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private var startButton: some View {
        Button {
            coordinator.start(personId: personId)
        } label: {
            Label("Start enrollment", systemImage: "camera.fill")
                .font(.headline)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 6)
        }
        .buttonStyle(.borderedProminent)
        .controlSize(.large)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }

    private func resultCard(_ r: EnrollmentResult) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 12) {
                Image(systemName: r.symbol)
                    .font(.title)
                    .foregroundStyle(.white)
                VStack(alignment: .leading, spacing: 2) {
                    Text(r.title).font(.title3.bold()).foregroundStyle(.white)
                    Text(r.subtitle).font(.caption).foregroundStyle(.white.opacity(0.9))
                }
                Spacer()
            }
            VStack(spacing: 6) {
                ForEach(r.rows, id: \.0) { row in
                    HStack {
                        Text(row.0).font(.caption).foregroundStyle(.white.opacity(0.85))
                        Spacer()
                        Text(row.1).font(.caption.bold()).foregroundStyle(.white)
                    }
                }
            }
        }
        .padding(16)
        .background(r.color)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .shadow(color: r.color.opacity(0.35), radius: 10, y: 4)
    }

    private var logCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("Callbacks").font(.headline)
                Spacer()
                Button("Clear") { coordinator.log = "Ready." }
                    .font(.caption)
            }
            ScrollView {
                Text(coordinator.log)
                    .font(.system(.caption, design: .monospaced))
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .textSelection(.enabled)
            }
            .frame(maxHeight: 220)
        }
        .padding(16)
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
}
