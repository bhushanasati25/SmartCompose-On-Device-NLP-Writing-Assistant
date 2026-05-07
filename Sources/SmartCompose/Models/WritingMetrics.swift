import Foundation

/// Real-time writing analytics computed asynchronously by the TextAnalyzer.
struct WritingMetrics: Equatable {
    /// Total number of words in the document.
    var wordCount: Int = 0

    /// Total number of sentences.
    var sentenceCount: Int = 0

    /// Total number of paragraphs.
    var paragraphCount: Int = 0

    /// Average number of words per sentence.
    var averageSentenceLength: Double = 0.0

    /// Total number of characters (excluding whitespace).
    var characterCount: Int = 0

    /// Flesch-Kincaid readability grade level.
    var readabilityScore: Double = 0.0

    /// Human-readable readability label derived from the score.
    var readabilityLabel: ReadabilityLevel {
        switch readabilityScore {
        case ..<30:
            return .veryDifficult
        case 30..<50:
            return .difficult
        case 50..<60:
            return .fairlyDifficult
        case 60..<70:
            return .standard
        case 70..<80:
            return .fairlyEasy
        case 80..<90:
            return .easy
        default:
            return .veryEasy
        }
    }

    /// Detected language (BCP 47 code, e.g. "en").
    var detectedLanguage: String?

    /// Sentiment polarity: -1.0 (negative) to 1.0 (positive).
    var sentimentScore: Double = 0.0

    /// Human-readable sentiment label.
    var sentimentLabel: String {
        switch sentimentScore {
        case ..<(-0.3):
            return "Negative"
        case (-0.3)..<0.3:
            return "Neutral"
        default:
            return "Positive"
        }
    }

    /// Named entities extracted from the text.
    var entities: [ExtractedEntity] = []

    /// Number of suggestions accepted by the user in this session.
    var suggestionsAccepted: Int = 0

    /// Number of suggestions dismissed by the user in this session.
    var suggestionsDismissed: Int = 0

    /// Acceptance rate as a percentage.
    var acceptanceRate: Double {
        let total = suggestionsAccepted + suggestionsDismissed
        guard total > 0 else { return 0.0 }
        return Double(suggestionsAccepted) / Double(total) * 100.0
    }

    /// Estimated reading time in minutes.
    var estimatedReadingTime: Double {
        // Average adult reads ~250 words per minute.
        max(Double(wordCount) / 250.0, 0.1)
    }
}

/// Readability classification levels based on Flesch-Kincaid score.
enum ReadabilityLevel: String, CaseIterable {
    case veryEasy = "Very Easy"
    case easy = "Easy"
    case fairlyEasy = "Fairly Easy"
    case standard = "Standard"
    case fairlyDifficult = "Fairly Difficult"
    case difficult = "Difficult"
    case veryDifficult = "Very Difficult"

    /// SF Symbol name for display.
    var iconName: String {
        switch self {
        case .veryEasy, .easy:
            return "gauge.with.dots.needle.0percent"
        case .fairlyEasy, .standard:
            return "gauge.with.dots.needle.33percent"
        case .fairlyDifficult:
            return "gauge.with.dots.needle.50percent"
        case .difficult, .veryDifficult:
            return "gauge.with.dots.needle.100percent"
        }
    }
}

/// A named entity extracted by the NaturalLanguage tagger.
struct ExtractedEntity: Identifiable, Equatable {
    let id = UUID()
    let text: String
    let type: EntityType

    static func == (lhs: ExtractedEntity, rhs: ExtractedEntity) -> Bool {
        lhs.text == rhs.text && lhs.type == rhs.type
    }
}

/// Categories of named entities recognized by NLTagger.
enum EntityType: String, CaseIterable {
    case person = "Person"
    case place = "Place"
    case organization = "Organization"

    /// Display color for entity pills in the UI.
    var colorName: String {
        switch self {
        case .person: return "blue"
        case .place: return "green"
        case .organization: return "purple"
        }
    }

    /// SF Symbol name.
    var iconName: String {
        switch self {
        case .person: return "person.fill"
        case .place: return "mappin.circle.fill"
        case .organization: return "building.2.fill"
        }
    }
}
