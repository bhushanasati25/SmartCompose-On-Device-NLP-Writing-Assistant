import SwiftUI
import UIKit

/// Horizontal formatting toolbar with Bold, Italic, and Heading controls.
/// Floats at the bottom of the compose view with a blur material background.
struct FormattingToolbar: View {

    let coordinator: RichTextCoordinator
    let textView: UITextView?

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 6) {
                // Bold
                ToolbarButton(icon: "bold", label: "Bold") {
                    guard let tv = textView else { return }
                    coordinator.toggleBold(in: tv)
                    HapticManager.shared.formatChange()
                }

                // Italic
                ToolbarButton(icon: "italic", label: "Italic") {
                    guard let tv = textView else { return }
                    coordinator.toggleItalic(in: tv)
                    HapticManager.shared.formatChange()
                }

                Divider()
                    .frame(height: 20)

                // Heading 1
                ToolbarButton(icon: "textformat.size.larger", label: "Heading 1") {
                    guard let tv = textView else { return }
                    coordinator.applyHeading(level: 1, to: tv)
                    HapticManager.shared.formatChange()
                }

                // Heading 2
                ToolbarButton(icon: "textformat.size", label: "Heading 2") {
                    guard let tv = textView else { return }
                    coordinator.applyHeading(level: 2, to: tv)
                    HapticManager.shared.formatChange()
                }

                // Heading 3
                ToolbarButton(icon: "textformat.size.smaller", label: "Heading 3") {
                    guard let tv = textView else { return }
                    coordinator.applyHeading(level: 3, to: tv)
                    HapticManager.shared.formatChange()
                }

                Divider()
                    .frame(height: 20)

                // Body (reset formatting)
                ToolbarButton(icon: "text.alignleft", label: "Body") {
                    guard let tv = textView else { return }
                    coordinator.applyHeading(level: 0, to: tv)
                    HapticManager.shared.formatChange()
                }
            }
            .padding(.horizontal, 16)
        }
        .frame(height: 44)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .shadow(color: .black.opacity(0.06), radius: 6, y: 2)
        .padding(.horizontal, 12)
        .padding(.bottom, 8)
    }
}

// MARK: - Toolbar Button

private struct ToolbarButton: View {
    let icon: String
    let label: String
    let action: () -> Void

    @State private var isPressed = false

    var body: some View {
        Button(action: {
            isPressed.toggle()
            action()
        }) {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .medium))
                .foregroundStyle(.primary)
                .frame(width: 36, height: 36)
                .background(
                    isPressed
                    ? AnyShapeStyle(Theme.accent.opacity(0.15))
                    : AnyShapeStyle(.clear)
                )
                .clipShape(RoundedRectangle(cornerRadius: 8))
        }
        .accessibilityLabel(label)
        .buttonStyle(.plain)
    }
}
