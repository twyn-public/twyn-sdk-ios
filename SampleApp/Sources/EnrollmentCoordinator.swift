import UIKit
import Combine
import TwynIOSSDK

/// Thin host-side glue: creates the SDK view controller, presents it, and logs
/// the delegate callbacks. No capture logic here — that is all inside TwynIOSSDK.
///
/// When the face step completes it reads the authoritative decision from the
/// gateway audit API and shows an APPROVED / REJECTED / REVIEW dialog, like the
/// Android sample.
final class EnrollmentCoordinator: NSObject, ObservableObject, T4FastIDDelegate {

    @Published var log = "Ready."

    // Set to your deployment. Used only for the audit read (the SDK's own
    // liveness transport is baked into the SDK binary).
    private let gatewayBase = "https://ibeta-dev-bixelab.twyn.me"

    // Watermark of the last decision BEFORE the liveness, so we wait for the NEW one.
    private var baselineDecisionId: String?
    private var baselineCaptured = false
    private let io = DispatchQueue(label: "twyn.sample.io")

    func start(personId: String) {
        let sdk = T4FastIDSDK()
        sdk.delegate = self
        sdk.sdkKey = "af9e4536-4b01-44bc-8063-1b3638dbcc61"
        sdk.personId = personId
        sdk.canal = "TWYN"
        sdk.env = "dev"
        sdk.requestSteps = ["T4_FACE"]
        sdk.tot = ""
        sdk.actionTimeOut = 20000
        sdk.showSuccessDialog = false
        sdk.openT4Fingers = false
        sdk.language = "en"
        sdk.iBeta = true

        // Twyn device identity / continuity (App Attest + DeviceCheck).
        Task {
            do {
                let ev = try await TwynDevice.shared.evaluate(personId: personId)
                sdk.logicalDeviceId = ev.logicalDeviceId
                append("device: logical=\(ev.logicalDeviceId ?? "-") trust=\(ev.deviceTrustScore) risk=\(ev.riskLevel) attest=\(ev.appAttestRecorded)")
            } catch {
                append("device error: \(error.localizedDescription)")
            }
        }

        captureBaselineDecision()
        present(sdk)
    }

    private func present(_ vc: UIViewController) {
        guard let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let root = scene.windows.first(where: { $0.isKeyWindow })?.rootViewController else {
            append("no root view controller")
            return
        }
        vc.modalPresentationStyle = .fullScreen
        root.present(vc, animated: true)
    }

    private func append(_ line: String) {
        DispatchQueue.main.async { self.log = line + "\n" + self.log }
    }

    // MARK: - Gateway decision (audit API) + result dialog

    private func captureBaselineDecision() {
        baselineCaptured = false
        baselineDecisionId = nil
        io.async {
            self.baselineDecisionId = self.fetchLatestDecision()?["_id"] as? String
            self.baselineCaptured = true
        }
    }

    private func fetchDecisionAndShow(tcn: String?, alive: Bool) {
        io.async {
            var dec: [String: Any]?
            let deadline = Date().addingTimeInterval(12)
            while Date() < deadline {
                if let latest = self.fetchLatestDecision() {
                    let id = latest["_id"] as? String
                    let isNew = !self.baselineCaptured || self.baselineDecisionId == nil || id != self.baselineDecisionId
                    if isNew { dec = latest; break }
                }
                Thread.sleep(forTimeInterval: 1)
            }
            let final = dec
            DispatchQueue.main.async { self.showResult(tcn: tcn, alive: alive, dec: final) }
        }
    }

    private func fetchLatestDecision() -> [String: Any]? {
        guard let url = URL(string: "\(gatewayBase)/api/audit/decisions?limit=1") else { return nil }
        var req = URLRequest(url: url)
        req.timeoutInterval = 8
        req.setValue("application/json", forHTTPHeaderField: "Accept")
        guard let data = try? Data(contentsOf: url, options: []) else { return nil }
        _ = req
        guard let obj = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let items = obj["items"] as? [[String: Any]], let first = items.first else { return nil }
        return first
    }

    private func showResult(tcn: String?, alive: Bool, dec: [String: Any]?) {
        let decision = (dec?["decision"] as? String).flatMap { $0.isEmpty ? nil : $0 } ?? "INDEFINIDA"
        let risk = dec?["riskScore"] as? Double
        let sentinel = ((dec?["signals"] as? [String: Any])?["sentinel"] as? [String: Any])?["decision"] as? String
        let reasons = (dec?["reasonCodes"] as? [String]) ?? []

        var title = "INDEFINIDO"
        switch decision {
        case "APPROVED": title = "APROVADO"
        case "REJECTED": title = "REPROVADO"
        case "CHALLENGE": title = "EM ANÁLISE"
        default: title = "INDEFINIDO"
        }

        var msg = "Liveness (SDK): \(alive ? "Sim" : "Não")\n"
        msg += "Decisão: \(decision)\n"
        if let r = risk { msg += String(format: "Risco: %.3f\n", r) }
        if let s = sentinel, !s.isEmpty { msg += "Sentinel: \(s)\n" }
        msg += "Motivos: \(reasons.isEmpty ? "—" : reasons.joined(separator: ", "))\n"
        if let t = tcn, !t.isEmpty { msg += "TCN: \(t)" }

        append("decision: \(decision) risk=\(risk.map { String(format: "%.3f", $0) } ?? "-") sentinel=\(sentinel ?? "-")")

        let alert = UIAlertController(title: title, message: msg, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        guard let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let root = scene.windows.first(where: { $0.isKeyWindow })?.rootViewController else { return }
        var top = root
        while let presented = top.presentedViewController { top = presented }
        top.present(alert, animated: true)
    }

    // MARK: - T4FastIDDelegate

    func onEnrollFaceCompleted(isAlive: Bool, imageDataString: String, tcn: String) {
        append("face completed: alive=\(isAlive) tcn=\(tcn)")
        fetchDecisionAndShow(tcn: tcn, alive: isAlive)
    }

    func onEnrollFaceError(code: Int, message: String) {
        append("face error: code=\(code) msg=\(message)")
    }

    func onEnrollDocumentCompleted(isValid: Bool, frontDataString: String?, backDataString: String?, tcn: String) {
        append("document completed: valid=\(isValid) tcn=\(tcn)")
    }

    func onEnrollDocumentError(code: Int, message: String) {
        append("document error: code=\(code) msg=\(message)")
    }

    func onTransactionCompleted(workflowInstanceId: String, tot: String) {
        append("transaction completed: wkf=\(workflowInstanceId) tot=\(tot)")
    }

    func onTransactionFailed(code: Int, message: String) {
        append("transaction failed: code=\(code) msg=\(message)")
    }

    func onSDKStatusChanged(code: Int, message: String) {
        append("sdk status: code=\(code) msg=\(message)")
    }
}
