import SwiftUI
import Vision
import VisionKit

struct OCRScannerView: View {
    @Environment(\.dismiss) var dismiss
    var onScanned: (String) -> Void 

    @State private var showingScanner = true 
    @State private var scannedText: String = ""

    var body: some View {
        EmptyView()
            .sheet(isPresented: $showingScanner) {
                DocumentScannerView(scannedText: $scannedText) {
                    if !scannedText.isEmpty {
                        onScanned(scannedText) 
                    }
                    dismiss() 
                }
            }
    }
}

struct DocumentScannerView: UIViewControllerRepresentable {
    @Binding var scannedText: String
    var onComplete: () -> Void 

    func makeUIViewController(context: Context) -> VNDocumentCameraViewController {
        let controller = VNDocumentCameraViewController()
        controller.delegate = context.coordinator
        return controller
    }

    func updateUIViewController(_ uiViewController: VNDocumentCameraViewController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, VNDocumentCameraViewControllerDelegate {
        var parent: DocumentScannerView
        private var textRecognitionRequest = VNRecognizeTextRequest()

        init(_ parent: DocumentScannerView) {
            self.parent = parent
            super.init()
            setupVisionRequest()
        }

        private func setupVisionRequest() {
            textRecognitionRequest = VNRecognizeTextRequest { [weak self] (request, error) in
                guard let self = self else { return }
                if let error = error {
                    print("Text recognition error: \(error.localizedDescription)")
                    self.parent.scannedText = "" 
                    DispatchQueue.main.async {
                        self.parent.onComplete()
                    }
                    return
                }
                guard let observations = request.results as? [VNRecognizedTextObservation], !observations.isEmpty else {
                    print("No text recognized.")
                    self.parent.scannedText = "" 
                    DispatchQueue.main.async {
                        self.parent.onComplete()
                    }
                    return
                }

                let recognizedStrings = observations.compactMap { observation in
                    observation.topCandidates(1).first?.string
                }
                
                DispatchQueue.main.async {
                    self.parent.scannedText = recognizedStrings.joined(separator: "\n")
                    self.parent.onComplete()
                }
            }
            textRecognitionRequest.recognitionLevel = .accurate 
            textRecognitionRequest.usesLanguageCorrection = true
        }

        func documentCameraViewController(_ controller: VNDocumentCameraViewController, didFinishWith scan: VNDocumentCameraScan) {
            let imageRequestHandler = VNImageRequestHandler(cgImage: scan.imageOfPage(at: 0).cgImage!, options: [:])
            DispatchQueue.global(qos: .userInitiated).async {
                do {
                    try imageRequestHandler.perform([self.textRecognitionRequest])
                } catch {
                    print("Failed to perform text recognition: \(error.localizedDescription)")
                    DispatchQueue.main.async {
                        self.parent.scannedText = ""
                        self.parent.onComplete()
                    }
                }
            }
        }

        func documentCameraViewControllerDidCancel(_ controller: VNDocumentCameraViewController) {
            print("Document scanning cancelled.")
            parent.scannedText = ""
            parent.onComplete() 
        }

        func documentCameraViewController(_ controller: VNDocumentCameraViewController, didFailWithError error: Error) {
            print("Document scanning failed with error: \(error.localizedDescription)")
            parent.scannedText = ""
            parent.onComplete() 
        }
    }
}

struct OCRScannerView_Previews: PreviewProvider {
    static var previews: some View {
        OCRScannerView(onScanned: { text in
            print("Scanned text in preview: \(text)")
        })
    }
}
