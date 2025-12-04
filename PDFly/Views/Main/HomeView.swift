import SwiftUI
import PurchaseKit
import UniformTypeIdentifiers
import UIKit

struct HomeView: View {
    @State private var showFilePicker = false
    @State private var showCamera = false
    @State private var showSettings = false
    @State private var showHistory = false
    @State private var showImageConverter = false
    @State private var showSignature = false
    @State private var selectedFromPDFFormat: OutputFormat?
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    imageConverterSection
                    pdfToolsSection
                    convertToPDFSection
                    convertFromPDFSection
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 100)
            }
            .background(Color(uiColor: .systemGroupedBackground))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        showSettings = true
                    } label: {
                        Image(systemName: "gearshape")
                            .foregroundStyle(Color(hex: "E53935"))
                    }
                }
                
                ToolbarItem(placement: .principal) {
                    Text("PDF Converter")
                        .font(.headline)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showHistory = true
                    } label: {
                        Image(systemName: "list.bullet.rectangle")
                            .foregroundStyle(Color(hex: "E53935"))
                    }
                }
            }
            .fullScreenCover(isPresented: $showSettings) {
                SettingsView()
            }
            .fullScreenCover(isPresented: $showHistory) {
                HistoryView()
            }
            .fullScreenCover(isPresented: $showFilePicker) {
                ConvertToPDFView()
            }
            .fullScreenCover(isPresented: $showCamera) {
                CameraToPDFView()
            }
            .fullScreenCover(isPresented: $showImageConverter) {
                ImageConverterView()
            }
            .fullScreenCover(isPresented: $showSignature) {
                AddSignatureFlowView()
            }
            .fullScreenCover(item: $selectedFromPDFFormat) { format in
                ConvertFromPDFFlowView(outputFormat: format)
            }
        }
    }
    
    private var imageConverterSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Image Converter")
                .font(.title3.weight(.semibold))
            
            ToPDFTile(
                icon: "photo.on.rectangle.angled",
                iconColor: Color(hex: "9C27B0"),
                title: "Images",
                subtitle: "convert between JPG, PNG, WEBP, HEIC",
                isWide: true
            ) {
                showImageConverter = true
            }
        }
    }
    
    private var pdfToolsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("PDF Tools")
                .font(.title3.weight(.semibold))
            
            ToPDFTile(
                icon: "signature",
                iconColor: Color(hex: "E53935"),
                title: "Add Signature",
                subtitle: "sign your PDF documents",
                isWide: true
            ) {
                showSignature = true
            }
        }
    }
    
    private var convertToPDFSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Convert to PDF")
                .font(.title3.weight(.semibold))
            
            HStack(spacing: 12) {
                ToPDFTile(
                    icon: "doc.fill",
                    iconColor: Color(hex: "E53935"),
                    title: "Files",
                    subtitle: "convert different\nfile types"
                ) {
                    showFilePicker = true
                }
                
                ToPDFTile(
                    icon: "camera.fill",
                    iconColor: Color(hex: "E53935"),
                    title: "Camera",
                    subtitle: "scan documents"
                ) {
                    showCamera = true
                }
            }
        }
    }
    
    private var convertFromPDFSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Convert from PDF")
                .font(.title3.weight(.semibold))
            
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                ForEach(OutputFormat.allCases) { format in
                    FromPDFTile(format: format) {
                        selectedFromPDFFormat = format
                    }
                }
            }
        }
    }
    
    }

private struct ToPDFTile: View {
    let icon: String
    let iconColor: Color
    let title: String
    let subtitle: String
    var isWide: Bool = false
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(iconColor.opacity(0.12))
                        .frame(width: 50, height: 50)
                    
                    Image(systemName: icon)
                        .font(.system(size: 22))
                        .foregroundStyle(iconColor)
                }
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.primary)
                    
                    Text(subtitle)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)
                }
                
                if isWide {
                    Spacer()
                }
            }
            .padding(12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.white, in: RoundedRectangle(cornerRadius: 16))
        }
        .buttonStyle(.plain)
    }
}

private struct FromPDFTile: View {
    let format: OutputFormat
    let action: () -> Void
    @ObservedObject private var subscription = PurchaseKitSubscription.shared
    
    private var hasPremium: Bool {
        subscription.isPremium
    }
    
