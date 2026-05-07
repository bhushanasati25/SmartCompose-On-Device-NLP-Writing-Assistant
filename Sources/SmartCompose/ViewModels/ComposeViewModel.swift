import Foundation
import SwiftUI
import Observation
import UIKit

/// Orchestrates the compose screen: text editing, NLP prediction, ghost text rendering,
/// and real-time writing analytics.
@Observable
@MainActor
class ComposeViewModel {

    // MARK: - Document State

    var document: Document
    var text: String = ""
    var cursorOffset: Int = 0

    // MARK: - Suggestion State

    var suggestionState: SuggestionState = .idle

    // MARK: - Writing Metrics

    var writingMetrics: WritingMetrics = WritingMetrics()
    var isAnalyzing: Bool = false

    // MARK: - UI State

    var showStats: Bool = false
    var isSaving: Bool = false

    // MARK: - Dependencies

    let ghostRenderer: GhostTextRenderer
    let coordinator: RichTextCoordinator
    private let predictionEngine = PredictionEngine.shared
    private let textAnalyzer = TextAnalyzer.shared
    private let languageModel = LanguageModelStore.shared

    // MARK: - Task Management

    /// The currently running prediction task. Cancelled when new text is typed.
    private var predictionTask: Task<Void, Never>?

    /// The currently running analysis task.
    private var analysisTask: Task<Void, Never>?

    /// Whether predictions are enabled (user preference).
    var isPredictionEnabled: Bool {
        get {
            let value = UserDefaults.standard.object(forKey: "predictionsEnabled")
            // Default to true if not set
            return value == nil ? true : UserDefaults.standard.bool(forKey: "predictionsEnabled")
        }
        set {
            UserDefaults.standard.set(newValue, forKey: "predictionsEnabled")
        }
    }

    // MARK: - Initialization

    init(document: Document? = nil) {
        let doc = document ?? Document()
        self.document = doc
        self.text = doc.content

        let renderer = GhostTextRenderer()
        self.ghostRenderer = renderer
        self.coordinator = RichTextCoordinator(ghostRenderer: renderer)
    }

    // MARK: - Text Change Handling

    /// Called when the user's text changes (debounced by RichTextCoordinator).
    func handleTextChange(_ newText: String) {
        text = newText

        // Cancel stale prediction
        predictionTask?.cancel()
        suggestionState = .idle

        // Request new prediction
        if isPredictionEnabled {
            requestPrediction()
        }

        // Update metrics in the background
        requestAnalysis()
    }

    /// Called when the cursor position changes.
    func handleCursorChange(_ offset: Int) {
        cursorOffset = offset
    }

    // MARK: - Prediction Lifecycle

    /// Fires off an async prediction request, cancelling any previous one.
    func requestPrediction() {
        predictionTask?.cancel()

        predictionTask = Task { [weak self] in
            guard let self = self else { return }

            self.suggestionState = .loading

            let currentText = self.text
            let offset = self.cursorOffset > 0 ? self.cursorOffset : currentText.count

            // Run prediction off main thread via actor
            let suggestion = await predictionEngine.predict(
                text: currentText,
                cursorOffset: offset
            )

            // Check for cancellation
            guard !Task.isCancelled else { return }

            if let suggestion = suggestion {
                self.suggestionState = .ready(suggestion)
                HapticManager.shared.suggestionAppeared()
            } else {
                self.suggestionState = .idle
            }
        }
    }

    /// Accepts the current ghost text suggestion.
    func acceptSuggestion(in textView: UITextView) {
        guard case .ready = suggestionState else { return }

        // Accept the ghost text in the text view
        if let acceptedText = ghostRenderer.acceptGhostText(in: textView) {
            // Update our text state
            text = ghostRenderer.plainText(from: textView)

            // Reinforce the language model
            let contextWords = text
                .components(separatedBy: .whitespaces)
                .filter { !$0.isEmpty }
                .suffix(3)

            Task {
                await predictionEngine.acceptSuggestion(
                    context: Array(contextWords),
                    accepted: acceptedText
                )
            }

            // Update metrics
            writingMetrics.suggestionsAccepted += 1
            HapticManager.shared.suggestionAccepted()
        }

        suggestionState = .idle

        // Request next prediction
        if isPredictionEnabled {
            requestPrediction()
        }
    }

    /// Dismisses the current suggestion.
    func dismissSuggestion() {
        if case .ready = suggestionState {
            writingMetrics.suggestionsDismissed += 1
        }
        suggestionState = .dismissed

        // Reset to idle after a brief delay
        Task { @MainActor in
            try? await Task.sleep(nanoseconds: 100_000_000) // 100ms
            if case .dismissed = self.suggestionState {
                self.suggestionState = .idle
            }
        }
    }

    // MARK: - Writing Analysis

    var toneResult: ToneResult?

    /// Triggers async text analysis for writing metrics.
    func requestAnalysis() {
        analysisTask?.cancel()

        analysisTask = Task { [weak self] in
            guard let self = self else { return }
            self.isAnalyzing = true

            let currentText = self.text
            
            async let metricsFuture = textAnalyzer.analyze(currentText)
            async let toneFuture = ToneAnalyzer.shared.analyzeTone(currentText)
            
            let metrics = await metricsFuture
            let tone = await toneFuture

            guard !Task.isCancelled else { return }

            // Preserve session-level stats
            var updatedMetrics = metrics
            updatedMetrics.suggestionsAccepted = self.writingMetrics.suggestionsAccepted
            updatedMetrics.suggestionsDismissed = self.writingMetrics.suggestionsDismissed

            self.writingMetrics = updatedMetrics
            self.toneResult = tone
            self.isAnalyzing = false
        }
    }

    // MARK: - Document Persistence

    /// Saves the current document to disk.
    func saveDocument() {
        isSaving = true

        document.content = text
        document.modifiedAt = Date()
        document.wordCount = writingMetrics.wordCount
        document.detectedLanguage = writingMetrics.detectedLanguage

        if document.title == "Untitled" && !text.isEmpty {
            // Auto-generate title from first line
            let firstLine = text.components(separatedBy: .newlines).first ?? ""
            let trimmed = firstLine.trimmingCharacters(in: .whitespacesAndNewlines)
            if !trimmed.isEmpty {
                document.title = String(trimmed.prefix(50))
            }
        }

        do {
            try document.save()
            HapticManager.shared.documentSaved()
        } catch {
            print("[ComposeViewModel] Failed to save document: \(error)")
            HapticManager.shared.error()
        }

        isSaving = false
    }

    /// Trains the language model on the current document content.
    func trainOnContent() {
        Task {
            await languageModel.train(on: text)
        }
    }}
