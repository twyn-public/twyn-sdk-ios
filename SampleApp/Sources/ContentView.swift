import SwiftUI
import TwynIOSSDK

struct ContentView: View {
    @StateObject private var coordinator = EnrollmentCoordinator()
    @State private var personId = "88888888888"

    var body: some View {
        ZStack {
            TwynBrand.paper.ignoresSafeArea()
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
            ZStack {
                Circle().fill(TwynBrand.signal).frame(width: 64, height: 64)
                Image(systemName: "faceid").font(.system(size: 30)).foregroundStyle(TwynBrand.ink)
            }
            Text("Twyn").font(.system(size: 34, weight: .bold)).foregroundStyle(TwynBrand.ink)
            Text("Face liveness + device integrity")
                .font(.subheadline).foregroundStyle(TwynBrand.inkSoft)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 8)
    }

    private var inputCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("PERSON ID")
                .font(.caption2.bold()).tracking(1.2)
                .foregroundStyle(TwynBrand.inkSoft)
            TextField("personId", text: $personId)
                .font(.body.monospaced())
                .foregroundStyle(TwynBrand.ink)
                .keyboardType(.numberPad)
                .autocorrectionDisabled()
                .padding(12)
                .background(TwynBrand.paper.opacity(0.6))
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
        }
        .padding(16)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous).stroke(TwynBrand.border, lineWidth: 1))
    }

    private var startButton: some View {
        Button {
            coordinator.start(personId: personId)
        } label: {
            Label("Start enrollment", systemImage: "camera.fill")
        }
        .buttonStyle(BrandButtonStyle())
    }

    private func resultCard(_ r: EnrollmentResult) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 12) {
                Image(systemName: r.symbol).font(.title).foregroundStyle(.white)
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
                Text("Callbacks").font(.headline).foregroundStyle(TwynBrand.ink)
                Spacer()
                Button("Clear") { coordinator.log = "Ready." }
                    .font(.caption).tint(TwynBrand.signal)
            }
            ScrollView {
                Text(coordinator.log)
                    .font(.system(.caption, design: .monospaced))
                    .foregroundStyle(TwynBrand.ink)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .textSelection(.enabled)
            }
            .frame(maxHeight: 220)
        }
        .padding(16)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous).stroke(TwynBrand.border, lineWidth: 1))
    }
}
