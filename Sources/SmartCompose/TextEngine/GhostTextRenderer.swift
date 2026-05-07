import UIKit

/// Renders translucent "ghost text" predictions inline after the cursor in a UITextView.
/// Ghost text uses custom attributes and is stripped before any real text mutations.
final class GhostTextRenderer {

    // MARK: - Custom Attribute Keys

    /// Custom attribute key to mark ghost text ranges.
    static let ghostTextAttributeKey = NSAttributedString.Key("com.smartcompose.ghostText")

    // MARK: - Ghost Text Styling

    /// The attributed string style applied to ghost text.
    private static var ghostAttributes: [NSAttributedString.Key: Any] {
        [
            .foregroundColor: UIColor.tertiaryLabel,
            .font: UIFont.systemFont(ofSize: 17, weight: .regular),
            ghostTextAttributeKey: true
        ]
    }

    /// The default style for normal user-typed text.
    static var defaultTextAttributes: [NSAttributedString.Key: Any] {
        [
            .foregroundColor: UIColor.label,
            .font: UIFont.systemFont(ofSize: 17, weight: .regular)
        ]
    }

    // MARK: - State

    /// Whether ghost text is currently displayed.
    private(set) var isShowingGhostText: Bool = false

    /// The current ghost text content being displayed.
    private(set) var currentGhostText: String?

    /// The location in the text storage where ghost text was inserted.
    private(set) var ghostTextLocation: Int?

    // MARK: - Rendering

    /// Inserts ghost text at the current cursor position in the text view.
    /// - Parameters:
    ///   - suggestion: The predicted text to display.
    ///   - textView: The target UITextView.
    func showGhostText(_ suggestion: String, in textView: UITextView) {
        // First remove any existing ghost text
        removeGhostText(from: textView)

        guard !suggestion.isEmpty,
              let selectedRange = textView.selectedTextRange else { return }

        let cursorPosition = textView.offset(from: textView.beginningOfDocument, to: selectedRange.start)

        // Create the ghost text attributed string
        let ghostString = NSAttributedString(
            string: suggestion,
            attributes: Self.ghostAttributes
        )

        // Insert at cursor position
        let textStorage = textView.textStorage

        textStorage.beginEditing()
        textStorage.insert(ghostString, at: cursorPosition)
        textStorage.endEditing()

        // Restore cursor to before the ghost text
        if let newPosition = textView.position(from: textView.beginningOfDocument, offset: cursorPosition) {
            textView.selectedTextRange = textView.textRange(from: newPosition, to: newPosition)
        }

        isShowingGhostText = true
        currentGhostText = suggestion
        ghostTextLocation = cursorPosition
    }

    /// Removes all ghost text from the text view.
    @discardableResult
    func removeGhostText(from textView: UITextView) -> Bool {
        guard isShowingGhostText else { return false }

        let textStorage = textView.textStorage
        var rangesToRemove: [NSRange] = []

        // Find all ghost text ranges
        textStorage.enumerateAttribute(
            Self.ghostTextAttributeKey,
            in: NSRange(location: 0, length: textStorage.length)
        ) { value, range, _ in
            if value as? Bool == true {
                rangesToRemove.append(range)
            }
        }

        // Remove in reverse order to maintain valid indices
        textStorage.beginEditing()
        for range in rangesToRemove.reversed() {
            textStorage.deleteCharacters(in: range)
        }
        textStorage.endEditing()

        let hadGhostText = !rangesToRemove.isEmpty
        isShowingGhostText = false
        currentGhostText = nil
        ghostTextLocation = nil

        return hadGhostText
    }

    /// Accepts the current ghost text by converting it to normal text.
    /// Returns the accepted text string, or nil if no ghost text was present.
    func acceptGhostText(in textView: UITextView) -> String? {
        guard isShowingGhostText,
              let acceptedText = currentGhostText else { return nil }

        let textStorage = textView.textStorage

        // Find ghost text ranges and convert them to normal text
        var ghostRanges: [NSRange] = []

        textStorage.enumerateAttribute(
            Self.ghostTextAttributeKey,
            in: NSRange(location: 0, length: textStorage.length)
        ) { value, range, _ in
            if value as? Bool == true {
                ghostRanges.append(range)
            }
        }

        textStorage.beginEditing()
        for range in ghostRanges {
            // Replace ghost attributes with normal text attributes
            textStorage.setAttributes(Self.defaultTextAttributes, range: range)
        }
        textStorage.endEditing()

        // Move cursor to the end of the accepted text
        if let lastRange = ghostRanges.last {
            let endPosition = lastRange.location + lastRange.length
            if let newPosition = textView.position(
                from: textView.beginningOfDocument,
                offset: endPosition
            ) {
                textView.selectedTextRange = textView.textRange(from: newPosition, to: newPosition)
            }
        }

        isShowingGhostText = false
        currentGhostText = nil
        ghostTextLocation = nil

        return acceptedText
    }

    /// Returns the plain text content of the text view excluding any ghost text.
    func plainText(from textView: UITextView) -> String {
        let textStorage = textView.textStorage
        var result = ""

        textStorage.enumerateAttribute(
            Self.ghostTextAttributeKey,
            in: NSRange(location: 0, length: textStorage.length)
        ) { value, range, _ in
            if value as? Bool != true {
                let substring = textStorage.attributedSubstring(from: range).string
                result += substring
            }
        }

        return result
    }
}
