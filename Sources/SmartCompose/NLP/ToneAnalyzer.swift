import Foundation
import NaturalLanguage

/// Analyzes the writing tone/register of text using NaturalLanguage framework heuristics.
/// Classifies text as Formal, Semi-Formal, Informal, Academic, or Creative.
actor ToneAnalyzer {

    static let shared = ToneAnalyzer()

    private let nlpEngine = NLPEngine.shared

    private init() {}

    // MARK: - Public API

    /// Analyzes the overall tone of the given text.
    func analyzeTone(_ text: String) async -> ToneResult {
        guard !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return ToneResult(tone: .neutral, confidence: 0, indicators: [])
        }

        let words = await nlpEngine.tokenizeWords(text)
        let sentences = await nlpEngine.tokenizeSentences(text)
        let tags = await nlpEngine.tagPartsOfSpeech(text)

        guard !words.isEmpty else {
            return ToneResult(tone: .neutral, confidence: 0, indicators: [])
        }

        var indicators: [ToneIndicator] = []
        var scores: [WritingTone: Double] = [:]

        // 1. Vocabulary complexity (average word length)
        let avgWordLength = Double(words.reduce(0) { $0 + $1.count }) / Double(words.count)
        if avgWordLength > 6.0 {
            scores[.academic, default: 0] += 2.0
            scores[.formal, default: 0] += 1.0
            indicators.append(.init(name: "Complex Vocabulary", detail: String(format: "Avg %.1f chars/word", avgWordLength)))
        } else if avgWordLength < 4.5 {
            scores[.informal, default: 0] += 1.5
            indicators.append(.init(name: "Simple Vocabulary", detail: String(format: "Avg %.1f chars/word", avgWordLength)))
        }

        // 2. Sentence length
        let avgSentenceLength = Double(words.count) / max(Double(sentences.count), 1)
        if avgSentenceLength > 20 {
            scores[.academic, default: 0] += 2.0
            scores[.formal, default: 0] += 1.0
            indicators.append(.init(name: "Long Sentences", detail: String(format: "Avg %.0f words/sentence", avgSentenceLength)))
        } else if avgSentenceLength < 10 {
            scores[.informal, default: 0] += 1.5
            indicators.append(.init(name: "Short Sentences", detail: String(format: "Avg %.0f words/sentence", avgSentenceLength)))
        }

        // 3. Formal markers
        let formalMarkers = [
            "therefore", "furthermore", "consequently", "moreover", "nevertheless",
            "hereby", "pursuant", "accordingly", "henceforth", "notwithstanding",
            "whereas", "inasmuch", "thereby", "therein", "forthwith"
        ]
        let lowerWords = words.map { $0.lowercased() }
        let formalCount = lowerWords.filter { formalMarkers.contains($0) }.count
        if formalCount > 0 {
            scores[.formal, default: 0] += Double(formalCount) * 2.0
            indicators.append(.init(name: "Formal Markers", detail: "\(formalCount) formal transition(s)"))
        }

        // 4. Informal markers
        let informalMarkers = [
            "hey", "cool", "awesome", "gonna", "wanna", "gotta", "kinda",
            "sorta", "yeah", "nope", "ok", "okay", "lol", "btw", "fyi",
            "tbh", "imo", "omg", "sup", "yo", "dude", "stuff", "things"
        ]
        let informalCount = lowerWords.filter { informalMarkers.contains($0) }.count
        if informalCount > 0 {
            scores[.informal, default: 0] += Double(informalCount) * 2.5
            indicators.append(.init(name: "Informal Language", detail: "\(informalCount) casual expression(s)"))
        }

        // 5. Academic markers
        let academicMarkers = [
            "hypothesis", "methodology", "empirical", "quantitative", "qualitative",
            "theoretical", "paradigm", "correlation", "analysis", "synthesis",
            "literature", "framework", "systematic", "cognitive", "discourse",
            "implications", "significance", "phenomenon", "abstract", "citation"
        ]
        let academicCount = lowerWords.filter { academicMarkers.contains($0) }.count
        if academicCount > 0 {
            scores[.academic, default: 0] += Double(academicCount) * 2.5
            indicators.append(.init(name: "Academic Terms", detail: "\(academicCount) scholarly term(s)"))
        }

        // 6. First-person usage
        let firstPerson = ["i", "me", "my", "mine", "we", "us", "our", "ours"]
        let firstPersonCount = lowerWords.filter { firstPerson.contains($0) }.count
        let firstPersonRatio = Double(firstPersonCount) / Double(words.count)

        if firstPersonRatio > 0.05 {
            scores[.informal, default: 0] += 1.0
            scores[.creative, default: 0] += 0.5
        }

        // 7. Passive voice detection (approximation)
        let passiveIndicators = ["was", "were", "been", "being", "is", "are"]
        _ = tags.filter { $0.tag == .verb }
        let passiveCount = lowerWords.filter { passiveIndicators.contains($0) }.count
        if passiveCount > 2 {
            scores[.formal, default: 0] += 1.0
            scores[.academic, default: 0] += 0.5
            indicators.append(.init(name: "Passive Voice", detail: "\(passiveCount) passive construction(s)"))
        }

        // 8. Exclamation/question frequency
        let exclamationCount = text.filter { $0 == "!" }.count
        _ = text.filter { $0 == "?" }.count
        if exclamationCount > 2 {
            scores[.informal, default: 0] += 1.5
            scores[.creative, default: 0] += 1.0
            indicators.append(.init(name: "Exclamatory", detail: "\(exclamationCount) exclamation(s)"))
        }

        // 9. Contraction usage
        let contractions = ["don't", "can't", "won't", "isn't", "aren't", "wasn't",
                            "weren't", "wouldn't", "couldn't", "shouldn't", "didn't",
                            "hasn't", "haven't", "hadn't", "it's", "that's", "there's",
                            "i'm", "you're", "we're", "they're", "i've", "you've",
                            "we've", "they've", "i'll", "you'll", "we'll", "they'll"]
        let contractionCount = lowerWords.filter { contractions.contains($0) }.count
        if contractionCount > 0 {
            scores[.informal, default: 0] += Double(contractionCount) * 0.8
            scores[.formal, default: 0] -= Double(contractionCount) * 0.5
            indicators.append(.init(name: "Contractions", detail: "\(contractionCount) contraction(s)"))
        }

        // 10. Semi-formal detection (professional but approachable)
        let semiFormalMarkers = ["please", "thank", "appreciate", "regards", "sincerely",
                                  "kindly", "request", "inform", "discuss", "schedule"]
        let semiFormalCount = lowerWords.filter { semiFormalMarkers.contains($0) }.count
        if semiFormalCount > 0 {
            scores[.semiFormal, default: 0] += Double(semiFormalCount) * 1.5
        }

        // Determine winner
        let totalScore = scores.values.reduce(0, +)
        guard totalScore > 0 else {
            return ToneResult(tone: .neutral, confidence: 0.5, indicators: indicators)
        }

        let sorted = scores.sorted { $0.value > $1.value }
        let topTone = sorted.first?.key ?? .neutral
        let confidence = min((sorted.first?.value ?? 0) / max(totalScore, 1) + 0.3, 1.0)

        return ToneResult(tone: topTone, confidence: confidence, indicators: indicators)
    }
}

