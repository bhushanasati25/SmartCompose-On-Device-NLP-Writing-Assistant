import SwiftUI

/// Design system tokens for consistent visual styling across the app.
enum Theme {

    // MARK: - Colors

    /// Primary accent color used for interactive elements.
    static let accent = Color.blue

    /// Secondary accent for less prominent interactive elements.
    static let secondaryAccent = Color.indigo

    /// Ghost text color — translucent to indicate prediction.
    static let ghostText = Color(.tertiaryLabel)

    /// Background gradient for cards and surfaces.
    static let cardGradient = LinearGradient(
        colors: [
            Color(.secondarySystemGroupedBackground),
            Color(.secondarySystemGroupedBackground).opacity(0.8)
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    /// Background color for the main canvas.
    static let canvasBackground = Color(.systemGroupedBackground)

    /// Sentiment indicator colors.
    static func sentimentColor(for score: Double) -> Color {
        switch score {
        case ..<(-0.3):
            return .red
        case (-0.3)..<0.3:
            return .orange
        default:
            return .green
        }
    }

    /// Entity type colors.
    static func entityColor(for type: EntityType) -> Color {
        switch type {
        case .person: return .blue
        case .place: return .green
        case .organization: return .purple
        }
    }

    // MARK: - Typography

    /// Title font for document names.
    static let titleFont: Font = .system(size: 18, weight: .semibold, design: .default)

    /// Subtitle font for metadata.
    static let subtitleFont: Font = .system(size: 14, weight: .medium, design: .default)

    /// Caption font for timestamps and counts.
    static let captionFont: Font = .system(size: 12, weight: .regular, design: .default)

    /// Monospaced font for metrics display.
    static let metricsFont: Font = .system(size: 13, weight: .medium, design: .monospaced)

    // MARK: - Spacing

    /// Standard card padding.
    static let cardPadding: CGFloat = 16

    /// Corner radius for cards.
    static let cardCornerRadius: CGFloat = 16

    /// Corner radius for pills / badges.
    static let pillCornerRadius: CGFloat = 8

    /// Standard spacing between list items.
    static let listSpacing: CGFloat = 4

    // MARK: - Animation

    /// Standard spring animation for UI transitions.
    static let standardSpring: Animation = .spring(response: 0.5, dampingFraction: 0.8)

    /// Quick animation for suggestion appearance.
    static let quickSpring: Animation = .spring(response: 0.3, dampingFraction: 0.7)

    /// Smooth animation for metrics updates.
    static let smoothEase: Animation = .easeInOut(duration: 0.3)
}