    var body: some View {
        Button {
            if hasPremium {
                action()
            } else {
                PurchaseKitAPI.showPaywall()
            }
        } label: {
            VStack(spacing: 8) {
                ZStack {
                    FormatIconView(formatName: format.displayName, color: format.color)
                    
                    if !hasPremium {
                        Circle()
                            .fill(Color(hex: "E53935"))
                            .frame(width: 20, height: 20)
                            .overlay(
                                Image(systemName: "lock.fill")
                                    .font(.system(size: 10, weight: .bold))
                                    .foregroundStyle(.white)
                            )
                            .offset(x: 25, y: -25)
                    }
                }
                
                Text("\(format.displayName) from PDF")
                    .font(.caption.weight(.medium))
                    .foregroundStyle(.primary)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(Color.white, in: RoundedRectangle(cornerRadius: 16))
        }
        .buttonStyle(.plain)
    }
}


enum OutputFormat: String, CaseIterable, Identifiable {
    case docx, rtf, odt, html, epub, mobi, txt, jpg, png, xlsx, pptx
    
    var id: String { rawValue }
    
    var displayName: String {
        rawValue.uppercased()
    }
    
    var color: Color {
        switch self {
        case .docx: return Color(hex: "2B579A")
        case .rtf: return Color(hex: "1E3A5F")
        case .odt: return Color(hex: "FF6600")
        case .html: return Color(hex: "E44D26")
        case .epub: return Color(hex: "4CAF50")
        case .mobi: return Color(hex: "FF9900")
        case .txt: return Color(hex: "607D8B")
        case .jpg: return Color(hex: "00ACC1")
        case .png: return Color(hex: "9C27B0")
        case .xlsx: return Color(hex: "217346")
        case .pptx: return Color(hex: "D24726")
        }
    }
    
    var cloudConvertFormat: ConversionFormat {
        switch self {
        case .docx: return .docx
        case .rtf, .odt, .html, .epub, .mobi: return .txt
        case .txt: return .txt
        case .jpg: return .jpg
        case .png: return .png
        case .xlsx: return .xlsx
        case .pptx: return .pptx
        }
    }
}

struct HistoryView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var historyManager = HistoryManager.shared
    @State private var sortAscending = false
    @State private var selectedItem: HistoryItem?
    @State private var searchText = ""
    
    private var filteredItems: [HistoryItem] {
        let sorted = sortAscending
            ? historyManager.items.sorted { $0.createdAt < $1.createdAt }
            : historyManager.items.sorted { $0.createdAt > $1.createdAt }
        
        if searchText.isEmpty {
            return sorted
        }
        return sorted.filter {
            $0.fileName.localizedCaseInsensitiveContains(searchText) ||
            $0.resultFormat.localizedCaseInsensitiveContains(searchText) ||
            $0.originalFormat.localizedCaseInsensitiveContains(searchText)
        }
    }
    
    var body: some View {
        NavigationStack {
            Group {
                if historyManager.items.isEmpty {
                    emptyView
                } else {
                    listView
                }
            }
            .navigationTitle("History")
            .navigationBarTitleDisplayMode(.inline)
            .searchable(text: $searchText, prompt: "Search files")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
                
                if !historyManager.items.isEmpty {
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button {
                            sortAscending.toggle()
                        } label: {
                            Image(systemName: sortAscending ? "arrow.up" : "arrow.down")
                        }
                    }
                }
            }
            .fullScreenCover(item: $selectedItem) { item in
                HistoryItemDetailView(item: item)
            }
        }
    }
    
    private var emptyView: some View {
        VStack(spacing: 16) {
            Image(systemName: "doc.on.doc")
                .font(.system(size: 50))
                .foregroundStyle(.gray.opacity(0.4))
            
            Text("No conversion history yet")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
    }
    
    private var listView: some View {
        List {
            if filteredItems.isEmpty && !searchText.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 40))
                        .foregroundStyle(.secondary)
                    Text("No results for \"\(searchText)\"")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.top, 60)
                .listRowBackground(Color.clear)
            } else {
                ForEach(filteredItems) { item in
                    Button {
                        selectedItem = item
                    } label: {
                        HStack(spacing: 12) {
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color.gray.opacity(0.1))
                                .frame(width: 44, height: 54)
                                .overlay(
                                    Image(systemName: "doc.fill")
                                        .foregroundStyle(.gray.opacity(0.4))
                                )
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text(item.displayName)
                                    .font(.subheadline.weight(.medium))
                                    .lineLimit(1)
                                
                                Text(item.subtitle)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            
                            Spacer()
                            
                            Text(item.formattedDate)
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                            
                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .foregroundStyle(.primary)
                }
                .onDelete { indexSet in
                    for index in indexSet {
                        historyManager.deleteItem(filteredItems[index])
                    }
                }
            }
        }
    }
}

