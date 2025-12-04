import SwiftUI
import PencilKit
import PDFKit
import UniformTypeIdentifiers

struct SignaturePadView: View {
    @Environment(\.dismiss) private var dismiss
    let onSave: (UIImage) -> Void
    
    @State private var canvasView = PKCanvasView()
    @State private var savedSignatures: [UIImage] = []
    @State private var selectedTab = 0
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                Picker("", selection: $selectedTab) {
                    Text("Draw").tag(0)
                    Text("Saved").tag(1)
                }
                .pickerStyle(.segmented)
                .padding()
                
                if selectedTab == 0 {
                    drawView
                } else {
                    savedSignaturesView
                }
            }
            .background(Color(uiColor: .systemGroupedBackground))
            .navigationTitle("Signature")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
            .onAppear {
                loadSavedSignatures()
            }
        }
    }
    
    private var drawView: some View {
        VStack(spacing: 16) {
            Text("Draw your signature below")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            
            ZStack(alignment: .bottom) {
                SignatureCanvas(canvasView: $canvasView)
                    .frame(height: 200)
                    .background(Color.white)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                    )
                
                Rectangle()
                    .fill(Color.gray.opacity(0.3))
                    .frame(height: 1)
                    .padding(.horizontal, 40)
                    .padding(.bottom, 50)
            }
            .padding(.horizontal, 20)
            
            HStack(spacing: 16) {
                Button {
                    canvasView.drawing = PKDrawing()
                } label: {
                    Text("Clear")
                        .font(.headline)
                        .foregroundStyle(Color(hex: "E53935"))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(Color(hex: "E53935").opacity(0.1), in: RoundedRectangle(cornerRadius: 14))
                }
                
                Button {
                    saveAndUseSignature()
                } label: {
                    Text("Use Signature")
                        .font(.headline)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(Color(hex: "E53935"), in: RoundedRectangle(cornerRadius: 14))
                }
            }
            .padding(.horizontal, 20)
            
            Spacer()
        }
        .padding(.top, 8)
    }
    
    private var savedSignaturesView: some View {
        Group {
            if savedSignatures.isEmpty {
                VStack(spacing: 16) {
                    Spacer()
                    Image(systemName: "signature")
                        .font(.system(size: 50))
                        .foregroundStyle(.gray.opacity(0.4))
                    
                    Text("No saved signatures")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    
                    Text("Draw a signature and it will be saved here")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Spacer()
                }
            } else {
                ScrollView {
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                        ForEach(Array(savedSignatures.enumerated()), id: \.offset) { index, signature in
                            Button {
                                onSave(signature)
                                dismiss()
                            } label: {
                                Image(uiImage: signature)
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .frame(height: 80)
                                    .padding(16)
                                    .frame(maxWidth: .infinity)
                                    .background(Color.white, in: RoundedRectangle(cornerRadius: 12))
                            }
                            .contextMenu {
                                Button(role: .destructive) {
                                    deleteSignature(at: index)
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                }
                            }
                        }
                    }
                    .padding(20)
                }
            }
        }
    }
    
    private func saveAndUseSignature() {
        let image = canvasView.drawing.image(from: canvasView.bounds, scale: UIScreen.main.scale)
        
        if !canvasView.drawing.bounds.isEmpty {
            saveSignature(image)
        }
        
        onSave(image)
        dismiss()
    }
    
    private func loadSavedSignatures() {
        guard let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else { return }
        let signaturesURL = documentsURL.appendingPathComponent("Signatures")
        
        guard FileManager.default.fileExists(atPath: signaturesURL.path) else { return }
        
        do {
            let files = try FileManager.default.contentsOfDirectory(at: signaturesURL, includingPropertiesForKeys: nil)
            savedSignatures = files.compactMap { url -> UIImage? in
                guard let data = try? Data(contentsOf: url) else { return nil }
                return UIImage(data: data)
            }
        } catch {}
    }
    
    private func saveSignature(_ image: UIImage) {
        guard let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else { return }
        let signaturesURL = documentsURL.appendingPathComponent("Signatures")
        
        try? FileManager.default.createDirectory(at: signaturesURL, withIntermediateDirectories: true)
        
        let filename = "signature_\(Int(Date().timeIntervalSince1970)).png"
        let fileURL = signaturesURL.appendingPathComponent(filename)
        
        if let data = image.pngData() {
            try? data.write(to: fileURL)
            savedSignatures.append(image)
        }
    }
    
    private func deleteSignature(at index: Int) {
        guard let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else { return }
        let signaturesURL = documentsURL.appendingPathComponent("Signatures")
        
        do {
            let files = try FileManager.default.contentsOfDirectory(at: signaturesURL, includingPropertiesForKeys: nil)
            if index < files.count {
                try FileManager.default.removeItem(at: files[index])
                savedSignatures.remove(at: index)
            }
        } catch {}
    }
}

