import UIKit

/// Centralized haptic feedback manager providing consistent tactile responses.
final class HapticManager {

    static let shared = HapticManager()

    private let lightImpact = UIImpactFeedbackGenerator(style: .light)
    private let mediumImpact = UIImpactFeedbackGenerator(style: .medium)
    private let rigidImpact = UIImpactFeedbackGenerator(style: .rigid)
    private let notification = UINotificationFeedbackGenerator()
    private let selection = UISelectionFeedbackGenerator()

    private init() {
        // Pre-warm the generators for lower latency on first use
        lightImpact.prepare()
        mediumImpact.prepare()
    }

    /// Light tap when a suggestion appears.
    func suggestionAppeared() {
        lightImpact.impactOccurred()
    }

    /// Satisfying confirmation when a suggestion is accepted.
    func suggestionAccepted() {
        rigidImpact.impactOccurred(intensity: 0.8)
    }

    /// Subtle feedback when a suggestion is dismissed.
    func suggestionDismissed() {
        lightImpact.impactOccurred(intensity: 0.3)
    }

    /// Success notification when a document is saved.
    func documentSaved() {
        notification.notificationOccurred(.success)
    }

    /// Error notification for failures.
    func error() {
        notification.notificationOccurred(.error)
    }

    /// Selection feedback for toolbar button taps.
    func toolbarTap() {
        selection.selectionChanged()
    }

    /// Medium impact for document creation/deletion.
    func documentAction() {
        mediumImpact.impactOccurred()
    }

    /// Subtle tick for formatting changes.
    func formatChange() {
        lightImpact.impactOccurred(intensity: 0.5)
    }
}