struct HistoryItemDetailView: View {
    @Environment(\.dismiss) private var dismiss
    let item: HistoryItem
    @State private var fileData: Data?
    @State private var loadError = false
    
    var body: some View {
        Group {
            if let data = fileData {
                ConversionResultView(
                    data: data,
                    filename: item.fileName,
                    format: item.resultFormat
                )
            } else if loadError {
                NavigationStack {
                    VStack(spacing: 20) {
                        Spacer()
                        
                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.system(size: 60))
                            .foregroundStyle(.orange)
                        
                        Text("File Not Found")
                            .font(.title2.weight(.bold))
                        
                        Text("The file may have been deleted or moved.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 40)
                        
                        Spacer()
                        
                        Button {
                            dismiss()
                        } label: {
                            Text("Close")
                                .font(.headline)
                                .foregroundStyle(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(Color(hex: "E53935"), in: RoundedRectangle(cornerRadius: 14))
                        }
                        .padding(.horizontal, 24)
                        .padding(.bottom, 20)
                    }
                    .navigationTitle("Error")
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .cancellationAction) {
                            Button("Close") { dismiss() }
                        }
                    }
                }
            } else {
                ProgressView("Loading...")
            }
        }
        .onAppear {
            loadFile()
        }
    }
    
    private func loadFile() {
        guard let fileURL = item.fileURL else {
            loadError = true
            return
        }
        
        do {
            fileData = try Data(contentsOf: fileURL)
        } catch {
            print("Error loading file: \(error)")
            loadError = true
        }
    }
}

struct CameraToPDFView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var capturedImages: [UIImage] = []
    @State private var showPreview = false
    @State private var showCameraUnavailable = false
    
    var isCameraAvailable: Bool {
        UIImagePickerController.isSourceTypeAvailable(.camera)
    }
    
    var body: some View {
        Group {
            if isCameraAvailable {
                CameraView { images in
                    capturedImages = images
                    if !images.isEmpty {
                        showPreview = true
                    } else {
                        dismiss()
                    }
                }
                .ignoresSafeArea()
            } else {
                cameraUnavailableView
            }
        }
        .fullScreenCover(isPresented: $showPreview) {
            let docs = capturedImages.enumerated().map { index, image in
                SelectedDocument(
                    name: "Scan_\(index + 1)",
                    fileExtension: "jpg",
                    data: image.jpegData(compressionQuality: 0.8) ?? Data()
                )
            }
            DocumentPreviewView(documents: docs, source: .camera)
        }
        .onChange(of: showPreview) { newValue in
            if !newValue && !capturedImages.isEmpty {
                dismiss()
            }
        }
    }
    
    private var cameraUnavailableView: some View {
        VStack(spacing: 20) {
            Spacer()
            
            Image(systemName: "camera.fill")
                .font(.system(size: 60))
                .foregroundStyle(.gray.opacity(0.4))
            
            Text("Camera Unavailable")
                .font(.title2.weight(.semibold))
            
            Text("Camera is not available on this device.\nPlease use a real device to scan documents.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
            
            Button {
                dismiss()
            } label: {
                Text("Go Back")
                    .font(.headline)
                    .foregroundStyle(.white)
                    .frame(width: 200)
                    .padding(.vertical, 14)
                    .background(Color(hex: "E53935"), in: RoundedRectangle(cornerRadius: 12))
            }
            .padding(.top, 20)
            
            Spacer()
        }
    }
}

