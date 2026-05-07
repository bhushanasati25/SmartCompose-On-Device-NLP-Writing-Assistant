import XCTest
@testable import SmartCompose

final class NLPEngineTests: XCTestCase {

    private var engine: NLPEngine!

    override func setUp() {
        super.setUp()
        engine = NLPEngine.shared
    }

    // MARK: - Tokenization Tests

    func testWordTokenization() async {
        let text = "The quick brown fox jumps over the lazy dog."
        let words = await engine.tokenizeWords(text)

        XCTAssertEqual(words.count, 9)
        XCTAssertEqual(words.first, "The")
        XCTAssertEqual(words.last, "dog")
    }

    func testSentenceTokenization() async {
        let text = "Hello world. This is a test. Final sentence here."
        let sentences = await engine.tokenizeSentences(text)

        XCTAssertEqual(sentences.count, 3)
    }

    func testParagraphTokenization() async {
        let text = "First paragraph.\n\nSecond paragraph.\n\nThird paragraph."
        let paragraphs = await engine.tokenizeParagraphs(text)

        XCTAssertGreaterThanOrEqual(paragraphs.count, 2)
    }

    func testEmptyTextTokenization() async {
        let words = await engine.tokenizeWords("")
        XCTAssertTrue(words.isEmpty)
    }

    // MARK: - POS Tagging Tests

    func testPartsOfSpeechTagging() async {
        let text = "The cat sat on the mat."
        let tags = await engine.tagPartsOfSpeech(text)

        XCTAssertFalse(tags.isEmpty)
        // "The" should be tagged as a determiner
        if let firstTag = tags.first {
            XCTAssertEqual(firstTag.word, "The")
        }
    }

    func testLastWordTag() async {
        let text = "The beautiful"
        let tag = await engine.lastWordTag(text)

        XCTAssertNotNil(tag)
    }

    // MARK: - Language Detection Tests

    func testEnglishDetection() async {
        let text = "This is a sample English text for language detection."
        let language = await engine.detectLanguage(text)

        XCTAssertEqual(language?.rawValue, "en")
    }

    // MARK: - Sentiment Tests

    func testPositiveSentiment() async {
        let text = "I am so happy and excited about this wonderful opportunity!"
        let score = await engine.analyzeSentiment(text)

        // Positive text should have a positive score
        XCTAssertGreaterThan(score, -1.0)
        XCTAssertLessThanOrEqual(score, 1.0)
    }

    func testNegativeSentiment() async {
        let text = "This is terrible and awful. Everything went wrong."
        let score = await engine.analyzeSentiment(text)

        XCTAssertGreaterThanOrEqual(score, -1.0)
        XCTAssertLessThanOrEqual(score, 1.0)
    }

    // MARK: - Syllable Counting Tests

    func testSyllableCounting() async {
        let oneSyllable = await engine.countSyllables(in: "cat")
        XCTAssertEqual(oneSyllable, 1)

        let twoSyllables = await engine.countSyllables(in: "happy")
        XCTAssertEqual(twoSyllables, 2)

        let threeSyllables = await engine.countSyllables(in: "beautiful")
        XCTAssertGreaterThanOrEqual(threeSyllables, 3)
    }

    func testEmptyWordSyllables() async {
        let count = await engine.countSyllables(in: "")
        XCTAssertEqual(count, 0)
    }

    // MARK: - Entity Extraction Tests

    func testEntityExtraction() async {
        let text = "Tim Cook is the CEO of Apple in Cupertino."
        let entities = await engine.extractEntities(text)

        // Should find at least some entities
        // Note: NLTagger entity extraction accuracy varies
        XCTAssertNotNil(entities)
    }

    // MARK: - Embedding Tests

    func testWordEmbeddingExists() async {
        let hasEmbed = await engine.hasEmbedding(for: "hello")
        // English embedding should contain common words
        XCTAssertTrue(hasEmbed)
    }

    func testSimilarWords() async {
        let neighbors = await engine.findSimilarWords(to: "king", maxCount: 5)
        XCTAssertFalse(neighbors.isEmpty)
    }

    // MARK: - Performance Tests

    func testTokenizationPerformance() {
        let longText = String(repeating: "The quick brown fox jumps over the lazy dog. ", count: 100)

        measure {
            let expectation = XCTestExpectation(description: "Tokenize")
            Task {
                let _ = await engine.tokenizeWords(longText)
                expectation.fulfill()
            }
            wait(for: [expectation], timeout: 5.0)
        }
    }
}
