import Foundation

enum ConversionDirection: String, Codable {
    case toPDF = "to_pdf"
    case fromPDF = "from_pdf"
    case urlToPDF = "url_to_pdf"
    case merge = "merge"
    case edit = "edit"
    
    var displayName: String {
        switch self {
        case .toPDF: return "Converted to PDF"
        case .fromPDF: return "Converted from PDF"
        case .urlToPDF: return "URL to PDF"
        case .merge: return "Merged PDFs"
        case .edit: return "Edited PDF"
        }
    }
    
    var icon: String {
        switch self {
        case .toPDF: return "arrow.right.doc.on.clipboard"
        case .fromPDF: return "arrow.left.doc.on.clipboard"
        case .urlToPDF: return "link"
        case .merge: return "doc.on.doc.fill"
        case .edit: return "pencil"
        }
    }
}

struct HistoryItem: Identifiable, Codable {
    let id: UUID
    let fileName: String
    let originalFormat: String
    let resultFormat: String
    let direction: ConversionDirection
    let source: DocumentSource
    let createdAt: Date
    let relativeFilePath: String?
    var thumbnailData: Data?
    var pageCount: Int?
    var fileSize: Int64?
    
    init(
        id: UUID = UUID(),
        fileName: String,
        originalFormat: String,
        resultFormat: String,
        direction: ConversionDirection,
        source: DocumentSource,
        fileURL: URL? = nil
    ) {
        self.id = id
        self.fileName = fileName
        self.originalFormat = originalFormat
        self.resultFormat = resultFormat
        self.direction = direction
        self.source = source
        self.createdAt = Date()
        self.relativeFilePath = fileURL?.lastPathComponent
    }
    
    var fileURL: URL? {
        guard let path = relativeFilePath else { return nil }
        let documentsDir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("PDFly", isDirectory: true)
        return documentsDir.appendingPathComponent(path)
    }
    
    var displayName: String {
        fileName
    }
    
    var subtitle: String {
        "\(originalFormat.uppercased()) → \(resultFormat.uppercased())"
    }
    
    var formattedDate: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: createdAt, relativeTo: Date())
    }
    
    var fullFormattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: createdAt)
    }
    
    var formattedSize: String {
        guard let size = fileSize else { return "" }
        let formatter = ByteCountFormatter()
        formatter.countStyle = .file
        return formatter.string(fromByteCount: size)
    }
}

extension HistoryItem {
    static func groupedByDate(_ items: [HistoryItem]) -> [(String, [HistoryItem])] {
        let calendar = Calendar.current
        let grouped = Dictionary(grouping: items) { item -> String in
            if calendar.isDateInToday(item.createdAt) {
                return "Today"
            } else if calendar.isDateInYesterday(item.createdAt) {
                return "Yesterday"
            } else {
                let formatter = DateFormatter()
                formatter.dateFormat = "MMM d, yyyy"
                return formatter.string(from: item.createdAt)
            }
        }
        
        return grouped.sorted { $0.value.first?.createdAt ?? Date() > $1.value.first?.createdAt ?? Date() }
    }
}

