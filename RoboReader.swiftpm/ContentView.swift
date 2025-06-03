import SwiftUI

import VisionKit

import Vision

import WebKit


struct OCRSpeechApp: App {
    
    var body: some Scene {
        
        WindowGroup {
            
            ContentView()
            
        }
        
    }
    
}


struct ContentView: View {
    
    @State private var recognizedText = ""
    
    @State private var showImagePicker = false
    
    @State private var image: UIImage?
    
    
    
    var body: some View {
        
        VStack(spacing: 20) {
            
            Button("Take Book Photo") {
                
                showImagePicker = true
                
            }
            
            .font(.title2)
            
            
            
            if !recognizedText.isEmpty {
                
                ScrollView {
                    
                    Text(recognizedText)
                    
                        .padding()
                    
                }
                
                .frame(maxHeight: 300)
                
                
                
                Button("Read Text Aloud") {
                    
                    WebSpeechController.shared.speak(text: recognizedText)
                    
                }
                
                .font(.title2)
                
            }
            
        }
        
        .padding()
        
        .sheet(isPresented: $showImagePicker) {
            
            ImagePicker(image: $image, onComplete: processImage)
            
        }
        
        .background(WebSpeechView())
        
    }
    
    
    
    func processImage(_ image: UIImage?) {
        
        guard let image = image else { return }
        
        
        
        let requestHandler = VNImageRequestHandler(cgImage: image.cgImage!, options: [:])
        
        let request = VNRecognizeTextRequest { request, error in
            
            if let observations = request.results as? [VNRecognizedTextObservation] {
                
                recognizedText = observations.compactMap { $0.topCandidates(1).first?.string }.joined(separator: " ")
                
            }
            
        }
        
        request.recognitionLevel = .accurate
        
        
        
        DispatchQueue.global(qos: .userInitiated).async {
            
            do {
                
                try requestHandler.perform([request])
                
            } catch {
                
                print("OCR error: \(error)")
                
            }
            
        }
        
    }
    
}


struct ImagePicker: UIViewControllerRepresentable {
    
    @Environment(\.presentationMode) var presentationMode
    
    @Binding var image: UIImage?
    
    var onComplete: (UIImage?) -> Void
    
    
    
    func makeCoordinator() -> Coordinator {
        
        Coordinator(self)
        
    }
    
    
    
    class Coordinator: NSObject, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
        
        let parent: ImagePicker
        
        init(_ parent: ImagePicker) { self.parent = parent }
        
        
        
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            
            if let uiImage = info[.originalImage] as? UIImage {
                
                parent.image = uiImage
                
                parent.onComplete(uiImage)
                
            }
            
            parent.presentationMode.wrappedValue.dismiss()
            
        }
        
        
        
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            
            parent.presentationMode.wrappedValue.dismiss()
            
        }
        
    }
    
    
    
    func makeUIViewController(context: Context) -> UIImagePickerController {
        
        let picker = UIImagePickerController()
        
        picker.sourceType = .camera // ✅ Force camera only
        
        picker.delegate = context.coordinator
        
        return picker
        
    }
    
    
    
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
    
}


// MARK: - Web Speech Support


class WebSpeechController: NSObject {
    
    static let shared = WebSpeechController()
    
    private var webView: WKWebView?
    
    
    
    func setWebView(_ webView: WKWebView) {
        
        self.webView = webView
        
    }
    
    
    
    func speak(text: String) {
        
        let escaped = text.replacingOccurrences(of: "\"", with: "\\\"")
        
        let js = "speakText(\"\(escaped)\")"
        
        webView?.evaluateJavaScript(js, completionHandler: nil)
        
    }
    
}


struct WebSpeechView: UIViewRepresentable {
    
    func makeUIView(context: Context) -> WKWebView {
        
        let webView = WKWebView()
        
        webView.loadHTMLString(html, baseURL: nil)
        
        WebSpeechController.shared.setWebView(webView)
        
        return webView
        
    }
    
    
    
    func updateUIView(_ uiView: WKWebView, context: Context) {}
    
    
    
    private var html: String {
        
        """
        
        <!DOCTYPE html>
        
        <html>
        
        <body>
        
        <script>
        
        function speakText(text) {
        
            var msg = new SpeechSynthesisUtterance(text);
        
            msg.lang = 'en-US';
        
            speechSynthesis.speak(msg);
        
        }
        
        </script>
        
        </body>
        
        </html>
        
        """
        
    }
    
}


