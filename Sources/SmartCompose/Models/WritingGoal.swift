import Foundation

/// Tracks writing goals with word count targets and progress.
struct WritingGoal: Codable, Equatable {
    /// Target word count.
    var targetWordCount: Int

    /// Whether the goal is active.
    var isActive: Bool

    /// Date the goal was set.
    var createdAt: Date

    /// Current progress as a fraction (0.0 to 1.0+).
    func progress(currentWordCount: Int) -> Double {
        guard targetWordCount > 0 else { return 0.0 }
        return Double(currentWordCount) / Double(targetWordCount)
    }

    /// Whether the goal has been achieved.
    func isAchieved(currentWordCount: Int) -> Bool {
        currentWordCount >= targetWordCount
    }

    /// Remaining words to reach the goal.
    func remainingWords(currentWordCount: Int) -> Int {
        max(0, targetWordCount - currentWordCount)
    }

    // MARK: - Presets

    static let quickNote = WritingGoal(targetWordCount: 100, isActive: true, createdAt: Date())
    static let shortEmail = WritingGoal(targetWordCount: 250, isActive: true, createdAt: Date())
    static let blogPost = WritingGoal(targetWordCount: 800, isActive: true, createdAt: Date())
    static let essay = WritingGoal(targetWordCount: 1500, isActive: true, createdAt: Date())
    static let longForm = WritingGoal(targetWordCount: 3000, isActive: true, createdAt: Date())

    static let presets: [(label: String, goal: WritingGoal)] = [
        ("Quick Note (100)", .quickNote),
        ("Short Email (250)", .shortEmail),
        ("Blog Post (800)", .blogPost),
        ("Essay (1,500)", .essay),
        ("Long Form (3,000)", .longForm)
    ]
}

// MARK: - Persistence

extension WritingGoal {
    private static let storageKey = "com.smartcompose.writingGoal"

    /// Saves the goal to UserDefaults.
    func save() {
        if let data = try? JSONEncoder().encode(self) {
            UserDefaults.standard.set(data, forKey: Self.storageKey)
        }
    }

    /// Loads the saved goal from UserDefaults, if any.
    static func load() -> WritingGoal? {
        guard let data = UserDefaults.standard.data(forKey: Self.storageKey) else { return nil }
        return try? JSONDecoder().decode(WritingGoal.self, from: data)
    }

    /// Clears the saved goal.
    static func clear() {
        UserDefaults.standard.removeObject(forKey: Self.storageKey)
    }
}
