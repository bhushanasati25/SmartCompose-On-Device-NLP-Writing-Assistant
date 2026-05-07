import Foundation

/// Manages the persisted n-gram frequency model used for text prediction.
/// The model is pre-seeded with common English phrases and learns from the user's writing.
actor LanguageModelStore {

    static let shared = LanguageModelStore()

    // MARK: - N-Gram Storage

    /// Trigram frequencies: "word1 word2" → ["word3": count]
    private var trigrams: [String: [String: Int]] = [:]

    /// Bigram frequencies: "word1" → ["word2": count]
    private var bigrams: [String: [String: Int]] = [:]

    /// Unigram frequencies: word → count
    private var unigrams: [String: Int] = [:]

    /// Total number of training tokens observed.
    private(set) var totalTokens: Int = 0

    // MARK: - Persistence

    private let fileManager = FileManager.default

    private var storageDirectory: URL {
        fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appending(path: "SmartCompose/LanguageModel", directoryHint: .isDirectory)
    }

    private var trigramsURL: URL { storageDirectory.appending(path: "trigrams.json") }
    private var bigramsURL: URL { storageDirectory.appending(path: "bigrams.json") }
    private var unigramsURL: URL { storageDirectory.appending(path: "unigrams.json") }

    private init() {
        Task {
            await initialize()
        }
    }

    private func initialize() {
        loadFromDisk()
        if totalTokens == 0 {
            seedWithDefaultCorpus()
        }
    }

    // MARK: - Training

    /// Trains the language model on the given text, updating n-gram frequencies.
    func train(on text: String) async {
        let nlpEngine = NLPEngine.shared
        let words = await nlpEngine.tokenizeWords(text)
            .map { $0.lowercased() }
            .filter { !$0.isEmpty }

        guard words.count >= 2 else { return }

        // Update unigrams
        for word in words {
            unigrams[word, default: 0] += 1
            totalTokens += 1
        }

        // Update bigrams
        for i in 0..<(words.count - 1) {
            let key = words[i]
            let nextWord = words[i + 1]
            bigrams[key, default: [:]][nextWord, default: 0] += 1
        }

        // Update trigrams
        for i in 0..<(words.count - 2) {
            let key = "\(words[i]) \(words[i + 1])"
            let nextWord = words[i + 2]
            trigrams[key, default: [:]][nextWord, default: 0] += 1
        }

        saveToDisk()
    }

    // MARK: - Prediction

    /// Predicts the next word given a context of 1-2 previous words.
    /// Returns an array of (word, probability) pairs sorted by probability descending.
    func predict(context: [String], maxResults: Int = 5) -> [(word: String, probability: Double)] {
        let lowered = context.map { $0.lowercased() }

        // Try trigram first (most specific)
        if lowered.count >= 2 {
            let key = "\(lowered[lowered.count - 2]) \(lowered[lowered.count - 1])"
            if let candidates = trigrams[key], !candidates.isEmpty {
                return topCandidates(from: candidates, maxResults: maxResults)
            }
        }

        // Fall back to bigram
        if let lastWord = lowered.last {
            if let candidates = bigrams[lastWord], !candidates.isEmpty {
                return topCandidates(from: candidates, maxResults: maxResults)
            }
        }

        // Fall back to unigram (most common words)
        if !unigrams.isEmpty {
            return topCandidates(from: unigrams, maxResults: maxResults)
        }

        return []
    }

    /// Checks whether the model has any data for a given context.
    func hasContext(for words: [String]) -> Bool {
        let lowered = words.map { $0.lowercased() }

        if lowered.count >= 2 {
            let key = "\(lowered[lowered.count - 2]) \(lowered[lowered.count - 1])"
            if trigrams[key] != nil { return true }
        }

        if let last = lowered.last, bigrams[last] != nil {
            return true
        }

        return false
    }

    /// Records that the user accepted a prediction, reinforcing the n-gram path.
    func reinforce(context: [String], acceptedWord: String) {
        let lowered = context.map { $0.lowercased() }
        let word = acceptedWord.lowercased()

        // Reinforce the n-gram path with bonus weight
        unigrams[word, default: 0] += 3

        if let last = lowered.last {
            bigrams[last, default: [:]][word, default: 0] += 3
        }

        if lowered.count >= 2 {
            let key = "\(lowered[lowered.count - 2]) \(lowered[lowered.count - 1])"
            trigrams[key, default: [:]][word, default: 0] += 3
        }

        saveToDisk()
    }

    /// Clears all learned data and re-seeds with the default corpus.
    func resetToDefaults() {
        trigrams = [:]
        bigrams = [:]
        unigrams = [:]
        totalTokens = 0
        seedWithDefaultCorpus()
        saveToDisk()
    }

    // MARK: - Private Helpers

    private func topCandidates(
        from frequency: [String: Int],
        maxResults: Int
    ) -> [(word: String, probability: Double)] {
        let total = Double(frequency.values.reduce(0, +))
        guard total > 0 else { return [] }

        return frequency
            .sorted { $0.value > $1.value }
            .prefix(maxResults)
            .map { (word: $0.key, probability: Double($0.value) / total) }
    }

    // MARK: - Disk I/O

    private func saveToDisk() {
        do {
            if !fileManager.fileExists(atPath: storageDirectory.path()) {
                try fileManager.createDirectory(at: storageDirectory, withIntermediateDirectories: true)
            }
            try JSONEncoder().encode(trigrams).write(to: trigramsURL, options: .atomic)
            try JSONEncoder().encode(bigrams).write(to: bigramsURL, options: .atomic)
            try JSONEncoder().encode(unigrams).write(to: unigramsURL, options: .atomic)
        } catch {
            print("[LanguageModelStore] Failed to save: \(error)")
        }
    }

    private func loadFromDisk() {
        let decoder = JSONDecoder()

        if let data = try? Data(contentsOf: trigramsURL) {
            trigrams = (try? decoder.decode([String: [String: Int]].self, from: data)) ?? [:]
        }
        if let data = try? Data(contentsOf: bigramsURL) {
            bigrams = (try? decoder.decode([String: [String: Int]].self, from: data)) ?? [:]
        }
        if let data = try? Data(contentsOf: unigramsURL) {
            unigrams = (try? decoder.decode([String: Int].self, from: data)) ?? [:]
            totalTokens = unigrams.values.reduce(0, +)
        }
    }

    // MARK: - Default Corpus

    /// Seeds the model with common English writing phrases to bootstrap predictions.
    private func seedWithDefaultCorpus() {
        let corpus = [
            // Professional email phrases
            "I hope this email finds you well",
            "Thank you for your prompt response",
            "I wanted to follow up on our previous conversation",
            "Please let me know if you have any questions",
            "I look forward to hearing from you",
            "As discussed in our meeting",
            "I am writing to inform you about",
            "Could you please provide more details",
            "I appreciate your time and consideration",
            "Best regards and have a great day",
            "Please find the attached document for your review",
            "I would like to schedule a meeting to discuss",
            "Thank you for your patience and understanding",
            "Let me know if there is anything else I can help with",
            "I am pleased to announce that we have",
            "We are excited to share this update with you",
            "Looking forward to our collaboration on this project",
            "The deadline for this task is next Friday",
            "Please review the document and provide your feedback",
            "I have completed the analysis and the results are",

            // General writing
            "The quick brown fox jumps over the lazy dog",
            "In conclusion we can see that the data suggests",
            "On the other hand there are several factors to consider",
            "Furthermore this approach provides significant advantages",
            "However it is important to note that",
            "Therefore we recommend the following course of action",
            "In addition to the points mentioned above",
            "According to the latest research findings",
            "This is an important development that affects",
            "We need to carefully evaluate all available options",

            // Common transitions
            "First and foremost we should consider",
            "Additionally it is worth mentioning that",
            "In summary the key takeaways are",
            "As a result of these changes we expect",
            "Nevertheless the overall impact remains positive",
            "Consequently we have decided to proceed with",
            "Meanwhile the team continues to make progress",
            "Subsequently we will need to address the following",

            // Technology and business
            "The implementation was completed ahead of schedule",
            "We have successfully deployed the new system",
            "The performance metrics show significant improvement",
            "Our team has been working diligently on this project",
            "The budget allocation for this quarter has been approved",
            "We are currently in the process of evaluating",
            "The project timeline has been updated accordingly",
            "Based on our analysis the recommended approach is",
        ]

        for sentence in corpus {
            let words = sentence.lowercased()
                .components(separatedBy: .whitespaces)
                .filter { !$0.isEmpty }

            for word in words {
                unigrams[word, default: 0] += 1
                totalTokens += 1
            }

            for i in 0..<(words.count - 1) {
                bigrams[words[i], default: [:]][words[i + 1], default: 0] += 1
            }

            for i in 0..<(words.count - 2) {
                let key = "\(words[i]) \(words[i + 1])"
                trigrams[key, default: [:]][words[i + 2], default: 0] += 1
            }
        }

        saveToDisk()
    }
}
