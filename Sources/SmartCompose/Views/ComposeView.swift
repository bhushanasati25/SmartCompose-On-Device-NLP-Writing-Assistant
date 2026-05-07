import SwiftUI
import UIKit

/// Full-screen rich text editor with inline ghost text predictions,
/// formatting toolbar, and real-time writing analytics.
struct ComposeView: View {

    @Bindable var viewModel: ComposeViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var textView: UITextView?
    @State private var showStats = false
    @State private var showFocusMode = false
    @State private var showExportSheet = false
    @StateObject private var speechService = SpeechService.shared

    /// Optional callback invoked after a save to refresh the document list.
    var onSave: (() -> Void)?

    var body: some View {
        ZStack(alignment: .bottom) {
            // Editor canvas
            VStack(spacing: 0) {
                // Title field
                titleField

                Divider()
                    .padding(.horizontal)

                // Main text editor
                ComposeTextView(
                    text: $viewModel.text,
                    ghostRenderer: viewModel.ghostRenderer,
                    coordinator: viewModel.coordinator,
                    onAcceptSuggestion: {
                        if let tv = textView {
                            viewModel.acceptSuggestion(in: tv)
                        }
                    },
                    onTextChange: { newText in
                        viewModel.handleTextChange(newText)
                    },
                    onCursorChange: { offset in
                        viewModel.handleCursorChange(offset)
                    }
                )
                .onAppear {
                    // Capture the UITextView reference for ghost text operations
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        // The UITextView is found via the view hierarchy
                        if let window = UIApplication.shared.connectedScenes
                            .compactMap({ $0 as? UIWindowScene })
                            .flatMap({ $0.windows })
                            .first(where: { $0.isKeyWindow }) {
                            textView = findTextView(in: window)
                        }
                    }
                }
            }
            .background(Color(.systemBackground))

            // Bottom overlay: suggestion indicator + formatting toolbar
            VStack(spacing: 8) {
                // Suggestion indicator
                if case .ready(let suggestion) = viewModel.suggestionState {
                    suggestionBanner(suggestion)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                }

                // Formatting toolbar
                FormattingToolbar(coordinator: viewModel.coordinator, textView: textView)
            }
            .animation(Theme.quickSpring, value: viewModel.suggestionState)
        }
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItemGroup(placement: .navigationBarTrailing) {
                // Text-to-Speech
                Button {
                    speechService.togglePlayPause(viewModel.text)
                } label: {
                    Image(systemName: speechService.state.icon)
                        .foregroundStyle(speechService.state == .idle ? .secondary : Theme.accent)
                }
                .accessibilityLabel(speechService.state.label)

                // Focus Mode
                Button {
                    showFocusMode = true
                } label: {
                    Image(systemName: "arrow.up.left.and.arrow.down.right")
                        .foregroundStyle(.secondary)
                }
                .accessibilityLabel("Focus Mode")

                // Export
                Button {
                    showExportSheet = true
                } label: {
                    Image(systemName: "square.and.arrow.up")
                        .foregroundStyle(.secondary)
                }
                .accessibilityLabel("Export Document")

                // Stats
                Button {
                    withAnimation(Theme.standardSpring) { showStats.toggle() }
                } label: {
                    Image(systemName: "chart.bar.fill")
                        .foregroundStyle(showStats ? Theme.accent : .secondary)
                }
                .accessibilityLabel("Writing Statistics")

                // Save
                Button {
                    viewModel.saveDocument()
                    onSave?()
                } label: {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(Theme.accent)
                }
                .accessibilityLabel("Save Document")
            }
        }
        .sheet(isPresented: $showStats) {
            NavigationStack {
                WritingStatsView(
                    metrics: viewModel.writingMetrics,
                    toneResult: viewModel.toneResult,
                    isAnalyzing: viewModel.isAnalyzing
                )
                    .navigationTitle("Writing Stats")
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .navigationBarTrailing) {
                            Button("Done") { showStats = false }
                        }
                    }
            }
            .presentationDetents([.medium, .large])
            .presentationDragIndicator(.visible)
        }
        .fullScreenCover(isPresented: $showFocusMode) {
            FocusModeView(
                text: $viewModel.text,
                ghostRenderer: viewModel.ghostRenderer,
                coordinator: viewModel.coordinator
            )
        }
        .confirmationDialog("Export Document", isPresented: $showExportSheet, titleVisibility: .visible) {
            ForEach(ExportFormat.allCases) { format in
                Button(format.rawValue) {
                    exportDocument(as: format)
                }
            }
            Button("Cancel", role: .cancel) {}
        }
        .onDisappear {
            // Auto-save and train on content when leaving
            viewModel.saveDocument()
            viewModel.trainOnContent()
            onSave?()
        }
    }

    // MARK: - Title Field

    private var titleField: some View {
        TextField("Document Title", text: $viewModel.document.title)
            .font(.system(size: 24, weight: .bold))
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
    }

    // MARK: - Suggestion Banner

    private func suggestionBanner(_ suggestion: Suggestion) -> some View {
        HStack(spacing: 10) {
            Image(systemName: "sparkles")
                .font(.caption)
                .foregroundStyle(Theme.accent)

            Text("Press Tab to accept: ")
                .font(.caption)
                .foregroundStyle(.secondary)
            +
            Text(suggestion.text)
                .font(.caption.weight(.medium))
                .foregroundStyle(.primary)

            Spacer()

            // Confidence pill
            Text("\(Int(suggestion.confidence * 100))%")
                .font(.system(size: 10, weight: .bold, design: .monospaced))
                .padding(.horizontal, 6)
                .padding(.vertical, 3)
                .background(Theme.accent.opacity(0.15))
                .foregroundStyle(Theme.accent)
                .clipShape(RoundedRectangle(cornerRadius: 4))
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .shadow(color: .black.opacity(0.08), radius: 8, y: 4)
        .padding(.horizontal, 16)
    }

    // MARK: - Helpers

    /// Recursively finds the first UITextView in the view hierarchy.
    private func findTextView(in view: UIView) -> UITextView? {
        if let textView = view as? UITextView {
            return textView
        }
        for subview in view.subviews {
            if let found = findTextView(in: subview) {
                return found
            }
        }
        return nil
    }

    private func exportDocument(as format: ExportFormat) {
        let title = viewModel.document.title.isEmpty ? "Untitled Document" : viewModel.document.title
        let items = ExportService.shared.shareItems(title: title, content: viewModel.text, format: format)
        
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let window = windowScene.windows.first,
              let rootVC = window.rootViewController else { return }
              
        let activityVC = UIActivityViewController(activityItems: items, applicationActivities: nil)
        
        // For iPad support
        if let popover = activityVC.popoverPresentationController {
            popover.sourceView = window
            popover.sourceRect = CGRect(x: window.bounds.midX, y: window.bounds.midY, width: 0, height: 0)
            popover.permittedArrowDirections = []
        }
        
        rootVC.present(activityVC, animated: true)
    }
}
