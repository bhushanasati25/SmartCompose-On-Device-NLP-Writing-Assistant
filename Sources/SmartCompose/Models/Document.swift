import Foundation

/// Represents a user-created writing document persisted to the local file system.
struct Document: Identifiable, Codable, Hashable {
    let id: UUID
    var title: String
    var content: String
    var createdAt: Date
    var modifiedAt: Date
    var wordCount: Int
    var detectedLanguage: String?

    init(
        id: UUID = UUID(),
        title: String = "Untitled",
        content: String = "",
        createdAt: Date = Date(),
        modifiedAt: Date = Date(),
        wordCount: Int = 0,
        detectedLanguage: String? = nil
    ) {
        self.id = id
        self.title = title
        self.content = content
        self.createdAt = createdAt
        self.modifiedAt = modifiedAt
        self.wordCount = wordCount
        self.detectedLanguage = detectedLanguage
    }

    /// A short preview snippet of the document body.
    var snippet: String {
        let trimmed = content.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.count <= 120 {
            return trimmed
        }
        return String(trimmed.prefix(120)) + "…"
    }

    /// Formatted modification date for display.
    var formattedDate: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: modifiedAt, relativeTo: Date())
    }
}

// MARK: - File-System Persistence

extension Document {

    /// Root directory for all persisted documents.
    private static var documentsDirectory: URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appending(path: "SmartCompose", directoryHint: .isDirectory)
    }

    /// File URL for this specific document.
    private var fileURL: URL {
        Self.documentsDirectory.appending(path: "\(id.uuidString).json")
    }

    /// Saves the document to disk as a JSON file.
    func save() throws {
        let directory = Self.documentsDirectory
        if !FileManager.default.fileExists(atPath: directory.path()) {
            try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        }
        let data = try JSONEncoder().encode(self)
        try data.write(to: fileURL, options: .atomic)
    }

    /// Deletes the document's file from disk.
    func delete() throws {
        let url = fileURL
        if FileManager.default.fileExists(atPath: url.path()) {
            try FileManager.default.removeItem(at: url)
        }
    }

    /// Loads all persisted documents from the SmartCompose documents directory.
    static func loadAll() throws -> [Document] {
        let directory = documentsDirectory
        guard FileManager.default.fileExists(atPath: directory.path()) else {
            return []
        }

        let fileURLs = try FileManager.default.contentsOfDirectory(
            at: directory,
            includingPropertiesForKeys: nil,
            options: .skipsHiddenFiles
        ).filter { $0.pathExtension == "json" }

        let decoder = JSONDecoder()
        return fileURLs.compactMap { url in
            guard let data = try? Data(contentsOf: url) else { return nil }
            return try? decoder.decode(Document.self, from: data)
        }.sorted { $0.modifiedAt > $1.modifiedAt }
    }
}
