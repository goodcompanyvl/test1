import SwiftUI
import WebKit

struct URLInputView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var urlString = ""
    @State private var isConverting = false
    @State private var showResult = false
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var convertedData: Data?
    @State private var convertedFilename = ""
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                Spacer()
                
                ZStack {
                    Circle()
                        .fill(Color(hex: "4A9EF7").opacity(0.1))
                        .frame(width: 120, height: 120)
                    
                    Circle()
                        .fill(Color(hex: "4A9EF7").opacity(0.15))
                        .frame(width: 90, height: 90)
                    
                    Image(systemName: "globe")
                        .font(.system(size: 40))
                        .foregroundStyle(Color(hex: "4A9EF7"))
                }
                
                VStack(spacing: 8) {
                    Text("Website to PDF")
                        .font(.title2.weight(.bold))
                    
                    Text("Convert any webpage to PDF locally")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("Website URL")
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(.secondary)
                    
                    HStack(spacing: 12) {
                        Image(systemName: "link")
                            .foregroundStyle(.secondary)
                        
                        TextField("example.com", text: $urlString)
                            .textFieldStyle(.plain)
                            .keyboardType(.URL)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()
                    }
                    .padding()
                    .background(Color.gray.opacity(0.1), in: RoundedRectangle(cornerRadius: 12))
                }
                .padding(.horizontal, 20)
                
                Spacer()
                
                Button {
                    convertURL()
                } label: {
                    HStack(spacing: 10) {
                        if isConverting {
                            ProgressView()
                                .tint(.white)
                        } else {
                            Image(systemName: "doc.fill")
                        }
                        Text(isConverting ? "Converting..." : "Convert to PDF")
                    }
                    .font(.headline)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(
                        urlString.isEmpty ? Color.gray : Color(hex: "4A9EF7"),
                        in: RoundedRectangle(cornerRadius: 14)
                    )
                }
                .disabled(urlString.isEmpty || isConverting)
                .padding(.horizontal, 20)
                .padding(.bottom, 20)
            }
            .navigationTitle("URL to PDF")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
            .fullScreenCover(isPresented: $showResult) {
                if let data = convertedData {
                    ConversionResultView(
                        data: data,
                        filename: convertedFilename,
                        format: "pdf"
                    )
                }
            }
            .onChange(of: showResult) { newValue in
                if !newValue && convertedData != nil {
                    dismiss()
                }
            }
            .alert("Error", isPresented: $showError) {
                Button("OK") {}
            } message: {
                Text(errorMessage)
            }
        }
    }
    
    private func convertURL() {
        var url = urlString.trimmingCharacters(in: .whitespacesAndNewlines)
        
        if !url.hasPrefix("http://") && !url.hasPrefix("https://") {
            url = "https://" + url
        }
        
        guard let webURL = URL(string: url) else {
            errorMessage = "Invalid URL"
            showError = true
            return
        }
        
        isConverting = true
        
        Task {
            do {
                let pdfData = try await WebPDFGenerator.shared.generatePDF(from: webURL)
                
                let domain = webURL.host ?? "website"
                let filename = "\(domain)_\(Int(Date().timeIntervalSince1970)).pdf"
                let fileURL = try await HistoryManager.shared.saveDocument(data: pdfData, filename: filename)
                
                let historyItem = HistoryItem(
                    fileName: filename,
                    originalFormat: "url",
                    resultFormat: "pdf",
                    direction: .urlToPDF,
                    source: .url,
                    fileURL: fileURL
                )
                HistoryManager.shared.addItem(historyItem)
                
                convertedData = pdfData
                convertedFilename = filename
                isConverting = false
                showResult = true
                
            } catch {
                isConverting = false
                errorMessage = error.localizedDescription
                showError = true
            }
        }
    }
}

@MainActor
final class WebPDFGenerator: NSObject {
    static let shared = WebPDFGenerator()
    
    private var webView: WKWebView?
    private var continuation: CheckedContinuation<Data, Error>?
    
    func generatePDF(from url: URL) async throws -> Data {
        return try await withCheckedThrowingContinuation { continuation in
            self.continuation = continuation
            
            let config = WKWebViewConfiguration()
            let webView = WKWebView(frame: CGRect(x: 0, y: 0, width: 595, height: 842), configuration: config)
            webView.navigationDelegate = self
            self.webView = webView
            
            let request = URLRequest(url: url, timeoutInterval: 30)
            webView.load(request)
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 60) { [weak self] in
                if self?.continuation != nil {
                    self?.continuation?.resume(throwing: PDFGeneratorError.timeout)
                    self?.continuation = nil
                    self?.webView = nil
                }
            }
        }
    }
    
    private func createPDF() {
        guard let webView = webView else {
            continuation?.resume(throwing: PDFGeneratorError.webViewNotFound)
            continuation = nil
            return
        }
        
        webView.createPDF { [weak self] result in
            switch result {
            case .success(let data):
                self?.continuation?.resume(returning: data)
            case .failure(let error):
                self?.continuation?.resume(throwing: error)
            }
            self?.continuation = nil
            self?.webView = nil
        }
    }
}

extension WebPDFGenerator: WKNavigationDelegate {
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) { [weak self] in
            self?.createPDF()
        }
    }
    
    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        continuation?.resume(throwing: error)
        continuation = nil
        self.webView = nil
    }
    
    func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
        continuation?.resume(throwing: error)
        continuation = nil
        self.webView = nil
    }
}

enum PDFGeneratorError: LocalizedError {
    case timeout
    case webViewNotFound
    
    var errorDescription: String? {
        switch self {
        case .timeout:
            return "Page loading timed out"
        case .webViewNotFound:
            return "Failed to create PDF"
        }
    }
}

#Preview {
    URLInputView()
}
