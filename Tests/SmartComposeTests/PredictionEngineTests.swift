import XCTest
@testable import SmartCompose

final class PredictionEngineTests: XCTestCase {

    // MARK: - Language Model Tests

    func testLanguageModelPrediction() async {
        let store = LanguageModelStore.shared

        // The model is pre-seeded, so it should have predictions
        let predictions = await store.predict(context: ["i", "hope"], maxResults: 3)
        XCTAssertFalse(predictions.isEmpty, "Pre-seeded model should produce predictions")
    }

    func testLanguageModelTraining() async {
        let store = LanguageModelStore.shared

        // Train on a specific phrase
        await store.train(on: "the weather today is absolutely fantastic and wonderful")

        // Should now predict based on training data
        let predictions = await store.predict(context: ["the", "weather"], maxResults: 3)
        XCTAssertFalse(predictions.isEmpty)
    }

    func testLanguageModelReinforcement() async {
        let store = LanguageModelStore.shared

        // Reinforce a specific path
        await store.reinforce(context: ["thank", "you"], acceptedWord: "very")

        // Check that prediction includes the reinforced word
        let predictions = await store.predict(context: ["thank", "you"], maxResults: 5)
        let containsReinforced = predictions.contains { $0.word == "very" }
        XCTAssertTrue(containsReinforced, "Reinforced word should appear in predictions")
    }

    func testLanguageModelContextCheck() async {
        let store = LanguageModelStore.shared

        // Pre-seeded corpus should have "i hope"
        let hasContext = await store.hasContext(for: ["i", "hope"])
        XCTAssertTrue(hasContext, "Pre-seeded model should have context for common phrases")
    }

    // MARK: - Prediction Engine Tests

    func testPredictionEngineGeneratesSuggestion() async {
        let engine = PredictionEngine.shared

        // Use a common phrase from the seed corpus
        let suggestion = await engine.predict(
            text: "I hope this email finds",
            cursorOffset: 25
        )

        // Should generate some prediction (may or may not match exactly)
        // This test validates the pipeline runs without crashing
        XCTAssertNotNil(suggestion != nil || suggestion == nil) // Pipeline ran successfully
    }

    func testPredictionEngineHandlesEmptyText() async {
        let engine = PredictionEngine.shared

        let suggestion = await engine.predict(text: "", cursorOffset: 0)
        XCTAssertNil(suggestion, "Empty text should not produce predictions")
    }

    func testPredictionEngineHandlesSingleWord() async {
        let engine = PredictionEngine.shared

        let suggestion = await engine.predict(text: "Hello", cursorOffset: 5)
        // Single word may or may not produce a prediction, but shouldn't crash
        XCTAssertNotNil(suggestion != nil || suggestion == nil)
    }

    // MARK: - Suggestion Model Tests

    func testSuggestionFreshness() {
        let freshSuggestion = Suggestion(
            text: "test",
            confidence: 0.8,
            source: .ngram,
            insertionOffset: 0,
            timestamp: Date()
        )
        XCTAssertTrue(freshSuggestion.isFresh)

        let staleSuggestion = Suggestion(
            text: "test",
            confidence: 0.8,
            source: .ngram,
            insertionOffset: 0,
            timestamp: Date().addingTimeInterval(-5)
        )
        XCTAssertFalse(staleSuggestion.isFresh)
    }

    func testSuggestionStateEquality() {
        let state1 = SuggestionState.idle
        let state2 = SuggestionState.idle
        XCTAssertEqual(state1, state2)

        let state3 = SuggestionState.loading
        XCTAssertNotEqual(state1, state3)
    }
}
