#!/usr/bin/env swift

// build_corpus.swift
// Generates a seed n-gram frequency model from a curated text corpus.
// Usage: swift Scripts/build_corpus.swift

import Foundation

/// Builds trigram, bigram, and unigram frequency tables from input text.
func buildNGramModel(from texts: [String]) -> (
    trigrams: [String: [String: Int]],
    bigrams: [String: [String: Int]],
    unigrams: [String: Int]
) {
    var trigrams: [String: [String: Int]] = [:]
    var bigrams: [String: [String: Int]] = [:]
    var unigrams: [String: Int] = [:]

    for text in texts {
        let words = text.lowercased()
            .components(separatedBy: .whitespacesAndNewlines)
            .filter { !$0.isEmpty }
            .map { $0.trimmingCharacters(in: .punctuationCharacters) }
            .filter { !$0.isEmpty }

        // Unigrams
        for word in words {
            unigrams[word, default: 0] += 1
        }

        // Bigrams
        for i in 0..<(words.count - 1) {
            bigrams[words[i], default: [:]][words[i + 1], default: 0] += 1
        }

        // Trigrams
        for i in 0..<(words.count - 2) {
            let key = "\(words[i]) \(words[i + 1])"
            trigrams[key, default: [:]][words[i + 2], default: 0] += 1
        }
    }

    return (trigrams, bigrams, unigrams)
}

// MARK: - Corpus

let corpus = [
    // Professional communication
    "I hope this email finds you well and I wanted to follow up on our conversation",
    "Thank you for your prompt response regarding the project timeline",
    "Please let me know if you have any questions or need further clarification",
    "I look forward to hearing from you at your earliest convenience",
    "As discussed in our meeting today I will proceed with the implementation",
    "I am writing to inform you about the upcoming changes to our process",
    "Could you please provide more details about the requirements",
    "I appreciate your time and consideration in this matter",
    "Please find the attached document for your review and feedback",
    "I would like to schedule a meeting to discuss the next steps",

    // General writing patterns
    "The quick brown fox jumps over the lazy dog in the park",
    "In conclusion we can see that the data clearly suggests a positive trend",
    "On the other hand there are several important factors to consider",
    "Furthermore this approach provides significant advantages over the previous method",
    "However it is important to note that these results may vary",
    "Therefore we recommend the following course of action going forward",
    "In addition to the points mentioned above we should also consider",
    "According to the latest research findings the evidence supports our hypothesis",

    // Technology and business
    "The implementation was completed ahead of schedule and under budget",
    "We have successfully deployed the new system to production",
    "The performance metrics show significant improvement over the baseline",
    "Our team has been working diligently on the new feature set",
    "The project timeline has been updated to reflect the new requirements",
    "Based on our analysis the recommended approach is to use the new framework",
    "We are currently in the process of evaluating the best options",
    "The budget allocation for this quarter has been approved by management",

    // Transitions and connectors
    "First and foremost we should consider the impact on our users",
    "Additionally it is worth mentioning that the team has made progress",
    "In summary the key takeaways from this analysis are clear",
    "As a result of these changes we expect to see improvements",
    "Nevertheless the overall impact remains positive for the organization",
    "Consequently we have decided to proceed with the proposed changes",
    "Meanwhile the development team continues to make steady progress",
    "Subsequently we will need to address the remaining open issues",
]

// MARK: - Build and Export

let model = buildNGramModel(from: corpus)

let encoder = JSONEncoder()
encoder.outputFormatting = [.prettyPrinted, .sortedKeys]

let outputDir = FileManager.default.currentDirectoryPath + "/Scripts/output"

do {
    try FileManager.default.createDirectory(
        atPath: outputDir,
        withIntermediateDirectories: true
    )

    let trigramData = try encoder.encode(model.trigrams)
    try trigramData.write(to: URL(fileURLWithPath: outputDir + "/trigrams.json"))

    let bigramData = try encoder.encode(model.bigrams)
    try bigramData.write(to: URL(fileURLWithPath: outputDir + "/bigrams.json"))

    let unigramData = try encoder.encode(model.unigrams)
    try unigramData.write(to: URL(fileURLWithPath: outputDir + "/unigrams.json"))

    print("✅ N-gram model built successfully!")
    print("   Unigrams: \(model.unigrams.count) unique words")
    print("   Bigrams:  \(model.bigrams.count) unique contexts")
    print("   Trigrams: \(model.trigrams.count) unique contexts")
    print("   Output:   \(outputDir)/")
} catch {
    print("❌ Error: \(error)")
}
