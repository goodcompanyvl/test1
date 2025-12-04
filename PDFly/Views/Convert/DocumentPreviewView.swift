import SwiftUI
import PDFKit
import UniformTypeIdentifiers

struct DocumentPreviewView: View {
    @Environment(\.dismiss) private var dismiss
    @State var documents: [SelectedDocument]
    let source: DocumentSource
    @State private var isConverting = false
    @State private var showResult = false
    @State private var convertedPDFData: Data?
    @State private var convertedFilename = ""
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var draggedItem: SelectedDocument?
    @State private var selectedIndex = 0
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                if documents.count == 1, let doc = documents.first {
                    singleDocumentPreview(doc)
                } else {
                    multipleDocumentsPreview
                }
                
                bottomButtons
            }
            .background(Color(uiColor: .systemGroupedBackground))
            .navigationTitle("Preview")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title2)
                            .foregroundStyle(.gray.opacity(0.6))
                    }
                }
            }
            .overlay {
                if isConverting {
                    LoadingOverlay(message: "Converting to PDF...")
                }
            }
            .fullScreenCover(isPresented: $showResult) {
                if let data = convertedPDFData {
                    ConversionResultView(data: data, filename: convertedFilename, format: "pdf")
                }
            }
            .onChange(of: showResult) { newValue in
                if !newValue && convertedPDFData != nil {
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
    
    private func singleDocumentPreview(_ doc: SelectedDocument) -> some View {
        VStack(spacing: 20) {
            Spacer()
            
            if let image = UIImage(data: doc.data) {
                ZStack {
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color.white)
                        .shadow(color: .black.opacity(0.15), radius: 20, y: 10)
                    
                    Image(uiImage: image)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .padding(8)
                }
                .frame(maxWidth: .infinity)
                .frame(maxHeight: 400)
                .padding(.horizontal, 30)
            } else {
                documentPlaceholder(doc)
            }
            
            VStack(spacing: 6) {
                Text(doc.name)
                    .font(.headline)
                
                Text(doc.fileExtension.uppercased())
                    .font(.caption)
                    .foregroundStyle(.white)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(Color(hex: "E53935"), in: Capsule())
            }
            
            Spacer()
        }
    }
    
    private var multipleDocumentsPreview: some View {
        VStack(spacing: 16) {
            TabView(selection: $selectedIndex) {
                ForEach(Array(documents.enumerated()), id: \.element.id) { index, doc in
                    VStack(spacing: 0) {
                        if let image = UIImage(data: doc.data) {
                            ZStack {
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(Color.white)
                                    .shadow(color: .black.opacity(0.1), radius: 15, y: 8)
                                
                                Image(uiImage: image)
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .clipShape(RoundedRectangle(cornerRadius: 12))
                                    .padding(8)
                            }
                            .padding(.horizontal, 30)
                        } else {
                            documentPlaceholder(doc)
                                .padding(.horizontal, 30)
                        }
                    }
                    .tag(index)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .frame(maxHeight: 350)
            
            HStack(spacing: 6) {
                ForEach(0..<documents.count, id: \.self) { index in
                    Circle()
                        .fill(index == selectedIndex ? Color(hex: "E53935") : Color.gray.opacity(0.3))
                        .frame(width: 8, height: 8)
                        .animation(.easeInOut(duration: 0.2), value: selectedIndex)
                }
            }
            
            Text("\(selectedIndex + 1) of \(documents.count)")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(Array(documents.enumerated()), id: \.element.id) { index, doc in
                        Button {
                            withAnimation {
                                selectedIndex = index
                            }
                        } label: {
                            if let image = UIImage(data: doc.data) {
                                Image(uiImage: image)
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                                    .frame(width: 60, height: 75)
                                    .clipShape(RoundedRectangle(cornerRadius: 8))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 8)
                                            .stroke(index == selectedIndex ? Color(hex: "E53935") : Color.clear, lineWidth: 3)
                                    )
                            } else {
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(Color.gray.opacity(0.2))
                                    .frame(width: 60, height: 75)
                                    .overlay(
                                        Image(systemName: "doc.fill")
                                            .foregroundStyle(.gray)
                                    )
                            }
                        }
                    }
                }
                .padding(.horizontal, 20)
            }
            .frame(height: 80)
        }
        .padding(.top, 20)
    }
    
    private func documentPlaceholder(_ doc: SelectedDocument) -> some View {
        VStack(spacing: 12) {
            Image(systemName: "doc.fill")
                .font(.system(size: 60))
                .foregroundStyle(.gray.opacity(0.4))
            
            Text(doc.name)
                .font(.headline)
            
            Text(".\(doc.fileExtension.uppercased())")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 200)
        .background(Color.white, in: RoundedRectangle(cornerRadius: 16))
    }
    
    private var bottomButtons: some View {
        VStack(spacing: 0) {
            Divider()
            
            Button {
                convertToPDF()
            } label: {
                HStack(spacing: 10) {
                    Image(systemName: documents.count > 1 ? "doc.on.doc.fill" : "doc.fill")
                    Text(documents.count > 1 ? "Merge \(documents.count) Pages to PDF" : "Convert to PDF")
                }
                .font(.headline)
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(Color(hex: "E53935"), in: RoundedRectangle(cornerRadius: 14))
            }
            .disabled(isConverting)
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
        }
        .background(.ultraThinMaterial)
    }
    
    private func convertToPDF() {
        isConverting = true
        
        Task {
            do {
                var pdfData: Data
                
                if documents.count == 1, let doc = documents.first {
                    if doc.fileExtension.lowercased() == "pdf" {
                        pdfData = doc.data
                    } else if ["jpg", "jpeg", "png", "heic", "heif"].contains(doc.fileExtension.lowercased()) {
                        pdfData = createPDFFromImages([doc.data])
                    } else {
                        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent("\(doc.name).\(doc.fileExtension)")
                        try doc.data.write(to: tempURL)
                        pdfData = try await CloudConvertService.shared.convertToPDF(fileURL: tempURL, filename: doc.name)
                        try? FileManager.default.removeItem(at: tempURL)
                    }
                } else {
                    let imageData = documents.compactMap { $0.data }
                    pdfData = createPDFFromImages(imageData)
                }
                
                let filename = documents.count == 1 
                    ? "\(documents[0].name)_\(Int(Date().timeIntervalSince1970)).pdf"
                    : "Merged_\(Int(Date().timeIntervalSince1970)).pdf"
                
                let fileURL = try await HistoryManager.shared.saveDocument(data: pdfData, filename: filename)
                
                let historyItem = HistoryItem(
                    fileName: filename,
                    originalFormat: documents.first?.fileExtension ?? "unknown",
                    resultFormat: "pdf",
                    direction: documents.count > 1 ? .merge : .toPDF,
                    source: source,
                    fileURL: fileURL
                )
                HistoryManager.shared.addItem(historyItem)
                
                convertedPDFData = pdfData
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
    
    private func createPDFFromImages(_ imagesData: [Data]) -> Data {
        let pdfDocument = PDFDocument()
        
        for (index, data) in imagesData.enumerated() {
            guard let image = UIImage(data: data) else { continue }
            
            let pageRect = CGRect(x: 0, y: 0, width: image.size.width, height: image.size.height)
            let renderer = UIGraphicsPDFRenderer(bounds: pageRect)
            
            let pageData = renderer.pdfData { context in
                context.beginPage()
                image.draw(in: pageRect)
            }
            
            if let pagePDF = PDFDocument(data: pageData),
               let page = pagePDF.page(at: 0) {
                pdfDocument.insert(page, at: index)
            }
        }
        
        return pdfDocument.dataRepresentation() ?? Data()
    }
}

struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

#Preview("Single") {
    DocumentPreviewView(
        documents: [
            SelectedDocument(name: "Photo", fileExtension: "jpg", data: Data())
        ],
        source: .gallery
    )
}

#Preview("Multiple") {
    DocumentPreviewView(
        documents: [
            SelectedDocument(name: "Scan 1", fileExtension: "jpg", data: Data()),
            SelectedDocument(name: "Scan 2", fileExtension: "jpg", data: Data()),
            SelectedDocument(name: "Scan 3", fileExtension: "jpg", data: Data())
        ],
        source: .camera
    )
}
