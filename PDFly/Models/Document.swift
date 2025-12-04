import Foundation
import SwiftUI

enum DocumentSource: String, Codable {
    case files
    case gallery
    case camera
    case url
}

enum DocumentType: String, Codable {
    case pdf
    case image
    case document
    case spreadsheet
    case presentation
    case text
    case unknown
    
    init(from extension: String) {
        switch `extension`.lowercased() {
        case "pdf":
            self = .pdf
        case "jpg", "jpeg", "png", "heic", "heif", "gif", "bmp", "tiff":
            self = .image
        case "doc", "docx", "odt", "rtf":
            self = .document
        case "xls", "xlsx", "ods", "csv":
            self = .spreadsheet
        case "ppt", "pptx", "odp":
            self = .presentation
        case "txt", "md":
            self = .text
        default:
            self = .unknown
        }
    }
    
    var icon: String {
        switch self {
        case .pdf: return "doc.fill"
        case .image: return "photo.fill"
        case .document: return "doc.text.fill"
        case .spreadsheet: return "tablecells.fill"
        case .presentation: return "rectangle.stack.fill"
        case .text: return "doc.plaintext.fill"
        case .unknown: return "doc.fill"
        }
    }
    
    var color: Color {
        switch self {
        case .pdf: return .red
        case .image: return .blue
        case .document: return .indigo
        case .spreadsheet: return .green
        case .presentation: return .orange
        case .text: return .gray
        case .unknown: return .secondary
        }
    }
}

struct Document: Identifiable, Codable {
    let id: UUID
    var name: String
    let originalName: String
    let fileExtension: String
    let type: DocumentType
    let source: DocumentSource
    let createdAt: Date
    var fileURL: URL?
    var thumbnailData: Data?
    var pageCount: Int?
    var fileSize: Int64?
    
    init(
        id: UUID = UUID(),
        name: String,
        fileExtension: String,
        source: DocumentSource,
        fileURL: URL? = nil
    ) {
        self.id = id
        self.name = name
        self.originalName = name
        self.fileExtension = fileExtension
        self.type = DocumentType(from: fileExtension)
        self.source = source
        self.createdAt = Date()
        self.fileURL = fileURL
    }
    
    var displayName: String {
        if name.hasSuffix(".\(fileExtension)") {
            return name
        }
        return "\(name).\(fileExtension)"
    }
    
    var formattedSize: String {
        guard let size = fileSize else { return "" }
        let formatter = ByteCountFormatter()
        formatter.countStyle = .file
        return formatter.string(fromByteCount: size)
    }
    
    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: createdAt)
    }
}

struct ConversionResult: Identifiable {
    let id: UUID
    let document: Document
    let outputData: Data
    let outputFormat: String
    let convertedAt: Date
    
    init(document: Document, outputData: Data, outputFormat: String) {
        self.id = UUID()
        self.document = document
        self.outputData = outputData
        self.outputFormat = outputFormat
        self.convertedAt = Date()
    }
}




