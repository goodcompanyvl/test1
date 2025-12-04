import SwiftUI
import PDFKit
import PencilKit

struct PDFEditorView: View {
    @Environment(\.dismiss) private var dismiss
    let pdfData: Data
    @State private var pdfDocument: PDFDocument?
    @State private var currentPage = 0
    @State private var selectedTool: EditorTool = .none
    @State private var showPageManager = false
    @State private var showOCR = false
    @State private var isProcessing = false
    @State private var showShareSheet = false
    @State private var editedPDFData: Data?
    @State private var showSignature = false
    
    enum EditorTool: String, CaseIterable {
        case none, draw, text, signature, crop
        
        var icon: String {
            switch self {
            case .none: return "hand.point.up.fill"
            case .draw: return "pencil.tip"
            case .text: return "textformat"
            case .signature: return "signature"
            case .crop: return "crop"
            }
        }
        
        var title: String {
            switch self {
            case .none: return "Select"
            case .draw: return "Draw"
            case .text: return "Text"
            case .signature: return "Sign"
            case .crop: return "Crop"
            }
        }
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                if let document = pdfDocument {
                    PDFEditorContent(
                        document: document,
                        currentPage: $currentPage,
                        selectedTool: selectedTool
                    )
                } else {
                    ProgressView("Loading PDF...")
                }
                
                toolBar
            }
            .navigationTitle("Edit PDF")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                
                ToolbarItem(placement: .primaryAction) {
                    Menu {
                        Button {
                            savePDF()
                        } label: {
                            Label("Save", systemImage: "square.and.arrow.down")
                        }
                        
                        Button {
                            showShareSheet = true
                        } label: {
                            Label("Share", systemImage: "square.and.arrow.up")
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                }
            }
            .fullScreenCover(isPresented: $showPageManager) {
                if let document = pdfDocument {
                    PageManagerView(document: document, currentPage: $currentPage)
                }
            }
            .sheet(isPresented: $showShareSheet) {
                if let data = editedPDFData ?? pdfDocument?.dataRepresentation() {
                    ShareSheet(items: [data])
                }
            }
            .fullScreenCover(isPresented: $showSignature) {
                SignatureEditorView(pdfData: pdfData)
            }
            .overlay {
                if isProcessing {
                    LoadingOverlay(message: "Processing...")
                }
            }
            .onAppear {
                pdfDocument = PDFDocument(data: pdfData)
            }
        }
    }
    
    private var toolBar: some View {
        VStack(spacing: 0) {
            Divider()
            
            HStack(spacing: 0) {
                ForEach(EditorTool.allCases, id: \.self) { tool in
                    ToolButton(
                        tool: tool,
                        isSelected: selectedTool == tool
                    ) {
                        if tool == .signature {
                            showSignature = true
                        } else {
                            selectedTool = tool
                        }
                    }
                }
                
                Divider()
                    .frame(height: 30)
                    .padding(.horizontal, 8)
                
                Button {
                    showPageManager = true
                } label: {
                    VStack(spacing: 4) {
                        Image(systemName: "doc.on.doc")
                            .font(.system(size: 20))
                        Text("Pages")
                            .font(.caption2)
                    }
                    .foregroundStyle(.primary)
                    .frame(maxWidth: .infinity)
                }
                
                Button {
                    performOCR()
                } label: {
                    VStack(spacing: 4) {
                        Image(systemName: "text.viewfinder")
                            .font(.system(size: 20))
                        Text("OCR")
                            .font(.caption2)
                    }
                    .foregroundStyle(.primary)
                    .frame(maxWidth: .infinity)
                }
            }
            .padding(.vertical, 12)
            .background(Color(uiColor: .systemBackground))
        }
    }
    
    private func savePDF() {
        guard let document = pdfDocument,
              let data = document.dataRepresentation() else { return }
        
        editedPDFData = data
        
        Task {
            let filename = "edited_\(Int(Date().timeIntervalSince1970)).pdf"
            let fileURL = try? await HistoryManager.shared.saveDocument(data: data, filename: filename)
            
            let historyItem = HistoryItem(
                fileName: filename,
                originalFormat: "pdf",
                resultFormat: "pdf",
                direction: .edit,
                source: .files,
                fileURL: fileURL
            )
            HistoryManager.shared.addItem(historyItem)
        }
    }
    
    private func performOCR() {
        isProcessing = true
        
        Task {
            do {
                let ocrData = try await CloudConvertService.shared.ocrPDF(
                    pdfData: pdfData,
                    filename: "document.pdf"
                )
                
                if let newDocument = PDFDocument(data: ocrData) {
                    pdfDocument = newDocument
                    editedPDFData = ocrData
                }
                
                isProcessing = false
            } catch {
                isProcessing = false
            }
        }
    }
}

