import SwiftUI
import UniformTypeIdentifiers
import PDFKit
import Combine
import PurchaseKit

struct ConvertFromPDFView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel = ConvertFromPDFViewModel()
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                if viewModel.selectedPDF == nil {
                    selectPDFView
                } else {
                    pdfOptionsView
                }
            }
            .navigationTitle("Convert from PDF")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
            .fileImporter(
                isPresented: $viewModel.showFilePicker,
                allowedContentTypes: [.pdf],
                allowsMultipleSelection: false
            ) { result in
                viewModel.handleFileImport(result)
            }
            .fullScreenCover(isPresented: $viewModel.showFormatPicker) {
                FormatPickerView(
                    selectedFormat: $viewModel.selectedFormat,
                    onConvert: { viewModel.startConversion() }
                )
            }
            .fullScreenCover(isPresented: $viewModel.showEditor) {
                if let pdfData = viewModel.selectedPDF?.data {
                    PDFEditorView(pdfData: pdfData)
                }
            }
            .overlay {
                if viewModel.isConverting {
                    LoadingOverlay(message: "Converting...")
                }
            }
            .fullScreenCover(isPresented: $viewModel.showResult) {
                if let data = viewModel.convertedData {
                    ConversionResultView(
                        data: data,
                        filename: viewModel.convertedFilename,
                        format: viewModel.selectedFormat.rawValue
                    )
                }
            }
            .onChange(of: viewModel.showResult) { newValue in
                if !newValue && viewModel.convertedData != nil {
                    dismiss()
                }
            }
            .alert("Error", isPresented: $viewModel.showError) {
                Button("OK") {}
            } message: {
                Text(viewModel.errorMessage)
            }
        }
    }
    
    private var selectPDFView: some View {
        VStack(spacing: 20) {
            Spacer()
            
            Image(systemName: "doc.fill")
                .font(.system(size: 60))
                .foregroundStyle(.gray.opacity(0.4))
            
            Text("Select a PDF file")
                .font(.title3.weight(.medium))
            
            Text("Choose a PDF to convert or edit")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            
            Button {
                viewModel.showFilePicker = true
            } label: {
                Text("Choose PDF")
                    .font(.headline)
                    .foregroundStyle(.white)
                    .frame(width: 200)
                    .padding(.vertical, 14)
                    .background(Color(hex: "4A9EF7"), in: RoundedRectangle(cornerRadius: 12))
            }
            .padding(.top, 10)
            
            Spacer()
        }
    }
    
    private var pdfOptionsView: some View {
        VStack(spacing: 20) {
            if let pdf = viewModel.selectedPDF {
                PDFThumbnailView(data: pdf.data)
                    .frame(height: 300)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .shadow(color: .black.opacity(0.1), radius: 10, y: 5)
                    .padding(.horizontal, 40)
                
                Text(pdf.name)
                    .font(.headline)
                
                Text("\(pdf.pageCount) pages")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
            
            VStack(spacing: 12) {
                PremiumConvertButton(
                    showFormatPicker: $viewModel.showFormatPicker
                )
                
                PremiumEditButton(
                    showEditor: $viewModel.showEditor
                )
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 20)
        }
    }
}

struct PDFThumbnailView: View {
    let data: Data
    @State private var thumbnail: UIImage?
    
    var body: some View {
        Group {
            if let thumbnail = thumbnail {
                Image(uiImage: thumbnail)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
            } else {
                Rectangle()
                    .fill(Color.gray.opacity(0.1))
                    .overlay(ProgressView())
            }
        }
        .onAppear {
            generateThumbnail()
        }
    }
    
    private func generateThumbnail() {
        guard let document = PDFDocument(data: data),
              let page = document.page(at: 0) else { return }
        
        let pageRect = page.bounds(for: .mediaBox)
        let renderer = UIGraphicsImageRenderer(size: pageRect.size)
        
        thumbnail = renderer.image { context in
            UIColor.white.setFill()
            context.fill(pageRect)
            
            context.cgContext.translateBy(x: 0, y: pageRect.height)
            context.cgContext.scaleBy(x: 1, y: -1)
            
            page.draw(with: .mediaBox, to: context.cgContext)
        }
    }
}

@MainActor
final class ConvertFromPDFViewModel: ObservableObject {
    @Published var showFilePicker = false
    @Published var showFormatPicker = false
    @Published var showEditor = false
    @Published var showResult = false
    @Published var selectedPDF: SelectedPDF?
    @Published var selectedFormat: ConversionFormat = .docx
    @Published var isConverting = false
    @Published var showError = false
    @Published var errorMessage = ""
    
    var convertedData: Data?
    var convertedFilename = ""
    
    func handleFileImport(_ result: Result<[URL], Error>) {
        switch result {
        case .success(let urls):
            guard let url = urls.first else { return }
            guard url.startAccessingSecurityScopedResource() else { return }
            defer { url.stopAccessingSecurityScopedResource() }
            
            if let data = try? Data(contentsOf: url),
               let document = PDFDocument(data: data) {
                selectedPDF = SelectedPDF(
                    name: url.deletingPathExtension().lastPathComponent,
                    data: data,
                    pageCount: document.pageCount
                )
            }
            
        case .failure(let error):
            errorMessage = error.localizedDescription
            showError = true
        }
    }
    
