import Foundation
import NaturalLanguage

/// Thread-safe NLP engine wrapping Apple's NaturalLanguage framework.
/// All processing runs on the actor's serial executor, never blocking the main thread.
actor NLPEngine {

    static let shared = NLPEngine()

    // MARK: - Cached Resources

    /// Pre-loaded word embedding for semantic similarity queries.
    private let wordEmbedding: NLEmbedding?

    private init() {
        // Load the English word embedding once — this is the most expensive initialization.
        self.wordEmbedding = NLEmbedding.wordEmbedding(for: .english)
    }

    // MARK: - Tokenization

    /// Tokenizes text into individual words.
    func tokenizeWords(_ text: String) -> [String] {
        let tokenizer = NLTokenizer(unit: .word)
        tokenizer.string = text
        return tokenizer.tokens(for: text.startIndex..<text.endIndex).map { range in
            String(text[range])
        }
    }

    /// Tokenizes text into sentences.
    func tokenizeSentences(_ text: String) -> [String] {
        let tokenizer = NLTokenizer(unit: .sentence)
        tokenizer.string = text
        return tokenizer.tokens(for: text.startIndex..<text.endIndex).map { range in
            String(text[range])
        }
    }

    /// Tokenizes text into paragraphs.
    func tokenizeParagraphs(_ text: String) -> [String] {
        let tokenizer = NLTokenizer(unit: .paragraph)
        tokenizer.string = text
        return tokenizer.tokens(for: text.startIndex..<text.endIndex).map { range in
            String(text[range])
        }
    }

    // MARK: - Part-of-Speech Tagging

    /// Returns POS tags for each word in the text.
    func tagPartsOfSpeech(_ text: String) -> [(word: String, tag: NLTag)] {
        let tagger = NLTagger(tagSchemes: [.lexicalClass])
        tagger.string = text

        var results: [(String, NLTag)] = []
        tagger.enumerateTags(
            in: text.startIndex..<text.endIndex,
            unit: .word,
            scheme: .lexicalClass
        ) { tag, range in
            if let tag = tag {
                results.append((String(text[range]), tag))
            }
            return true
        }
        return results
    }

    /// Returns the POS tag for the last word in the given text.
    func lastWordTag(_ text: String) -> NLTag? {
        let tags = tagPartsOfSpeech(text)
        return tags.last?.tag
    }

    // MARK: - Lemmatization

    /// Returns lemmatized forms of words in the text.
    func lemmatize(_ text: String) -> [(word: String, lemma: String)] {
        let tagger = NLTagger(tagSchemes: [.lemma])
        tagger.string = text

        var results: [(String, String)] = []
        tagger.enumerateTags(
            in: text.startIndex..<text.endIndex,
            unit: .word,
            scheme: .lemma
        ) { tag, range in
            let word = String(text[range])
            let lemma = tag?.rawValue ?? word
            results.append((word, lemma))
            return true
        }
        return results
    }

    // MARK: - Named Entity Recognition

    /// Extracts named entities (person, place, organization) from the text.
    func extractEntities(_ text: String) -> [ExtractedEntity] {
        let tagger = NLTagger(tagSchemes: [.nameType])
        tagger.string = text

        let options: NLTagger.Options = [.omitPunctuation, .omitWhitespace, .joinNames]
        var entities: [ExtractedEntity] = []

        tagger.enumerateTags(
            in: text.startIndex..<text.endIndex,
            unit: .word,
            scheme: .nameType,
            options: options
        ) { tag, range in
            guard let tag = tag else { return true }

            let entityText = String(text[range])
            let entityType: EntityType?

            switch tag {
            case .personalName:
                entityType = .person
            case .placeName:
                entityType = .place
            case .organizationName:
                entityType = .organization
            default:
                entityType = nil
            }

            if let type = entityType {
                // Avoid duplicates
                if !entities.contains(where: { $0.text == entityText && $0.type == type }) {
                    entities.append(ExtractedEntity(text: entityText, type: type))
                }
            }
            return true
        }
        return entities
    }

    // MARK: - Language Detection

    /// Detects the dominant language of the given text.
    func detectLanguage(_ text: String) -> NLLanguage? {
        let recognizer = NLLanguageRecognizer()
        recognizer.processString(text)
        return recognizer.dominantLanguage
    }

    // MARK: - Sentiment Analysis

    /// Returns a sentiment score from -1.0 (negative) to 1.0 (positive).
    func analyzeSentiment(_ text: String) -> Double {
        let tagger = NLTagger(tagSchemes: [.sentimentScore])
        tagger.string = text

        var totalScore: Double = 0.0
        var count: Int = 0

        tagger.enumerateTags(
            in: text.startIndex..<text.endIndex,
            unit: .paragraph,
            scheme: .sentimentScore
        ) { tag, _ in
            if let tag = tag, let score = Double(tag.rawValue) {
                totalScore += score
                count += 1
            }
            return true
        }

        guard count > 0 else { return 0.0 }
        return totalScore / Double(count)
    }

    // MARK: - Word Embeddings

    /// Finds the nearest semantic neighbors for a given word.
    /// Returns an array of (word, distance) pairs sorted by proximity.
    func findSimilarWords(to word: String, maxCount: Int = 10) -> [(word: String, distance: Double)] {
        guard let embedding = wordEmbedding else { return [] }

        var neighbors: [(String, Double)] = []
        embedding.enumerateNeighbors(for: word.lowercased(), maximumCount: maxCount) { neighbor, distance in
            neighbors.append((neighbor, distance))
            return true
        }
        return neighbors
    }

    /// Returns the cosine distance between two words (0.0 = identical, 2.0 = opposite).
    func wordDistance(_ wordA: String, _ wordB: String) -> Double? {
        guard let embedding = wordEmbedding else { return nil }
        return embedding.distance(between: wordA.lowercased(), and: wordB.lowercased())
    }

    /// Checks if a word exists in the embedding vocabulary.
    func hasEmbedding(for word: String) -> Bool {
        guard let embedding = wordEmbedding else { return false }
        return embedding.contains(word.lowercased())
    }

    // MARK: - Syllable Counting (for Readability)

    /// Estimates the number of syllables in a word using a heuristic approach.
    func countSyllables(in word: String) -> Int {
        let lowered = word.lowercased()
        guard !lowered.isEmpty else { return 0 }

        let vowels: Set<Character> = ["a", "e", "i", "o", "u", "y"]
        var count = 0
        var previousWasVowel = false

        for char in lowered {
            let isVowel = vowels.contains(char)
            if isVowel && !previousWasVowel {
                count += 1
            }
            previousWasVowel = isVowel
        }

        // Adjust for silent 'e' at end
        if lowered.hasSuffix("e") && count > 1 {
            count -= 1
        }

        // Ensure at least one syllable
        return max(count, 1)
    }
}
