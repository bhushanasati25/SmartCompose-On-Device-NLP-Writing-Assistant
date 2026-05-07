import SwiftUI

/// Displays the tone analysis result with indicators and confidence badge.
struct ToneAnalysisView: View {
    let toneResult: ToneResult?
    let isAnalyzing: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "waveform.badge.magnifyingglass")
                    .foregroundStyle(Theme.secondaryAccent)
                Text("Writing Tone")
                    .font(.headline)
                Spacer()

                if isAnalyzing {
                    ProgressView()
                        .scaleEffect(0.7)
                }
            }

            if let result = toneResult {
                // Tone badge
                HStack(spacing: 12) {
                    Image(systemName: result.tone.icon)
                        .font(.title2)
                        .foregroundStyle(toneColor(result.tone))

                    VStack(alignment: .leading, spacing: 3) {
                        HStack {
                            Text(result.tone.rawValue)
                                .font(.subheadline.weight(.semibold))

                            Text("\(Int(result.confidence * 100))%")
                                .font(.system(size: 10, weight: .bold, design: .monospaced))
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(toneColor(result.tone).opacity(0.15))
                                .foregroundStyle(toneColor(result.tone))
                                .clipShape(RoundedRectangle(cornerRadius: 4))
                        }

                        Text(result.tone.detail)
                            .font(Theme.captionFont)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                }

                // Indicators
                if !result.indicators.isEmpty {
                    Divider()

                    VStack(alignment: .leading, spacing: 6) {
                        ForEach(result.indicators) { indicator in
                            HStack(spacing: 6) {
                                Circle()
                                    .fill(toneColor(result.tone).opacity(0.5))
                                    .frame(width: 5, height: 5)
                                Text(indicator.name)
                                    .font(.caption.weight(.medium))
                                    .foregroundStyle(.primary)
                                Text("— \(indicator.detail)")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                }
            } else {
                Text("Start writing to analyze tone")
                    .font(Theme.captionFont)
                    .foregroundStyle(.tertiary)
            }
        }
        .padding(Theme.cardPadding)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: Theme.cardCornerRadius))
    }

    private func toneColor(_ tone: WritingTone) -> Color {
        switch tone {
        case .formal: return .blue
        case .semiFormal: return .indigo
        case .informal: return .orange
        case .academic: return .purple
        case .creative: return .pink
        case .neutral: return .gray
        }
    }
}
