import Foundation
import Combine

actor HistoryService {
    static let shared = HistoryService()
    
    private let historyKey = "conversion_history"
    private let documentsDirectory: URL
    
    private init() {
        documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("PDFly", isDirectory: true)
        
        try? FileManager.default.createDirectory(at: documentsDirectory, withIntermediateDirectories: true)
    }
    
    func loadHistory() -> [HistoryItem] {
        guard let data = UserDefaults.standard.data(forKey: historyKey),
              let items = try? JSONDecoder().decode([HistoryItem].self, from: data) else {
            return []
        }
        return items.sorted { $0.createdAt > $1.createdAt }
    }
    
    func saveHistory(_ items: [HistoryItem]) {
        guard let data = try? JSONEncoder().encode(items) else { return }
        UserDefaults.standard.set(data, forKey: historyKey)
    }
    
    func addItem(_ item: HistoryItem) {
        var items = loadHistory()
        items.insert(item, at: 0)
        saveHistory(items)
    }
    
    func deleteItem(_ item: HistoryItem) {
        var items = loadHistory()
        items.removeAll { $0.id == item.id }
        saveHistory(items)
        
        if let fileURL = item.fileURL {
            try? FileManager.default.removeItem(at: fileURL)
        }
    }
    
    func clearHistory() {
        let items = loadHistory()
        for item in items {
            if let fileURL = item.fileURL {
                try? FileManager.default.removeItem(at: fileURL)
            }
        }
        saveHistory([])
    }
    
    func saveDocument(data: Data, filename: String) throws -> URL {
        let fileURL = documentsDirectory.appendingPathComponent(filename)
        try data.write(to: fileURL)
        return fileURL
    }
    
    func loadDocument(from url: URL) throws -> Data {
        try Data(contentsOf: url)
    }
    
    func deleteDocument(at url: URL) {
        try? FileManager.default.removeItem(at: url)
    }
    
    func getDocumentsDirectory() -> URL {
        documentsDirectory
    }
}

@MainActor
final class HistoryManager: ObservableObject {
    static let shared = HistoryManager()
    
    @Published var items: [HistoryItem] = []
    @Published var isLoading = false
    
    private init() {
        loadItems()
    }
    
    func loadItems() {
        Task {
            let loaded = await HistoryService.shared.loadHistory()
            items = loaded
        }
    }
    
    func addItem(_ item: HistoryItem) {
        Task {
            await HistoryService.shared.addItem(item)
            loadItems()
        }
    }
    
    func deleteItem(_ item: HistoryItem) {
        Task {
            await HistoryService.shared.deleteItem(item)
            loadItems()
        }
    }
    
    func clearHistory() {
        Task {
            await HistoryService.shared.clearHistory()
            items = []
        }
    }
    
    func saveDocument(data: Data, filename: String) async throws -> URL {
        try await HistoryService.shared.saveDocument(data: data, filename: filename)
    }
}

