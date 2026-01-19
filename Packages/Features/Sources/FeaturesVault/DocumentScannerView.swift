import SwiftUI
import UIKit
import Vision
import VisionKit

struct DocumentScannerView: UIViewControllerRepresentable {
    let onComplete: (String) -> Void

    func makeUIViewController(context: Context) -> VNDocumentCameraViewController {
        let controller = VNDocumentCameraViewController()
        controller.delegate = context.coordinator
        return controller
    }

    func updateUIViewController(_ uiViewController: VNDocumentCameraViewController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(onComplete: onComplete)
    }

    final class Coordinator: NSObject, VNDocumentCameraViewControllerDelegate {
        private let onComplete: (String) -> Void

        init(onComplete: @escaping (String) -> Void) {
            self.onComplete = onComplete
        }

        func documentCameraViewController(_ controller: VNDocumentCameraViewController, didFinishWith scan: VNDocumentCameraScan) {
            var text = ""
            for pageIndex in 0..<scan.pageCount {
                let image = scan.imageOfPage(at: pageIndex)
                text += recognizeText(from: image)
            }
            controller.dismiss(animated: true) {
                self.onComplete(text.trimmingCharacters(in: .whitespacesAndNewlines))
            }
        }

        func documentCameraViewControllerDidCancel(_ controller: VNDocumentCameraViewController) {
            controller.dismiss(animated: true)
        }

        func documentCameraViewController(_ controller: VNDocumentCameraViewController, didFailWithError error: Error) {
            controller.dismiss(animated: true)
        }

        private func recognizeText(from image: UIImage) -> String {
            guard let cgImage = image.cgImage else { return "" }
            let request = VNRecognizeTextRequest()
            request.recognitionLevel = .accurate
            request.usesLanguageCorrection = true
            let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
            do {
                try handler.perform([request])
                let results = request.results ?? []
                return results.compactMap { $0.topCandidates(1).first?.string }.joined(separator: "\n") + "\n"
            } catch {
                return ""
            }
        }
    }
}
