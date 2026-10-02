import UIKit
import Combine
import TwynIOSSDK

/// Thin host-side glue: creates the SDK view controller, presents it, and logs
/// the delegate callbacks. No capture logic here — that is all inside TwynIOSSDK.
final class EnrollmentCoordinator: NSObject, ObservableObject, T4FastIDDelegate {

    @Published var log = "Ready."

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

    // MARK: - T4FastIDDelegate

    func onEnrollFaceCompleted(isAlive: Bool, imageDataString: String, tcn: String) {
        append("face completed: alive=\(isAlive) tcn=\(tcn)")
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