struct ConvertFromPDFFlowView: View {
    @Environment(\.dismiss) private var dismiss
    let outputFormat: OutputFormat
    @State private var selectedPDF: SelectedPDF?
    @State private var showFilePicker = false
    @State private var isConverting = false
    @State private var showResult = false
    @State private var resultData: Data?
    @State private var resultFilename: String = ""
    @State private var showError = false
    @State private var errorMessage = ""
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                if let pdf = selectedPDF {
                    pdfSelectedView(pdf)
                } else {
                    selectPDFPrompt
                }
            }
            .navigationTitle("\(outputFormat.displayName) from PDF")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
            .fileImporter(
                isPresented: $showFilePicker,
                allowedContentTypes: [.pdf],
                allowsMultipleSelection: false
            ) { result in
                handleFileImport(result)
            }
            .overlay {
                if isConverting {
                    LoadingOverlay(message: "Converting to \(outputFormat.displayName)...")
                }
            }
            .fullScreenCover(isPresented: $showResult) {
                if let data = resultData {
                    ConversionResultView(
                        data: data,
                        filename: resultFilename,
                        format: outputFormat.rawValue
                    )
                }
            }
            .onChange(of: showResult) { newValue in
                if !newValue && resultData != nil {
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
    
    private var selectPDFPrompt: some View {
        VStack(spacing: 16) {
            Spacer()
            
            FormatIconView(formatName: outputFormat.displayName, color: outputFormat.color)
                .scaleEffect(1.5)
            
            Text("Select a PDF to convert")
                .font(.headline)
                .padding(.top, 20)
            
            Text("Your PDF will be converted to \(outputFormat.displayName) format")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
            
            Button {
                showFilePicker = true
            } label: {
                Text("Choose PDF")
                    .font(.headline)
                    .foregroundStyle(.white)
                    .frame(width: 200)
                    .padding(.vertical, 14)
                    .background(Color(hex: "E53935"), in: RoundedRectangle(cornerRadius: 12))
            }
            .padding(.top, 20)
            
            Spacer()
        }
    }
    
    private func pdfSelectedView(_ pdf: SelectedPDF) -> some View {
        VStack(spacing: 20) {
            Spacer()
            
            PDFThumbnailView(data: pdf.data)
                .frame(height: 250)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .shadow(color: .black.opacity(0.1), radius: 8, y: 4)
                .padding(.horizontal, 60)
            
            Text(pdf.name)
                .font(.headline)
            
            Text("\(pdf.pageCount) pages")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            
            Spacer()
            
            Button {
                convertPDF(pdf)
            } label: {
                Text("Convert to \(outputFormat.displayName)")
                    .font(.headline)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(outputFormat.color, in: RoundedRectangle(cornerRadius: 14))
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 20)
        }
    }
    
    private func handleFileImport(_ result: Result<[URL], Error>) {
        switch result {
        case .success(let urls):
            guard let url = urls.first else { return }
            guard url.startAccessingSecurityScopedResource() else { return }
            defer { url.stopAccessingSecurityScopedResource() }
            
            if let data = try? Data(contentsOf: url),
               let document = PDFKit.PDFDocument(data: data) {
                selectedPDF = SelectedPDF(
                    name: url.deletingPathExtension().lastPathComponent,
                    data: data,
                    pageCount: document.pageCount
                )
            }
            
        case .failure:
            dismiss()
        }
    }
    
    private func convertPDF(_ pdf: SelectedPDF) {
        isConverting = true
        
        Task {
            do {
                let convertedData = try await CloudConvertService.shared.convertFromPDF(
                    pdfData: pdf.data,
                    filename: "\(pdf.name).pdf",
                    to: outputFormat.cloudConvertFormat
                )
                
                let filename = "\(pdf.name)_converted.\(outputFormat.rawValue)"
                let fileURL = try await HistoryManager.shared.saveDocument(data: convertedData, filename: filename)
                
                let historyItem = HistoryItem(
                    fileName: filename,
                    originalFormat: "pdf",
                    resultFormat: outputFormat.rawValue,
                    direction: .fromPDF,
                    source: .files,
                    fileURL: fileURL
                )
                HistoryManager.shared.addItem(historyItem)
                
                isConverting = false
                resultData = convertedData
                resultFilename = filename
                showResult = true
                
            } catch {
                isConverting = false
                errorMessage = error.localizedDescription
                showError = true
            }
        }
    }
}

import PDFKit

#Preview {
    HomeView()
}