struct SignatureCanvas: UIViewRepresentable {
    @Binding var canvasView: PKCanvasView
    
    func makeUIView(context: Context) -> PKCanvasView {
        canvasView.tool = PKInkingTool(.pen, color: .black, width: 3)
        canvasView.backgroundColor = .clear
        canvasView.isOpaque = false
        canvasView.drawingPolicy = .anyInput
        return canvasView
    }
    
    func updateUIView(_ uiView: PKCanvasView, context: Context) {}
}

struct SignatureEditorView: View {
    @Environment(\.dismiss) private var dismiss
    let pdfData: Data
    
    @State private var pdfDocument: PDFDocument?
    @State private var currentPageIndex = 0
    @State private var signatureImage: UIImage?
    @State private var showSignaturePad = false
    @State private var signaturePosition: CGPoint = CGPoint(x: 200, y: 300)
    @State private var signatureScale: CGFloat = 1.0
    @State private var signatureRotation: Angle = .zero
    @State private var isSignatureFocused = true
    @State private var showResult = false
    @State private var resultData: Data?
    @State private var isProcessing = false
    @State private var viewSize: CGSize = .zero
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                if let document = pdfDocument {
                    GeometryReader { geometry in
                        ZStack {
                            PDFPageView(document: document, pageIndex: currentPageIndex)
                                .onTapGesture {
                                    isSignatureFocused = false
                                }
                            
                            if let signature = signatureImage {
                                DraggableSignature(
                                    image: signature,
                                    position: $signaturePosition,
                                    scale: $signatureScale,
                                    rotation: $signatureRotation,
                                    isFocused: $isSignatureFocused
                                )
                            }
                        }
                        .onAppear {
                            viewSize = geometry.size
                            signaturePosition = CGPoint(x: geometry.size.width / 2, y: geometry.size.height / 2)
                        }
                        .onChange(of: geometry.size) { newSize in
                            viewSize = newSize
                        }
                    }
                    .background(Color.gray.opacity(0.1))
                    
                    bottomControls(document: document)
                } else {
                    ProgressView("Loading PDF...")
                }
            }
            .navigationTitle("Add Signature")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                
                ToolbarItem(placement: .primaryAction) {
                    Button("Done") {
                        applySignature()
                    }
                    .disabled(signatureImage == nil)
                }
            }
            .sheet(isPresented: $showSignaturePad) {
                SignaturePadView { image in
                    signatureImage = image
                    resetSignatureState()
                }
            }
            .fullScreenCover(isPresented: $showResult) {
                if let data = resultData {
                    ConversionResultView(
                        data: data,
                        filename: "signed_document.pdf",
                        format: "pdf"
                    )
                }
            }
            .overlay {
                if isProcessing {
                    LoadingOverlay(message: "Applying signature...")
                }
            }
            .onChange(of: showResult) { newValue in
                if !newValue && resultData != nil {
                    dismiss()
                }
            }
            .onAppear {
                pdfDocument = PDFDocument(data: pdfData)
            }
        }
    }
    
    private func bottomControls(document: PDFDocument) -> some View {
        VStack(spacing: 0) {
            Divider()
            
            VStack(spacing: 12) {
                if document.pageCount > 1 {
                    HStack {
                        Button {
                            if currentPageIndex > 0 {
                                currentPageIndex -= 1
                            }
                        } label: {
                            Image(systemName: "chevron.left")
                                .font(.title3)
                                .foregroundStyle(currentPageIndex > 0 ? Color(hex: "E53935") : .gray)
                        }
                        .disabled(currentPageIndex == 0)
                        
                        Spacer()
                        
                        Text("Page \(currentPageIndex + 1) of \(document.pageCount)")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        
                        Spacer()
                        
                        Button {
                            if currentPageIndex < document.pageCount - 1 {
                                currentPageIndex += 1
                            }
                        } label: {
                            Image(systemName: "chevron.right")
                                .font(.title3)
                                .foregroundStyle(currentPageIndex < document.pageCount - 1 ? Color(hex: "E53935") : .gray)
                        }
                        .disabled(currentPageIndex >= document.pageCount - 1)
                    }
                    .padding(.horizontal, 20)
                }
                
                HStack(spacing: 12) {
                    Button {
                        showSignaturePad = true
                    } label: {
                        HStack {
                            Image(systemName: "signature")
                            Text(signatureImage == nil ? "Add Signature" : "Change Signature")
                        }
                        .font(.headline)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(Color(hex: "E53935"), in: RoundedRectangle(cornerRadius: 14))
                    }
                    
                    if signatureImage != nil {
                        Button {
                            signatureImage = nil
                            resetSignatureState()
                        } label: {
                            Image(systemName: "trash")
                                .font(.headline)
                                .foregroundStyle(Color(hex: "E53935"))
                                .frame(width: 54, height: 54)
                                .background(Color(hex: "E53935").opacity(0.1), in: RoundedRectangle(cornerRadius: 14))
                        }
                    }
                }
                .padding(.horizontal, 20)
            }
            .padding(.vertical, 16)
            .background(Color(uiColor: .systemBackground))
        }
    }
    
    private func resetSignatureState() {
        signaturePosition = CGPoint(x: viewSize.width / 2, y: viewSize.height / 2)
        signatureScale = 1.0
        signatureRotation = .zero
        isSignatureFocused = true
        print("🔄 Signature state reset to center: \(signaturePosition)")
    }
    
    private func applySignature() {
        guard let document = pdfDocument,
              let signature = signatureImage,
              let page = document.page(at: currentPageIndex) else { return }
        
        isProcessing = true
        
        let rotatedSignature = signature.rotated(by: signatureRotation.degrees)
        let capturedPosition = signaturePosition
        let capturedScale = signatureScale
        let capturedViewSize = viewSize
        
        DispatchQueue.global(qos: .userInitiated).async {
            let pageBounds = page.bounds(for: .mediaBox)
            
            let pdfAspect = pageBounds.width / pageBounds.height
            let viewAspect = capturedViewSize.width / capturedViewSize.height
            
            var displayWidth: CGFloat
            var displayHeight: CGFloat
            var offsetX: CGFloat = 0
            var offsetY: CGFloat = 0
            
            if pdfAspect > viewAspect {
                displayWidth = capturedViewSize.width
                displayHeight = capturedViewSize.width / pdfAspect
                offsetY = (capturedViewSize.height - displayHeight) / 2
            } else {
                displayHeight = capturedViewSize.height
                displayWidth = capturedViewSize.height * pdfAspect
                offsetX = (capturedViewSize.width - displayWidth) / 2
            }
            
            let relativeX = (capturedPosition.x - offsetX) / displayWidth
            let relativeY = (capturedPosition.y - offsetY) / displayHeight
            
            let signatureWidth: CGFloat = 150 * capturedScale * (pageBounds.width / displayWidth)
            let signatureHeight: CGFloat = 60 * capturedScale * (pageBounds.width / displayWidth)
            
            let pdfX = relativeX * pageBounds.width - signatureWidth / 2
            let pdfY = pageBounds.height - (relativeY * pageBounds.height) - signatureHeight / 2
            
            let signatureRect = CGRect(
                x: max(0, min(pageBounds.width - signatureWidth, pdfX)),
                y: max(0, min(pageBounds.height - signatureHeight, pdfY)),
                width: signatureWidth,
                height: signatureHeight
            )
            
            print("📍 View size: \(capturedViewSize)")
            print("📍 PDF bounds: \(pageBounds)")
            print("📍 Display size: \(displayWidth) x \(displayHeight), offset: \(offsetX), \(offsetY)")
            print("📍 Signature position in view: \(capturedPosition)")
            print("📍 Relative position: \(relativeX), \(relativeY)")
            print("📍 Signature rect in PDF: \(signatureRect)")
            
            if let signatureAnnotation = createSignatureAnnotation(image: rotatedSignature, rect: signatureRect) {
                page.addAnnotation(signatureAnnotation)
            }
            
            let signedData = document.dataRepresentation()
            
            DispatchQueue.main.async {
                isProcessing = false
                
                if let data = signedData {
                    Task {
                        let filename = "signed_\(Int(Date().timeIntervalSince1970)).pdf"
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
                    
                    resultData = data
                    showResult = true
                }
            }
        }
    }
    
    private func createSignatureAnnotation(image: UIImage, rect: CGRect) -> PDFAnnotation? {
        guard image.cgImage != nil else { return nil }
        return ImageStampAnnotation(bounds: rect, image: image)
    }
}

