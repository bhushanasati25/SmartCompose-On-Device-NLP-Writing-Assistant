import Foundation

/// Asynchronously computes writing analytics using the NLPEngine.
/// All analysis runs off the main thread via actor isolation.
actor TextAnalyzer {

    static let shared = TextAnalyzer()

    private let nlpEngine = NLPEngine.shared

    private init() {}

    /// Performs a full analysis of the given text, returning comprehensive writing metrics.
    func analyze(_ text: String) async -> WritingMetrics {
        guard !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return WritingMetrics()
        }

        // Run all analyses concurrently using structured concurrency
        async let words = nlpEngine.tokenizeWords(text)
        async let sentences = nlpEngine.tokenizeSentences(text)
        async let paragraphs = nlpEngine.tokenizeParagraphs(text)
        async let entities = nlpEngine.extractEntities(text)
        async let language = nlpEngine.detectLanguage(text)
        async let sentiment = nlpEngine.analyzeSentiment(text)

        let wordList = await words
        let sentenceList = await sentences
        let paragraphList = await paragraphs

        let wordCount = wordList.count
        let sentenceCount = max(sentenceList.count, 1)
        let paragraphCount = max(paragraphList.count, 1)

        let avgSentenceLength = Double(wordCount) / Double(sentenceCount)

        let characterCount = text.filter { !$0.isWhitespace }.count

        // Compute Flesch-Kincaid readability
        let readability = await computeReadability(
            words: wordList,
            sentenceCount: sentenceCount
        )

        var metrics = WritingMetrics()
        metrics.wordCount = wordCount
        metrics.sentenceCount = sentenceCount
        metrics.paragraphCount = paragraphCount
        metrics.averageSentenceLength = avgSentenceLength
        metrics.characterCount = characterCount
        metrics.readabilityScore = readability
        metrics.detectedLanguage = await language?.rawValue
        metrics.sentimentScore = await sentiment
        metrics.entities = await entities

        return metrics
    }

    /// Performs a lightweight analysis (word count only) for real-time feedback.
    func quickWordCount(_ text: String) async -> Int {
        return await nlpEngine.tokenizeWords(text).count
    }

    // MARK: - Readability

    /// Computes the Flesch Reading Ease score.
    /// Score: 0-100, higher = easier to read.
    /// Formula: 206.835 - 1.015 × (words/sentences) - 84.6 × (syllables/words)
    private func computeReadability(
        words: [String],
        sentenceCount: Int
    ) async -> Double {
        guard !words.isEmpty, sentenceCount > 0 else { return 0.0 }

        var totalSyllables = 0
        for word in words {
            totalSyllables += await nlpEngine.countSyllables(in: word)
        }

        let wordCount = Double(words.count)
        let avgWordsPerSentence = wordCount / Double(sentenceCount)
        let avgSyllablesPerWord = Double(totalSyllables) / wordCount

        let score = 206.835 - (1.015 * avgWordsPerSentence) - (84.6 * avgSyllablesPerWord)

        // Clamp to 0-100 range
        return min(max(score, 0.0), 100.0)
    }
}