// MARK: - Models

/// The classified writing tone.
enum WritingTone: String, CaseIterable {
    case formal = "Formal"
    case semiFormal = "Semi-Formal"
    case informal = "Informal"
    case academic = "Academic"
    case creative = "Creative"
    case neutral = "Neutral"

    /// SF Symbol for the tone.
    var icon: String {
        switch self {
        case .formal: return "briefcase.fill"
        case .semiFormal: return "person.text.rectangle.fill"
        case .informal: return "bubble.left.fill"
        case .academic: return "graduationcap.fill"
        case .creative: return "paintbrush.fill"
        case .neutral: return "minus.circle"
        }
    }

    /// Color name for display.
    var colorName: String {
        switch self {
        case .formal: return "blue"
        case .semiFormal: return "indigo"
        case .informal: return "orange"
        case .academic: return "purple"
        case .creative: return "pink"
        case .neutral: return "gray"
        }
    }

    /// Brief description of the tone.
    var detail: String {
        switch self {
        case .formal: return "Professional, structured, and objective language"
        case .semiFormal: return "Professional yet approachable and courteous"
        case .informal: return "Casual, conversational, and relaxed"
        case .academic: return "Scholarly, precise, and evidence-based"
        case .creative: return "Expressive, vivid, and imaginative"
        case .neutral: return "Balanced, general-purpose writing"
        }
    }
}

/// Result of a tone analysis.
struct ToneResult: Equatable {
    let tone: WritingTone
    let confidence: Double
    let indicators: [ToneIndicator]
}

/// A single indicator that contributed to the tone classification.
struct ToneIndicator: Equatable, Identifiable {
    let id = UUID()
    let name: String
    let detail: String

    static func == (lhs: ToneIndicator, rhs: ToneIndicator) -> Bool {
        lhs.name == rhs.name && lhs.detail == rhs.detail
    }
}
