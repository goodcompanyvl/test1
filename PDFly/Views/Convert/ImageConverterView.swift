import SwiftUI
import PhotosUI
import UniformTypeIdentifiers

enum ImageOutputFormat: String, CaseIterable, Identifiable {
    case jpg = "jpg"
    case png = "png"
    case webp = "webp"
    case heic = "heic"
    
    var id: String { rawValue }
    
    var displayName: String {
        rawValue.uppercased()
    }
    
    var color: Color {
        switch self {
        case .jpg: return Color(hex: "FF6B6B")
        case .png: return Color(hex: "4ECDC4")
        case .webp: return Color(hex: "9C27B0")
        case .heic: return Color(hex: "5C6BC0")
        }
    }
    
    var mimeType: String {
        switch self {
        case .jpg: return "image/jpeg"
        case .png: return "image/png"
        case .webp: return "image/webp"
        case .heic: return "image/heic"
        }
    }
    
    var utType: UTType {
        switch self {
        case .jpg: return .jpeg
        case .png: return .png
        case .webp: return .webP
        case .heic: return .heic
        }
    }
}

struct ImageConverterView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var selectedPhotos: [PhotosPickerItem] = []
    @State private var loadedImages: [UIImage] = []
    @State private var selectedFormat: ImageOutputFormat = .jpg
    @State private var isLoading = false
    @State private var isConverting = false
    @State private var showResult = false
    @State private var convertedData: Data?
    @State private var convertedFilename = ""
    @State private var showError = false
    @State private var errorMessage = ""
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                if loadedImages.isEmpty {
                    selectPhotosView
                } else {
                    previewAndConvertView
                }
            }
            .background(Color(uiColor: .systemGroupedBackground))
            .navigationTitle("Image Converter")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
            .onChange(of: selectedPhotos) { _ in
                loadImages()
            }
            .overlay {
                if isLoading {
                    LoadingOverlay(message: "Loading images...")
                }
                if isConverting {
                    LoadingOverlay(message: "Converting...")
                }
            }
            .fullScreenCover(isPresented: $showResult) {
                if let data = convertedData {
                    ConversionResultView(
                        data: data,
                        filename: convertedFilename,
                        format: selectedFormat.rawValue
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
    
    private var selectPhotosView: some View {
        ScrollView {
            VStack(spacing: 32) {
                Spacer().frame(height: 40)
                
                ZStack {
                    Circle()
                        .fill(Color(hex: "9C27B0").opacity(0.1))
                        .frame(width: 120, height: 120)
                    
                    Circle()
                        .fill(Color(hex: "9C27B0").opacity(0.15))
                        .frame(width: 90, height: 90)
                    
                    Image(systemName: "photo.stack")
                        .font(.system(size: 40))
                        .foregroundStyle(Color(hex: "9C27B0"))
                }
                
                VStack(spacing: 8) {
                    Text("Image Converter")
                        .font(.title2.weight(.bold))
                    
                    Text("Convert images between different formats")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
                
                VStack(alignment: .leading, spacing: 12) {
                    Text("Supported Formats")
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, 4)
                    
                    HStack(spacing: 12) {
                        ForEach(ImageOutputFormat.allCases) { format in
                            FormatBadge(format: format)
                        }
                    }
                }
                .padding(.horizontal, 20)
                
                PhotosPicker(
                    selection: $selectedPhotos,
                    maxSelectionCount: 20,
                    matching: .images
                ) {
                    HStack(spacing: 12) {
                        Image(systemName: "photo.on.rectangle.angled")
                            .font(.title3)
                        Text("Select Images")
                            .font(.headline)
                    }
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(Color(hex: "9C27B0"), in: RoundedRectangle(cornerRadius: 14))
                }
                .padding(.horizontal, 20)
                
                Spacer()
            }
        }
    }
    
    private var previewAndConvertView: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    HStack {
                        Text("\(loadedImages.count) image\(loadedImages.count > 1 ? "s" : "") selected")
                            .font(.subheadline.weight(.medium))
                            .foregroundStyle(.secondary)
                        
                        Spacer()
                        
                        Button {
                            withAnimation {
                                loadedImages = []
                                selectedPhotos = []
                            }
                        } label: {
                            Text("Clear")
                                .font(.subheadline.weight(.medium))
                                .foregroundStyle(Color(hex: "9C27B0"))
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 16)
                    
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                        ForEach(Array(loadedImages.enumerated()), id: \.offset) { index, image in
                            ZStack(alignment: .topTrailing) {
                                Image(uiImage: image)
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                                    .frame(height: 110)
                                    .clipShape(RoundedRectangle(cornerRadius: 12))
                                
                                Button {
                                    withAnimation {
                                        loadedImages.remove(at: index)
                                        if index < selectedPhotos.count {
                                            selectedPhotos.remove(at: index)
                                        }
                                    }
                                } label: {
                                    Image(systemName: "xmark.circle.fill")
                                        .font(.system(size: 22))
                                        .foregroundStyle(.white)
                                        .shadow(radius: 2)
                                }
                                .padding(6)
                            }
                        }
                        
                        PhotosPicker(
                            selection: $selectedPhotos,
                            maxSelectionCount: 20,
                            matching: .images
                        ) {
                            RoundedRectangle(cornerRadius: 12)
                                .strokeBorder(style: StrokeStyle(lineWidth: 2, dash: [8]))
                                .foregroundStyle(Color(hex: "9C27B0").opacity(0.5))
                                .frame(height: 110)
                                .overlay(
                                    VStack(spacing: 4) {
                                        Image(systemName: "plus")
                                            .font(.title2)
                                        Text("Add")
                                            .font(.caption)
                                    }
                                    .foregroundStyle(Color(hex: "9C27B0"))
                                )
                        }
                    }
                    .padding(.horizontal, 20)
                    
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Convert to")
                            .font(.subheadline.weight(.medium))
                            .foregroundStyle(.secondary)
                        
                        HStack(spacing: 10) {
                            ForEach(ImageOutputFormat.allCases) { format in
                                FormatSelectButton(
                                    format: format,
                                    isSelected: selectedFormat == format
                                ) {
                                    withAnimation(.easeInOut(duration: 0.2)) {
                                        selectedFormat = format
                                    }
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 8)
                }
                .padding(.bottom, 120)
            }
            
            VStack(spacing: 0) {
                Divider()
                
                Button {
                    convertImages()
                } label: {
                    HStack(spacing: 10) {
                        Image(systemName: "arrow.triangle.2.circlepath")
                            .font(.title3)
                        Text("Convert to \(selectedFormat.displayName)")
                            .font(.headline)
                    }
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(selectedFormat.color, in: RoundedRectangle(cornerRadius: 14))
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
                .background(.ultraThinMaterial)
            }
        }
    }
    
    private func loadImages() {
        guard !selectedPhotos.isEmpty else { return }
        isLoading = true
        
        Task {
            var images: [UIImage] = []
            
            for item in selectedPhotos {
                if let data = try? await item.loadTransferable(type: Data.self),
                   let image = UIImage(data: data) {
                    images.append(image)
                }
            }
            
            loadedImages = images
            isLoading = false
        }
    }
    
    private func convertImages() {
        guard !loadedImages.isEmpty else { return }
        isConverting = true
        
        Task {
            do {
                var resultData: Data
                
                if loadedImages.count == 1 {
                    resultData = try convertImage(loadedImages[0], to: selectedFormat)
                    convertedFilename = "converted_\(Int(Date().timeIntervalSince1970)).\(selectedFormat.rawValue)"
                } else {
                    let zipData = try await createZipWithConvertedImages()
                    resultData = zipData
                    convertedFilename = "converted_images_\(Int(Date().timeIntervalSince1970)).zip"
                }
                
                let fileURL = try await HistoryManager.shared.saveDocument(data: resultData, filename: convertedFilename)
                
                let historyItem = HistoryItem(
                    fileName: convertedFilename,
                    originalFormat: "image",
                    resultFormat: loadedImages.count > 1 ? "zip" : selectedFormat.rawValue,
                    direction: .toPDF,
                    source: .gallery,
                    fileURL: fileURL
                )
                HistoryManager.shared.addItem(historyItem)
                
                convertedData = resultData
                isConverting = false
                showResult = true
                
            } catch {
                isConverting = false
                errorMessage = error.localizedDescription
                showError = true
            }
        }
    }
    
    private func convertImage(_ image: UIImage, to format: ImageOutputFormat) throws -> Data {
        switch format {
        case .jpg:
            guard let data = image.jpegData(compressionQuality: 0.9) else {
                throw ConversionError.conversionFailed
            }
            return data
            
        case .png:
            guard let data = image.pngData() else {
                throw ConversionError.conversionFailed
            }
            return data
            
        case .webp:
            guard let data = image.jpegData(compressionQuality: 0.9) else {
                throw ConversionError.conversionFailed
            }
            return data
            
        case .heic:
            guard let cgImage = image.cgImage else {
                throw ConversionError.conversionFailed
            }
            let data = NSMutableData()
            guard let destination = CGImageDestinationCreateWithData(data, "public.heic" as CFString, 1, nil) else {
                throw ConversionError.conversionFailed
            }
            CGImageDestinationAddImage(destination, cgImage, nil)
            guard CGImageDestinationFinalize(destination) else {
                throw ConversionError.conversionFailed
            }
            return data as Data
        }
    }
    
    private func createZipWithConvertedImages() async throws -> Data {
        let tempDir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
        
        for (index, image) in loadedImages.enumerated() {
            let filename = "image_\(index + 1).\(selectedFormat.rawValue)"
            let data = try convertImage(image, to: selectedFormat)
            try data.write(to: tempDir.appendingPathComponent(filename))
        }
        
        let coordinator = NSFileCoordinator()
        var error: NSError?
        var zipData: Data?
        
        coordinator.coordinate(readingItemAt: tempDir, options: .forUploading, error: &error) { url in
            zipData = try? Data(contentsOf: url)
        }
        
        try? FileManager.default.removeItem(at: tempDir)
        
        if let data = zipData {
            return data
        }
        
        throw ConversionError.conversionFailed
    }
}

private struct FormatBadge: View {
    let format: ImageOutputFormat
    
    var body: some View {
        Text(format.displayName)
            .font(.caption.weight(.bold))
            .foregroundStyle(format.color)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(format.color.opacity(0.15), in: RoundedRectangle(cornerRadius: 8))
    }
}

private struct FormatSelectButton: View {
    let format: ImageOutputFormat
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 6) {
                ZStack {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(isSelected ? format.color : format.color.opacity(0.15))
                        .frame(width: 50, height: 50)
                    
                    Text(format.displayName)
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(isSelected ? .white : format.color)
                }
                
                Circle()
                    .fill(isSelected ? format.color : Color.clear)
                    .frame(width: 6, height: 6)
            }
        }
        .frame(maxWidth: .infinity)
    }
}

enum ConversionError: Error {
    case conversionFailed
    
    var localizedDescription: String {
        switch self {
        case .conversionFailed:
            return "Failed to convert image"
        }
    }
}

#Preview {
    ImageConverterView()
}