    func startConversion() {
        guard let pdf = selectedPDF else { return }
        isConverting = true
        
        Task {
            do {
                let resultData = try await CloudConvertService.shared.convertFromPDF(
                    pdfData: pdf.data,
                    filename: "\(pdf.name).pdf",
                    to: selectedFormat
                )
                
                let filename = "\(pdf.name)_converted.\(selectedFormat.rawValue)"
                let fileURL = try await HistoryManager.shared.saveDocument(data: resultData, filename: filename)
                
                let historyItem = HistoryItem(
                    fileName: filename,
                    originalFormat: "pdf",
                    resultFormat: selectedFormat.rawValue,
                    direction: .fromPDF,
                    source: .files,
                    fileURL: fileURL
                )
                HistoryManager.shared.addItem(historyItem)
                
                convertedData = resultData
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

struct SelectedPDF: Identifiable {
    let id = UUID()
    let name: String
    let data: Data
    let pageCount: Int
}

struct FormatPickerView: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var selectedFormat: ConversionFormat
    let onConvert: () -> Void
    
    let formats: [ConversionFormat] = [.docx, .xlsx, .pptx, .jpg, .png, .txt]
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                Text("Choose output format")
                    .font(.title3.weight(.medium))
                    .padding(.top, 20)
                
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 100))], spacing: 16) {
                    ForEach(formats, id: \.self) { format in
                        FormatButton(
                            format: format,
                            isSelected: selectedFormat == format
                        ) {
                            selectedFormat = format
                        }
                    }
                }
                .padding(.horizontal, 20)
                
                Spacer()
                
                Button {
                    dismiss()
                    onConvert()
                } label: {
                    Text("Convert to \(selectedFormat.displayName)")
                        .font(.headline)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(Color(hex: "4A9EF7"), in: RoundedRectangle(cornerRadius: 14))
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 20)
            }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
        .presentationDetents([.medium])
    }
}

private struct FormatButton: View {
    let format: ConversionFormat
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: iconFor(format))
                    .font(.title2)
                
                Text(format.displayName)
                    .font(.caption.weight(.medium))
            }
            .frame(width: 80, height: 80)
            .background(
                isSelected ? Color(hex: "4A9EF7").opacity(0.1) : Color.gray.opacity(0.1),
                in: RoundedRectangle(cornerRadius: 12)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? Color(hex: "4A9EF7") : Color.clear, lineWidth: 2)
            )
        }
        .foregroundStyle(isSelected ? Color(hex: "4A9EF7") : .primary)
    }
    
    private func iconFor(_ format: ConversionFormat) -> String {
        switch format {
        case .pdf: return "doc.fill"
        case .jpg, .png: return "photo.fill"
        case .docx: return "doc.text.fill"
        case .xlsx: return "tablecells.fill"
        case .pptx: return "rectangle.stack.fill"
        case .txt: return "doc.plaintext.fill"
        }
    }
}

private struct PremiumConvertButton: View {
    @Binding var showFormatPicker: Bool
    @ObservedObject private var subscription = PurchaseKitSubscription.shared
    
    private var hasPremium: Bool {
        subscription.isPremium
    }
    
    var body: some View {
        Button {
            if hasPremium {
                showFormatPicker = true
            } else {
                PurchaseKitAPI.showPaywall()
            }
        } label: {
            ZStack(alignment: .topTrailing) {
                HStack {
                    Image(systemName: "arrow.triangle.2.circlepath")
                    Text("Convert")
                }
                .font(.headline)
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(Color(hex: "4A9EF7"), in: RoundedRectangle(cornerRadius: 14))
                
                if !hasPremium {
                    Image(systemName: "lock.fill")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(.white)
                        .padding(5)
                        .background(Color(hex: "E53935"), in: Circle())
                        .offset(x: 6, y: -6)
                }
            }
        }
    }
}

private struct PremiumEditButton: View {
    @Binding var showEditor: Bool
    @ObservedObject private var subscription = PurchaseKitSubscription.shared
    
    private var hasPremium: Bool {
        subscription.isPremium
    }
    
    var body: some View {
        Button {
            if hasPremium {
                showEditor = true
            } else {
                PurchaseKitAPI.showPaywall()
            }
        } label: {
            ZStack(alignment: .topTrailing) {
                HStack {
                    Image(systemName: "pencil")
                    Text("Edit")
                }
                .font(.headline)
                .foregroundStyle(Color(hex: "4A9EF7"))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(Color(hex: "4A9EF7").opacity(0.1), in: RoundedRectangle(cornerRadius: 14))
                
                if !hasPremium {
                    Image(systemName: "lock.fill")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(.white)
                        .padding(5)
                        .background(Color(hex: "E53935"), in: Circle())
                        .offset(x: 6, y: -6)
                }
            }
        }
    }
}

#Preview {
    ConvertFromPDFView()
}

