import Foundation
import NaturalLanguage

/// Generates next-word predictions using a hybrid n-gram + embedding strategy.
/// All inference runs asynchronously on the actor's serial executor.
actor PredictionEngine {

    static let shared = PredictionEngine()

    private let nlpEngine = NLPEngine.shared
    private let languageModel = LanguageModelStore.shared

    /// Minimum confidence threshold to surface a prediction.
    private let confidenceThreshold: Double = 0.08

    /// Maximum number of words to predict ahead.
    private let maxPredictionWords: Int = 5

    private init() {}

    // MARK: - Public API

    /// Generates a text prediction based on the current text and cursor position.
    /// Returns nil if no confident prediction can be made.
    func predict(text: String, cursorOffset: Int) async -> Suggestion? {
        // Extract the text up to the cursor
        let textToCursor: String
        if cursorOffset >= text.count {
            textToCursor = text
        } else {
            let index = text.index(text.startIndex, offsetBy: max(0, cursorOffset))
            textToCursor = String(text[..<index])
        }

        // Tokenize context words
        let allWords = await nlpEngine.tokenizeWords(textToCursor)
        guard !allWords.isEmpty else { return nil }

        // Use the last 2-3 words as context
        let contextWords = Array(allWords.suffix(3))

        // Try to predict multiple words for a more useful suggestion
        var predictedWords: [String] = []
        var currentContext = contextWords
        var bestConfidence: Double = 0.0
        var primarySource: SuggestionSource = .ngram

        for _ in 0..<maxPredictionWords {
            guard let prediction = await predictNextWord(context: currentContext) else { break }

            // Stop if confidence drops too low after the first word
            if !predictedWords.isEmpty && prediction.confidence < confidenceThreshold * 0.5 {
                break
            }

            predictedWords.append(prediction.word)

            if prediction.confidence > bestConfidence {
                bestConfidence = prediction.confidence
                primarySource = prediction.source
            }

            // Shift context window forward
            currentContext = Array(currentContext.suffix(2)) + [prediction.word]
        }

        guard !predictedWords.isEmpty, bestConfidence >= confidenceThreshold else {
            return nil
        }

        let suggestionText = predictedWords.joined(separator: " ")

        return Suggestion(
            text: suggestionText,
            confidence: bestConfidence,
            source: primarySource,
            insertionOffset: cursorOffset
        )
    }

    /// Records that the user accepted a suggestion, reinforcing the language model.
    func acceptSuggestion(context: [String], accepted: String) async {
        let words = accepted.components(separatedBy: .whitespaces).filter { !$0.isEmpty }
        var currentContext = context

        for word in words {
            await languageModel.reinforce(context: currentContext, acceptedWord: word)
            currentContext = Array(currentContext.suffix(2)) + [word]
        }
    }

    // MARK: - Internal Prediction Logic

    /// Predicts a single next word using hybrid n-gram + embedding approach.
    private func predictNextWord(
        context: [String]
    ) async -> (word: String, confidence: Double, source: SuggestionSource)? {

        // 1. Try n-gram prediction first (highest confidence)
        let ngramResults = await languageModel.predict(context: context, maxResults: 5)

        if let topNgram = ngramResults.first, topNgram.probability >= confidenceThreshold {
            // Apply POS-aware filtering
            let filtered = await filterByPOS(candidates: ngramResults, context: context)

            if let best = filtered.first {
                return (word: best.word, confidence: best.probability, source: .ngram)
            }

            // If POS filtering removed all candidates, use unfiltered top result
            return (word: topNgram.word, confidence: topNgram.probability, source: .ngram)
        }

        // 2. Fall back to embedding-based prediction when n-gram confidence is low
        if let lastWord = context.last {
            let neighbors = await nlpEngine.findSimilarWords(to: lastWord, maxCount: 5)

            // Find a contextually appropriate neighbor
            for neighbor in neighbors {
                // Skip the context word itself and very short words
                guard neighbor.word != lastWord.lowercased(),
                      neighbor.word.count > 2 else { continue }

                // Convert distance to confidence (lower distance = higher confidence)
                let confidence = max(0, 1.0 - neighbor.distance)

                if confidence >= confidenceThreshold {
                    return (word: neighbor.word, confidence: confidence * 0.7, source: .embedding)
                }
            }
        }

        // 3. If we have some n-gram results but below threshold, use them with lower confidence
        if let topNgram = ngramResults.first, topNgram.probability > 0.02 {
            return (word: topNgram.word, confidence: topNgram.probability, source: .ngram)
        }

        return nil
    }

    /// Filters prediction candidates by expected POS tag based on the preceding context.
    private func filterByPOS(
        candidates: [(word: String, probability: Double)],
        context: [String]
    ) async -> [(word: String, probability: Double)] {
        // Determine what POS tag the last word has
        let contextText = context.joined(separator: " ")
        guard let lastTag = await nlpEngine.lastWordTag(contextText) else {
            return candidates
        }

        // Define expected follow-up POS tags
        let expectedTags: Set<NLTag>

        switch lastTag {
        case .determiner:
            // After a/an/the, expect noun or adjective
            expectedTags = [.noun, .adjective]
        case .adjective:
            // After an adjective, expect noun or another adjective
            expectedTags = [.noun, .adjective]
        case .verb:
            // After a verb, expect noun, determiner, adverb, or preposition
            expectedTags = [.noun, .determiner, .adverb, .preposition]
        case .preposition:
            // After a preposition, expect determiner or noun
            expectedTags = [.determiner, .noun, .adjective]
        case .noun:
            // After a noun, expect verb, conjunction, preposition
            expectedTags = [.verb, .conjunction, .preposition]
        default:
            return candidates
        }

        // Filter candidates by checking their likely POS tag
        var filtered: [(String, Double)] = []
        for candidate in candidates {
            let testSentence = contextText + " " + candidate.word
            let tags = await nlpEngine.tagPartsOfSpeech(testSentence)

            if let candidateTag = tags.last?.tag, expectedTags.contains(candidateTag) {
                filtered.append(candidate)
            }
        }

        return filtered
    }
}
