import SwiftUI
import UIKit

/// A SwiftUI wrapper around a UITextView configured with TextKit 2 for high-performance
/// rich text editing with inline ghost text predictions.
struct ComposeTextView: UIViewRepresentable {

    @Binding var text: String
    let ghostRenderer: GhostTextRenderer
    let coordinator: RichTextCoordinator

    /// Callback triggered when the user taps the Tab key to accept a suggestion.
    var onAcceptSuggestion: (() -> Void)?

    /// Callback triggered when text changes (debounced).
    var onTextChange: ((String) -> Void)?

    /// Callback triggered when cursor position changes.
    var onCursorChange: ((Int) -> Void)?

    func makeUIView(context: Context) -> UITextView {
        // Configure TextKit 2 text view
        let textLayoutManager = NSTextLayoutManager()
        let textContentStorage = NSTextContentStorage()
        let textContainer = NSTextContainer(size: CGSize(
            width: 0,
            height: CGFloat.greatestFiniteMagnitude
        ))

        textLayoutManager.textContainer = textContainer
        textContentStorage.addTextLayoutManager(textLayoutManager)

        let textView = UITextView(frame: .zero, textContainer: textContainer)

        // Core configuration
        textView.isScrollEnabled = true
        textView.isEditable = true
        textView.isSelectable = true
        textView.allowsEditingTextAttributes = true
        textView.autocorrectionType = .default
        textView.autocapitalizationType = .sentences
        textView.smartQuotesType = .yes
        textView.smartDashesType = .yes

        // Typography
        textView.typingAttributes = GhostTextRenderer.defaultTextAttributes
        textView.font = UIFont.systemFont(ofSize: 17, weight: .regular)
        textView.textColor = UIColor.label
        textView.backgroundColor = .clear
        textView.tintColor = UIColor.systemBlue

        // Layout
        textView.textContainerInset = UIEdgeInsets(top: 20, left: 16, bottom: 80, right: 16)

        // Performance optimizations
        textView.layoutManager.allowsNonContiguousLayout = true

        // Delegate
        textView.delegate = coordinator

        // Set initial text
        if !text.isEmpty {
            textView.attributedText = NSAttributedString(
                string: text,
                attributes: GhostTextRenderer.defaultTextAttributes
            )
        }

        return textView
    }

    func updateUIView(_ textView: UITextView, context: Context) {
        // Only update if the text has changed externally (not from user typing)
        let currentPlainText = ghostRenderer.plainText(from: textView)
        if currentPlainText != text && !coordinator.isSuppressingChanges {
            coordinator.isSuppressingChanges = true
            textView.attributedText = NSAttributedString(
                string: text,
                attributes: GhostTextRenderer.defaultTextAttributes
            )
            coordinator.isSuppressingChanges = false
        }
    }

    func makeCoordinator() -> RichTextCoordinator {
        // Wire up coordinator callbacks
        coordinator.onTextChange = { [self] newText in
            self.text = newText
            self.onTextChange?(newText)
        }
        coordinator.onAcceptSuggestion = { [self] in
            self.onAcceptSuggestion?()
        }
        coordinator.onDismissSuggestion = nil // ViewModel handles this via text change
        coordinator.onCursorChange = { [self] offset in
            self.onCursorChange?(offset)
        }
        return coordinator
    }
}