private struct ToolButton: View {
    let tool: PDFEditorView.EditorTool
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: tool.icon)
                    .font(.system(size: 20))
                Text(tool.title)
                    .font(.caption2)
            }
            .foregroundStyle(isSelected ? Color(hex: "4A9EF7") : .primary)
            .frame(maxWidth: .infinity)
        }
    }
}

struct PDFEditorContent: View {
    let document: PDFDocument
    @Binding var currentPage: Int
    let selectedTool: PDFEditorView.EditorTool
    
    var body: some View {
        PDFKitView(document: document, currentPage: $currentPage)
            .overlay(alignment: .bottom) {
                pageIndicator
            }
    }
    
    private var pageIndicator: some View {
        Text("Page \(currentPage + 1) of \(document.pageCount)")
            .font(.caption)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(.ultraThinMaterial, in: Capsule())
            .padding(.bottom, 8)
    }
}

struct PDFKitView: UIViewRepresentable {
    let document: PDFDocument
    @Binding var currentPage: Int
    
    func makeUIView(context: Context) -> PDFView {
        let pdfView = PDFView()
        pdfView.document = document
        pdfView.autoScales = true
        pdfView.displayMode = .singlePage
        pdfView.displayDirection = .horizontal
        pdfView.usePageViewController(true)
        
        NotificationCenter.default.addObserver(
            context.coordinator,
            selector: #selector(Coordinator.pageChanged),
            name: .PDFViewPageChanged,
            object: pdfView
        )
        
        return pdfView
    }
    
    func updateUIView(_ pdfView: PDFView, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject {
        let parent: PDFKitView
        
        init(_ parent: PDFKitView) {
            self.parent = parent
        }
        
        @objc func pageChanged(_ notification: Notification) {
            guard let pdfView = notification.object as? PDFView,
                  let currentPage = pdfView.currentPage,
                  let pageIndex = pdfView.document?.index(for: currentPage) else { return }
            
            DispatchQueue.main.async {
                self.parent.currentPage = pageIndex
            }
        }
    }
}

struct PageManagerView: View {
    @Environment(\.dismiss) private var dismiss
    let document: PDFDocument
    @Binding var currentPage: Int
    @State private var pages: [PageItem] = []
    
    struct PageItem: Identifiable {
        let id = UUID()
        let index: Int
        var thumbnail: UIImage?
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 100))], spacing: 16) {
                    ForEach(pages) { page in
                        PageThumbnail(
                            page: page,
                            isSelected: page.index == currentPage
                        ) {
                            currentPage = page.index
                            dismiss()
                        }
                    }
                }
                .padding(20)
            }
            .navigationTitle("Pages")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
            .onAppear {
                loadPages()
            }
        }
        .presentationDetents([.medium, .large])
    }
    
    private func loadPages() {
        pages = (0..<document.pageCount).map { index in
            var item = PageItem(index: index)
            if let page = document.page(at: index) {
                item.thumbnail = page.thumbnail(of: CGSize(width: 100, height: 140), for: .mediaBox)
            }
            return item
        }
    }
}

private struct PageThumbnail: View {
    let page: PageManagerView.PageItem
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                if let thumbnail = page.thumbnail {
                    Image(uiImage: thumbnail)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(height: 120)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(isSelected ? Color(hex: "4A9EF7") : Color.clear, lineWidth: 3)
                        )
                } else {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.gray.opacity(0.1))
                        .frame(height: 120)
                }
                
                Text("\(page.index + 1)")
                    .font(.caption)
                    .foregroundStyle(isSelected ? Color(hex: "4A9EF7") : .secondary)
            }
        }
    }
}

#Preview {
    PDFEditorView(pdfData: Data())
}

