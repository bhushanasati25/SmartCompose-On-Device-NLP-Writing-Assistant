import UIKit
import Combine

/// Coordinates between UITextView delegate events and the SwiftUI ViewModel.
/// Handles debounced text changes, ghost text acceptance, and rich text formatting.
final class RichTextCoordinator: NSObject, UITextViewDelegate {

    // MARK: - Callbacks

    /// Called when text changes (debounced). Provides the plain text excluding ghost text.
    var onTextChange: ((String) -> Void)?

    /// Called when the user presses Tab to accept ghost text.
    var onAcceptSuggestion: (() -> Void)?

    /// Called when the user dismisses ghost text by typing.
    var onDismissSuggestion: (() -> Void)?

    /// Called when cursor position changes.
    var onCursorChange: ((Int) -> Void)?

    // MARK: - Dependencies

    let ghostRenderer: GhostTextRenderer

    // MARK: - Debounce

    private var debounceTimer: Timer?
    private let debounceInterval: TimeInterval = 0.15 // 150ms

    /// Flag to suppress change notifications during programmatic edits (e.g., ghost text insertion).
    var isSuppressingChanges: Bool = false

    init(ghostRenderer: GhostTextRenderer) {
        self.ghostRenderer = ghostRenderer
        super.init()
    }

    // MARK: - UITextViewDelegate

    func textViewDidChange(_ textView: UITextView) {
        guard !isSuppressingChanges else { return }

        // Cancel any pending debounce
        debounceTimer?.invalidate()

        // Get plain text excluding ghost text
        let plainText = ghostRenderer.plainText(from: textView)

        // Debounce the text change notification
        debounceTimer = Timer.scheduledTimer(withTimeInterval: debounceInterval, repeats: false) { [weak self] _ in
            self?.onTextChange?(plainText)
        }
    }

    func textViewDidChangeSelection(_ textView: UITextView) {
        guard !isSuppressingChanges else { return }

        if let selectedRange = textView.selectedTextRange {
            let offset = textView.offset(from: textView.beginningOfDocument, to: selectedRange.start)
            onCursorChange?(offset)
        }
    }

    func textView(
        _ textView: UITextView,
        shouldChangeTextIn range: NSRange,
        replacementText text: String
    ) -> Bool {
        // Handle Tab key → accept ghost text
        if text == "\t" && ghostRenderer.isShowingGhostText {
            onAcceptSuggestion?()
            return false // Prevent the tab character from being inserted
        }

        // If there's ghost text and user is typing, dismiss it first
        if ghostRenderer.isShowingGhostText {
            isSuppressingChanges = true
            ghostRenderer.removeGhostText(from: textView)
            isSuppressingChanges = false
            onDismissSuggestion?()
        }

        return true
    }

    // MARK: - Rich Text Formatting

    /// Applies bold formatting to the selected range.
    func toggleBold(in textView: UITextView) {
        applyFontTrait(.traitBold, to: textView)
    }

    /// Applies italic formatting to the selected range.
    func toggleItalic(in textView: UITextView) {
        applyFontTrait(.traitItalic, to: textView)
    }

    /// Applies a heading style to the current paragraph.
    func applyHeading(level: Int, to textView: UITextView) {
        guard let selectedRange = textView.selectedTextRange else { return }

        let cursorPosition = textView.offset(from: textView.beginningOfDocument, to: selectedRange.start)
        let text = textView.textStorage.string

        // Find the paragraph containing the cursor
        let nsText = text as NSString
        let paragraphRange = nsText.paragraphRange(for: NSRange(location: cursorPosition, length: 0))

        let fontSize: CGFloat
        let weight: UIFont.Weight

        switch level {
        case 1:
            fontSize = 28
            weight = .bold
        case 2:
            fontSize = 24
            weight = .semibold
        case 3:
            fontSize = 20
            weight = .medium
        default:
            fontSize = 17
            weight = .regular
        }

        let attributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: fontSize, weight: weight),
            .foregroundColor: UIColor.label
        ]

        textView.textStorage.beginEditing()
        textView.textStorage.setAttributes(attributes, range: paragraphRange)
        textView.textStorage.endEditing()
    }

    /// Resets formatting to default body style for the selected range.
    func resetFormatting(in textView: UITextView) {
        guard let selectedRange = textView.selectedTextRange else { return }

        let start = textView.offset(from: textView.beginningOfDocument, to: selectedRange.start)
        let end = textView.offset(from: textView.beginningOfDocument, to: selectedRange.end)
        let length = end - start

        guard length > 0 else { return }

        let range = NSRange(location: start, length: length)

        textView.textStorage.beginEditing()
        textView.textStorage.setAttributes(GhostTextRenderer.defaultTextAttributes, range: range)
        textView.textStorage.endEditing()
    }

    // MARK: - Private Helpers

    private func applyFontTrait(_ trait: UIFontDescriptor.SymbolicTraits, to textView: UITextView) {
        guard let selectedRange = textView.selectedTextRange else { return }

        let start = textView.offset(from: textView.beginningOfDocument, to: selectedRange.start)
        let end = textView.offset(from: textView.beginningOfDocument, to: selectedRange.end)
        let length = end - start

        guard length > 0 else {
            // If no selection, apply to the typing attributes for future text
            var attributes = textView.typingAttributes
            if let currentFont = attributes[.font] as? UIFont {
                let descriptor = currentFont.fontDescriptor
                if descriptor.symbolicTraits.contains(trait) {
                    // Remove trait
                    if let newDescriptor = descriptor.withSymbolicTraits(
                        descriptor.symbolicTraits.subtracting(trait)
                    ) {
                        attributes[.font] = UIFont(descriptor: newDescriptor, size: currentFont.pointSize)
                    }
                } else {
                    // Add trait
                    if let newDescriptor = descriptor.withSymbolicTraits(
                        descriptor.symbolicTraits.union(trait)
                    ) {
                        attributes[.font] = UIFont(descriptor: newDescriptor, size: currentFont.pointSize)
                    }
                }
            }
            textView.typingAttributes = attributes
            return
        }

        let range = NSRange(location: start, length: length)

        textView.textStorage.beginEditing()
        textView.textStorage.enumerateAttribute(.font, in: range) { value, attrRange, _ in
            guard let currentFont = value as? UIFont else { return }
            let descriptor = currentFont.fontDescriptor

            let newDescriptor: UIFontDescriptor?
            if descriptor.symbolicTraits.contains(trait) {
                newDescriptor = descriptor.withSymbolicTraits(descriptor.symbolicTraits.subtracting(trait))
            } else {
                newDescriptor = descriptor.withSymbolicTraits(descriptor.symbolicTraits.union(trait))
            }

            if let newDescriptor = newDescriptor {
                let newFont = UIFont(descriptor: newDescriptor, size: currentFont.pointSize)
                textView.textStorage.addAttribute(.font, value: newFont, range: attrRange)
            }
        }
        textView.textStorage.endEditing()
    }

    deinit {
        debounceTimer?.invalidate()
    }
}
