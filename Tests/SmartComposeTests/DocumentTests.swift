import XCTest
@testable import SmartCompose

final class DocumentTests: XCTestCase {

    // MARK: - Model Tests

    func testDocumentCreation() {
        let doc = Document(title: "Test Document", content: "Hello World")

        XCTAssertEqual(doc.title, "Test Document")
        XCTAssertEqual(doc.content, "Hello World")
        XCTAssertEqual(doc.wordCount, 0) // Not computed at creation
        XCTAssertNotNil(doc.id)
    }

    func testDocumentSnippetShort() {
        let doc = Document(content: "Short content.")
        XCTAssertEqual(doc.snippet, "Short content.")
    }

    func testDocumentSnippetLong() {
        let longContent = String(repeating: "word ", count: 50) // 250 chars
        let doc = Document(content: longContent)

        XCTAssertTrue(doc.snippet.count <= 121) // 120 + "…"
        XCTAssertTrue(doc.snippet.hasSuffix("…"))
    }

    func testDocumentSnippetEmpty() {
        let doc = Document(content: "")
        XCTAssertEqual(doc.snippet, "")
    }

    func testDocumentEquality() {
        let id = UUID()
        let doc1 = Document(id: id, title: "Test")
        let doc2 = Document(id: id, title: "Test")

        XCTAssertEqual(doc1, doc2)
    }

    func testDocumentFormattedDate() {
        let doc = Document()
        let formatted = doc.formattedDate
        XCTAssertFalse(formatted.isEmpty)
    }

    // MARK: - Encoding/Decoding Tests

    func testDocumentCodable() throws {
        let original = Document(
            title: "Codable Test",
            content: "Testing JSON encoding and decoding.",
            wordCount: 5,
            detectedLanguage: "en"
        )

        let encoder = JSONEncoder()
        let data = try encoder.encode(original)

        let decoder = JSONDecoder()
        let decoded = try decoder.decode(Document.self, from: data)

        XCTAssertEqual(original.id, decoded.id)
        XCTAssertEqual(original.title, decoded.title)
        XCTAssertEqual(original.content, decoded.content)
        XCTAssertEqual(original.wordCount, decoded.wordCount)
        XCTAssertEqual(original.detectedLanguage, decoded.detectedLanguage)
    }

    // MARK: - WritingMetrics Tests

    func testWritingMetricsDefaults() {
        let metrics = WritingMetrics()

        XCTAssertEqual(metrics.wordCount, 0)
        XCTAssertEqual(metrics.sentenceCount, 0)
        XCTAssertEqual(metrics.readabilityScore, 0.0)
        XCTAssertEqual(metrics.sentimentScore, 0.0)
        XCTAssertEqual(metrics.acceptanceRate, 0.0)
    }

    func testWritingMetricsReadabilityLabel() {
        var metrics = WritingMetrics()

        metrics.readabilityScore = 90
        XCTAssertEqual(metrics.readabilityLabel, .veryEasy)

        metrics.readabilityScore = 75
        XCTAssertEqual(metrics.readabilityLabel, .fairlyEasy)

        metrics.readabilityScore = 65
        XCTAssertEqual(metrics.readabilityLabel, .standard)

        metrics.readabilityScore = 25
        XCTAssertEqual(metrics.readabilityLabel, .veryDifficult)
    }

    func testWritingMetricsSentimentLabel() {
        var metrics = WritingMetrics()

        metrics.sentimentScore = 0.5
        XCTAssertEqual(metrics.sentimentLabel, "Positive")

        metrics.sentimentScore = 0.0
        XCTAssertEqual(metrics.sentimentLabel, "Neutral")

        metrics.sentimentScore = -0.5
        XCTAssertEqual(metrics.sentimentLabel, "Negative")
    }

    func testAcceptanceRate() {
        var metrics = WritingMetrics()

        metrics.suggestionsAccepted = 7
        metrics.suggestionsDismissed = 3
        XCTAssertEqual(metrics.acceptanceRate, 70.0)
    }

    func testEstimatedReadingTime() {
        var metrics = WritingMetrics()

        metrics.wordCount = 500
        XCTAssertEqual(metrics.estimatedReadingTime, 2.0, accuracy: 0.01)

        metrics.wordCount = 0
        XCTAssertEqual(metrics.estimatedReadingTime, 0.1) // Minimum
    }

    // MARK: - Entity Tests

    func testEntityType() {
        let entity = ExtractedEntity(text: "Apple", type: .organization)
        XCTAssertEqual(entity.type, .organization)
        XCTAssertEqual(entity.type.iconName, "building.2.fill")
    }
}