extension UIImage {
    func rotated(by degrees: Double) -> UIImage {
        guard degrees != 0 else { return self }
        
        let radians = CGFloat(degrees * .pi / 180)
        var newSize = CGRect(origin: .zero, size: size)
            .applying(CGAffineTransform(rotationAngle: radians))
            .integral.size
        newSize.width = floor(newSize.width)
        newSize.height = floor(newSize.height)
        
        UIGraphicsBeginImageContextWithOptions(newSize, false, scale)
        guard let context = UIGraphicsGetCurrentContext() else { return self }
        
        context.translateBy(x: newSize.width / 2, y: newSize.height / 2)
        context.rotate(by: radians)
        
        draw(in: CGRect(
            x: -size.width / 2,
            y: -size.height / 2,
            width: size.width,
            height: size.height
        ))
        
        let rotatedImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return rotatedImage ?? self
    }
}

class ImageStampAnnotation: PDFAnnotation {
    var stampImage: UIImage?
    
    init(bounds: CGRect, image: UIImage) {
        self.stampImage = image
        super.init(bounds: bounds, forType: .stamp, withProperties: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func draw(with box: PDFDisplayBox, in context: CGContext) {
        guard let image = stampImage, let cgImage = image.cgImage else {
            super.draw(with: box, in: context)
            return
        }
        
        context.saveGState()
        context.draw(cgImage, in: bounds)
        context.restoreGState()
    }
}

struct PDFPageView: UIViewRepresentable {
    let document: PDFDocument
    let pageIndex: Int
    
    func makeUIView(context: Context) -> PDFView {
        let pdfView = PDFView()
        pdfView.document = document
        pdfView.autoScales = true
        pdfView.displayMode = .singlePage
        pdfView.backgroundColor = .clear
        pdfView.isUserInteractionEnabled = false
        return pdfView
    }
    
    func updateUIView(_ pdfView: PDFView, context: Context) {
        if let page = document.page(at: pageIndex) {
            pdfView.go(to: page)
        }
    }
}

struct DraggableSignature: View {
    let image: UIImage
    @Binding var position: CGPoint
    @Binding var scale: CGFloat
    @Binding var rotation: Angle
    @Binding var isFocused: Bool
    
    @State private var dragOffset: CGSize = .zero
    @State private var currentScale: CGFloat = 1.0
    @State private var currentRotation: Angle = .zero
    
    private let baseWidth: CGFloat = 150
    private let baseHeight: CGFloat = 60
    
    var body: some View {
        ZStack(alignment: .topTrailing) {
            Image(uiImage: image)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: baseWidth * scale, height: baseHeight * scale)
            
            if isFocused {
                RoundedRectangle(cornerRadius: 4)
                    .stroke(Color(hex: "E53935"), style: StrokeStyle(lineWidth: 2, dash: [5]))
                    .frame(width: (baseWidth + 10) * scale, height: (baseHeight + 10) * scale)
                
                Button {
                    isFocused = false
                } label: {
                    Circle()
                        .fill(Color(hex: "E53935"))
                        .frame(width: 28, height: 28)
                        .overlay(
                            Image(systemName: "checkmark")
                                .font(.system(size: 14, weight: .bold))
                                .foregroundStyle(.white)
                        )
                }
                .offset(x: 14, y: -14)
            }
        }
        .frame(width: (baseWidth + 30) * scale, height: (baseHeight + 30) * scale)
        .contentShape(Rectangle())
        .rotationEffect(rotation + currentRotation)
        .scaleEffect(currentScale)
        .position(
            x: position.x + dragOffset.width,
            y: position.y + dragOffset.height
        )
        .onTapGesture {
            isFocused = true
        }
        .gesture(
            DragGesture()
                .onChanged { value in
                    dragOffset = value.translation
                }
                .onEnded { value in
                    position.x += value.translation.width
                    position.y += value.translation.height
                    dragOffset = .zero
                }
        )
        .simultaneousGesture(
            isFocused ?
            MagnificationGesture()
                .onChanged { value in
                    currentScale = value
                }
                .onEnded { value in
                    scale *= value
                    currentScale = 1.0
                }
            : nil
        )
        .simultaneousGesture(
            isFocused ?
            RotationGesture()
                .onChanged { value in
                    currentRotation = value
                }
                .onEnded { value in
                    rotation += value
                    currentRotation = .zero
                }
            : nil
        )
    }
}

struct AddSignatureFlowView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var selectedPDF: SelectedPDF?
    @State private var showFilePicker = false
    @State private var showSignatureEditor = false
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                if let pdf = selectedPDF {
                    pdfSelectedView(pdf)
                } else {
                    selectPDFPrompt
                }
            }
            .navigationTitle("Add Signature")
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
            .fullScreenCover(isPresented: $showSignatureEditor) {
                if let pdf = selectedPDF {
                    SignatureEditorView(pdfData: pdf.data)
                }
            }
            .onChange(of: showSignatureEditor) { newValue in
                if !newValue && selectedPDF != nil {
                    dismiss()
                }
            }
        }
    }
    
    private var selectPDFPrompt: some View {
        VStack(spacing: 16) {
            Spacer()
            
            ZStack {
                Circle()
                    .fill(Color(hex: "E53935").opacity(0.1))
                    .frame(width: 100, height: 100)
                
                Image(systemName: "signature")
                    .font(.system(size: 40))
                    .foregroundStyle(Color(hex: "E53935"))
            }
            
            Text("Select a PDF to sign")
                .font(.headline)
                .padding(.top, 20)
            
            Text("Choose a PDF document and add your signature")
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
                showSignatureEditor = true
            } label: {
                HStack {
                    Image(systemName: "signature")
                    Text("Add Signature")
                }
                .font(.headline)
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(Color(hex: "E53935"), in: RoundedRectangle(cornerRadius: 14))
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
               let document = PDFDocument(data: data) {
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
}

#Preview {
    SignaturePadView { _ in }
}

