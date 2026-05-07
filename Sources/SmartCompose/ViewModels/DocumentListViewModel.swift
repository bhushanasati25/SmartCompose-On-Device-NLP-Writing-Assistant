import Foundation
import SwiftUI
import Observation

/// Manages the document library — loading, creating, deleting, and searching documents.
@Observable
@MainActor
class DocumentListViewModel {

    var documents: [Document] = []
    var searchText: String = ""
    var isLoading: Bool = false
    var sortOrder: SortOrder = .dateModified

    /// Filtered and sorted documents based on current search text and sort order.
    var filteredDocuments: [Document] {
        var results = documents

        if !searchText.isEmpty {
            results = results.filter { doc in
                doc.title.localizedCaseInsensitiveContains(searchText) ||
                doc.content.localizedCaseInsensitiveContains(searchText)
            }
        }

        switch sortOrder {
        case .dateModified:
            results.sort { $0.modifiedAt > $1.modifiedAt }
        case .dateCreated:
            results.sort { $0.createdAt > $1.createdAt }
        case .title:
            results.sort { $0.title.localizedCompare($1.title) == .orderedAscending }
        case .wordCount:
            results.sort { $0.wordCount > $1.wordCount }
        }

        return results
    }

    /// Total word count across all documents.
    var totalWordCount: Int {
        documents.reduce(0) { $0 + $1.wordCount }
    }

    init() {
        loadDocuments()
    }

    /// Loads all documents from disk.
    func loadDocuments() {
        isLoading = true
        do {
            documents = try Document.loadAll()
        } catch {
            print("[DocumentListViewModel] Failed to load documents: \(error)")
        }
        isLoading = false
    }

    /// Creates a new empty document and returns it.
    func createDocument() -> Document {
        let document = Document()
        documents.insert(document, at: 0)
        HapticManager.shared.documentAction()
        return document
    }

    /// Deletes a document from both memory and disk.
    func deleteDocument(_ document: Document) {
        do {
            try document.delete()
            documents.removeAll { $0.id == document.id }
            HapticManager.shared.documentAction()
        } catch {
            print("[DocumentListViewModel] Failed to delete document: \(error)")
            HapticManager.shared.error()
        }
    }

    /// Deletes documents at the given index set (for SwiftUI List integration).
    func deleteDocuments(at offsets: IndexSet) {
        let docsToDelete = offsets.map { filteredDocuments[$0] }
        for doc in docsToDelete {
            deleteDocument(doc)
        }
    }

    /// Available sort orders for the document list.
    enum SortOrder: String, CaseIterable {
        case dateModified = "Date Modified"
        case dateCreated = "Date Created"
        case title = "Title"
        case wordCount = "Word Count"

        var icon: String {
            switch self {
            case .dateModified: return "clock.arrow.circlepath"
            case .dateCreated: return "calendar"
            case .title: return "textformat.abc"
            case .wordCount: return "number"
            }
        }
    }
}
