import SwiftUI
import PhotosUI
import UniformTypeIdentifiers
import Combine

struct ConvertToPDFView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel = ConvertToPDFViewModel()
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                Text("Select source")
                    .font(.title2.weight(.semibold))
                    .padding(.top, 20)
                
                VStack(spacing: 16) {
                    SourceButton(
                        icon: "folder.fill",
                        title: "Files",
                        subtitle: "Documents from storage",
                        color: .blue
                    ) {
                        viewModel.showFilePicker = true
                    }
                    
                    SourceButton(
                        icon: "photo.fill",
                        title: "Gallery",
                        subtitle: "Photos from library",
                        color: .green
                    ) {
                        viewModel.showPhotoPicker = true
                    }
                    
                    SourceButton(
                        icon: "camera.fill",
                        title: "Camera",
                        subtitle: "Take a photo",
                        color: .orange
                    ) {
                        viewModel.showCamera = true
                    }
                    
                    SourceButton(
                        icon: "link",
                        title: "URL Link",
                        subtitle: "Convert website to PDF",
                        color: .purple
                    ) {
                        viewModel.showURLInput = true
                    }
                }
                .padding(.horizontal, 20)
                
                Spacer()
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
            .fileImporter(
                isPresented: $viewModel.showFilePicker,
                allowedContentTypes: viewModel.allowedFileTypes,
                allowsMultipleSelection: true
            ) { result in
                viewModel.handleFileImport(result)
            }
            .photosPicker(
                isPresented: $viewModel.showPhotoPicker,
                selection: $viewModel.selectedPhotos,
                maxSelectionCount: 20,
                matching: .images
            )
            .fullScreenCover(isPresented: $viewModel.showCamera) {
                CameraView { images in
                    viewModel.handleCameraImages(images)
                }
                .ignoresSafeArea()
            }
            .fullScreenCover(isPresented: $viewModel.showURLInput) {
                URLInputView()
            }
            .fullScreenCover(isPresented: $viewModel.showPreview) {
                if let documents = viewModel.documentsToConvert {
                    DocumentPreviewView(documents: documents, source: viewModel.currentSource)
                }
            }
            .onChange(of: viewModel.showPreview) { newValue in
                if !newValue && viewModel.documentsToConvert != nil {
                    dismiss()
                }
            }
            .onChange(of: viewModel.selectedPhotos) { newValue in
                viewModel.handlePhotoSelection(newValue)
            }
            .overlay {
                if viewModel.isLoading {
                    LoadingOverlay(message: "Loading files...")
                }
            }
        }
    }
}

private struct SourceButton: View {
    let icon: String
    let title: String
    let subtitle: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundStyle(.white)
                    .frame(width: 50, height: 50)
                    .background(color, in: RoundedRectangle(cornerRadius: 12))
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.headline)
                        .foregroundStyle(.primary)
                    
                    Text(subtitle)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .foregroundStyle(.secondary)
            }
            .padding(16)
            .background(Color.white, in: RoundedRectangle(cornerRadius: 16))
            .shadow(color: .black.opacity(0.05), radius: 8, y: 2)
        }
    }
}

@MainActor
final class ConvertToPDFViewModel: ObservableObject {
    @Published var showFilePicker = false
    @Published var showPhotoPicker = false
    @Published var showCamera = false
    @Published var showURLInput = false
    @Published var showPreview = false
    @Published var isLoading = false
    @Published var selectedPhotos: [PhotosPickerItem] = []
    @Published var documentsToConvert: [SelectedDocument]?
    @Published var currentSource: DocumentSource = .files
    
    let allowedFileTypes: [UTType] = [
        .pdf,
        .image,
        .jpeg,
        .png,
        .heic,
        .plainText,
        .rtf,
        UTType("com.microsoft.word.doc") ?? .data,
        UTType("org.openxmlformats.wordprocessingml.document") ?? .data,
        UTType("com.microsoft.excel.xls") ?? .data,
        UTType("org.openxmlformats.spreadsheetml.sheet") ?? .data,
        UTType("com.microsoft.powerpoint.ppt") ?? .data,
        UTType("org.openxmlformats.presentationml.presentation") ?? .data
    ]
    
    func handleFileImport(_ result: Result<[URL], Error>) {
        switch result {
        case .success(let urls):
            currentSource = .files
            var documents: [SelectedDocument] = []
            for url in urls {
                guard url.startAccessingSecurityScopedResource() else { continue }
                defer { url.stopAccessingSecurityScopedResource() }
                
                if let data = try? Data(contentsOf: url) {
                    documents.append(SelectedDocument(
                        name: url.deletingPathExtension().lastPathComponent,
                        fileExtension: url.pathExtension,
                        data: data
                    ))
                }
            }
            if !documents.isEmpty {
                documentsToConvert = documents
                showPreview = true
            }
            
        case .failure(let error):
            print("File import error: \(error)")
        }
    }
    
    func handlePhotoSelection(_ items: [PhotosPickerItem]) {
        guard !items.isEmpty else { return }
        isLoading = true
        currentSource = .gallery
        
        Task {
            var documents: [SelectedDocument] = []
            
            for (index, item) in items.enumerated() {
                if let data = try? await item.loadTransferable(type: Data.self) {
                    documents.append(SelectedDocument(
                        name: "Photo_\(index + 1)",
                        fileExtension: "jpg",
                        data: data
                    ))
                }
            }
            
            selectedPhotos = []
            isLoading = false
            
            if !documents.isEmpty {
                documentsToConvert = documents
                showPreview = true
            }
        }
    }
    
    func handleCameraImages(_ images: [UIImage]) {
        showCamera = false
        
        guard !images.isEmpty else { return }
        
        currentSource = .camera
        var documents: [SelectedDocument] = []
        
        for (index, image) in images.enumerated() {
            if let data = image.jpegData(compressionQuality: 0.8) {
                documents.append(SelectedDocument(
                    name: "Scan_\(index + 1)",
                    fileExtension: "jpg",
                    data: data
                ))
            }
        }
        
        if !documents.isEmpty {
            documentsToConvert = documents
            showPreview = true
        }
    }
}

struct SelectedDocument: Identifiable {
    let id = UUID()
    var name: String
    let fileExtension: String
    let data: Data
    var order: Int = 0
    
    var thumbnail: UIImage? {
        UIImage(data: data)
    }
}

struct LoadingOverlay: View {
    let message: String
    
    var body: some View {
        ZStack {
            Color.black.opacity(0.4)
                .ignoresSafeArea()
            
            VStack(spacing: 16) {
                ProgressView()
                    .scaleEffect(1.5)
                    .tint(.white)
                
                Text(message)
                    .font(.subheadline)
                    .foregroundStyle(.white)
            }
            .padding(32)
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 20))
        }
    }
}

#Preview {
    ConvertToPDFView()
}

