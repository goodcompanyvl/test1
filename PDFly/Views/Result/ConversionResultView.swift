import SwiftUI
import QuickLook
import UniformTypeIdentifiers

struct ConversionResultView: View {
    @Environment(\.dismiss) private var dismiss
    let data: Data
    let filename: String
    let format: String
    
    @State private var showShareSheet = false
    @State private var showFileSaver = false
    @State private var showSaveSuccess = false
    @State private var previewURL: URL?
    @State private var showPreview = false
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                Spacer()
                
                successIcon
                
                VStack(spacing: 8) {
                    Text("Conversion Complete!")
                        .font(.title2.weight(.bold))
                    
                    Text(filename)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                    
                    Text(formattedSize)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                
                Spacer()
                
                actionButtons
                
                secondaryActions
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 20)
            .navigationTitle("Result")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .sheet(isPresented: $showShareSheet) {
                ShareSheet(items: [getFileURL()])
            }
            .sheet(isPresented: $showFileSaver) {
                DocumentExportPicker(fileURL: getFileURL()) { success in
                    if success {
                        showSaveSuccess = true
                    }
                }
            }
            .quickLookPreview($previewURL)
            .alert("Saved!", isPresented: $showSaveSuccess) {
                Button("OK") {}
            } message: {
                Text("File saved successfully.")
            }
        }
    }
    
    private var successIcon: some View {
        ZStack {
            Circle()
                .fill(Color(hex: "E53935").opacity(0.1))
                .frame(width: 120, height: 120)
            
            Circle()
                .fill(Color(hex: "E53935").opacity(0.2))
                .frame(width: 90, height: 90)
            
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 60))
                .foregroundStyle(Color(hex: "E53935"))
        }
    }
    
    private var formattedSize: String {
        let formatter = ByteCountFormatter()
        formatter.countStyle = .file
        return formatter.string(fromByteCount: Int64(data.count))
    }
    
    private var actionButtons: some View {
        VStack(spacing: 12) {
            Button {
                previewURL = getFileURL()
                showPreview = true
            } label: {
                ActionRow(
                    icon: "eye.fill",
                    title: "Preview",
                    subtitle: "View the converted file"
                )
            }
            
            Button {
                showShareSheet = true
            } label: {
                ActionRow(
                    icon: "square.and.arrow.up.fill",
                    title: "Share",
                    subtitle: "Send via AirDrop, Messages, Mail..."
                )
            }
            
            Button {
                showFileSaver = true
            } label: {
                ActionRow(
                    icon: "folder.fill",
                    title: "Save to Files",
                    subtitle: "Save to iCloud or local storage"
                )
            }
        }
    }
    
    private var secondaryActions: some View {
        HStack(spacing: 20) {
            SecondaryButton(icon: "doc.on.doc", title: "Copy") {
                copyToClipboard()
            }
            
            SecondaryButton(icon: "printer", title: "Print") {
                printFile()
            }
            
            SecondaryButton(icon: "arrow.clockwise", title: "Convert Again") {
                dismiss()
            }
        }
        .padding(.top, 12)
    }
    
    private func getFileURL() -> URL {
        let tempDir = FileManager.default.temporaryDirectory
        let fileURL = tempDir.appendingPathComponent(filename)
        try? data.write(to: fileURL)
        return fileURL
    }
    
    private func copyToClipboard() {
        UIPasteboard.general.setData(data, forPasteboardType: format == "pdf" ? "com.adobe.pdf" : "public.data")
    }
    
    private func printFile() {
        guard format == "pdf" || ["jpg", "jpeg", "png"].contains(format.lowercased()) else { return }
        
        let printController = UIPrintInteractionController.shared
        printController.printingItem = data
        printController.present(animated: true)
    }
}

private struct ActionRow: View {
    let icon: String
    let title: String
    let subtitle: String
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundStyle(Color(hex: "E53935"))
                .frame(width: 44, height: 44)
                .background(Color(hex: "E53935").opacity(0.1), in: RoundedRectangle(cornerRadius: 12))
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.primary)
                
                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(16)
        .background(Color.white, in: RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.05), radius: 8, y: 2)
    }
}

private struct SecondaryButton: View {
    let icon: String
    let title: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 20))
                
                Text(title)
                    .font(.caption2)
            }
            .foregroundStyle(.secondary)
            .frame(width: 70, height: 60)
            .background(Color.gray.opacity(0.1), in: RoundedRectangle(cornerRadius: 12))
        }
    }
}

struct DocumentExportPicker: UIViewControllerRepresentable {
    let fileURL: URL
    let onCompletion: (Bool) -> Void
    
    func makeUIViewController(context: Context) -> UIDocumentPickerViewController {
        let picker = UIDocumentPickerViewController(forExporting: [fileURL], asCopy: true)
        picker.delegate = context.coordinator
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIDocumentPickerViewController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(onCompletion: onCompletion)
    }
    
    class Coordinator: NSObject, UIDocumentPickerDelegate {
        let onCompletion: (Bool) -> Void
        
        init(onCompletion: @escaping (Bool) -> Void) {
            self.onCompletion = onCompletion
        }
        
        func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
            onCompletion(true)
        }
        
        func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {
            onCompletion(false)
        }
    }
}

#Preview {
    ConversionResultView(
        data: Data(),
        filename: "document_converted.docx",
        format: "docx"
    )
}

